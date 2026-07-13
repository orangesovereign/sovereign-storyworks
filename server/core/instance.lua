-- Sovereign Storyworks — mission instance engine
-- Phase 1 (Mission Runtime Core) | Features: B1 (engine), B3 (edges), C2 (persistence/resume), L2
-- Server-authoritative. Built on a PARTICIPANTS LIST from day one (ruling #3):
-- V1 fills it with one character; V2 posse play extends it without a rewrite.

SWInstances = {}

-- instanceId -> runtime table:
-- { id, missionCode, def, currentNode, state = {}, status,
--   participants = { [charIdentifier] = { source = number|nil } },  -- source nil while offline
--   taskCtx }
local active = {}
local byChar = {} -- charIdentifier -> instanceId

local function core() return GetVorpCore() end

local function charOf(source)
  local user = core() and core().getUser(source)
  return user and user.getUsedCharacter or nil
end

-- persistence ---------------------------------------------------------------

local function persist(inst, finishedStatus)
  local ok, err = pcall(function()
    MySQL.update.await([[
      UPDATE `sovereign_mission_instances`
      SET `status` = ?, `current_node` = ?, `state` = ?, `finished_at` = IF(? IN ('completed','failed','cancelled'), NOW(), NULL)
      WHERE `id` = ?
    ]], { inst.status, inst.currentNode or '', json.encode(inst.state or {}), inst.status, inst.id })
  end)
  if not ok then SWLog.Error('instance %d persist failed: %s', inst.id, tostring(err)) end
end

-- participant helpers --------------------------------------------------------

local function forEachParticipant(inst, fn)
  for charIdentifier, p in pairs(inst.participants) do
    if p.source then fn(p.source, charIdentifier) end
  end
end

-- K4 (ruling #9): ALL runtime messaging renders through the standalone
-- sovereign_notify resource. A VORP Notify* call anywhere below is a defect.
local function sendK4(source, payload)
  local ok, err = pcall(function()
    exports.sovereign_notify:Notify(source, payload)
  end)
  if not ok then SWLog.Error('sovereign_notify unavailable: %s', tostring(err)) end
end

local function notify(inst, kind, text)
  local payload = kind == 'objective'
    and { kind = 'objective', text = text }
    or { kind = 'tick', text = text }
  forEachParticipant(inst, function(src)
    sendK4(src, payload)
  end)
end

local function notifyCard(inst, variant, title, body)
  forEachParticipant(inst, function(src)
    sendK4(src, { kind = 'card', variant = variant, title = title, body = body })
  end)
end

-- K1/K2: objective display state. The server tells clients WHAT the objective
-- is and (when fixed) WHERE — display only; completion checks remain server-side.
local function broadcastObjectiveBlip(inst)
  local target = inst.taskCtx and inst.taskCtx.target or nil
  local label = inst.taskNode and inst.taskNode.label or ''
  local payload = {
    title = inst.def.title,
    label = label,
    x = target and target.x or nil,
    y = target and target.y or nil,
    z = target and target.z or nil,
  }
  forEachParticipant(inst, function(src)
    TriggerClientEvent('sovereign_storyworks:client:objectiveBlip', src, payload)
  end)
end

local function clearObjectiveBlip(inst)
  forEachParticipant(inst, function(src)
    TriggerClientEvent('sovereign_storyworks:client:objectiveBlip', src, nil)
  end)
end

-- node lifecycle --------------------------------------------------------------

local finishInstance -- forward declaration

local function makeCtx(inst, node)
  local completed = false
  local ctx
  ctx = {
    -- tasks with moving targets (checkpoint routes) call this to update the
    -- K1/K2 display; harmless before broadcast wiring completes
    UpdateTarget = function(target)
      ctx.target = target
      broadcastObjectiveBlip(inst)
    end,
    instance = inst,
    node = node,
    config = node.config or {},
    state = inst.state,
    ForEachParticipant = function(fn) forEachParticipant(inst, fn) end,
    Notify = function(kind, text) notify(inst, kind, text) end,
    Complete = function(success)
      if completed or inst.status ~= 'active' then return end
      completed = true
      SWInstances.NodeFinished(inst, success ~= false)
    end,
    FinishMission = function(outcome, message)
      if completed or inst.status ~= 'active' then return end
      completed = true
      finishInstance(inst, outcome, message)
    end,
  }
  return ctx
end

local function stopCurrentTask(inst)
  if inst.taskCtx and inst.taskNode then
    clearObjectiveBlip(inst)
    local taskType = SWTasks.Get(inst.taskNode.type)
    if taskType and taskType.stop then
      local ok, err = pcall(taskType.stop, inst.taskCtx)
      if not ok then SWLog.Error('instance %d: task stop errored: %s', inst.id, tostring(err)) end
    end
  end
  inst.taskCtx = nil
  inst.taskNode = nil
end

local function enterNode(inst, nodeId)
  local node = inst.def.nodes[nodeId]
  if not node then
    SWLog.Error('instance %d: missing node "%s" — failing mission', inst.id, tostring(nodeId))
    return finishInstance(inst, 'failed', T('mission_broken'))
  end

  inst.currentNode = nodeId
  persist(inst)

  local taskType = SWTasks.Get(node.type)
  if not taskType then
    SWLog.Error('instance %d: unknown task type "%s" — failing mission', inst.id, tostring(node.type))
    return finishInstance(inst, 'failed', T('mission_broken'))
  end

  inst.taskNode = node
  inst.taskCtx = makeCtx(inst, node)

  if node.label and node.label ~= '' then
    -- announce after a short beat so a just-fired completion tip isn't swallowed
    -- (round 2: same-channel messages sent together lost the objective)
    SetTimeout(ConfigRuntime.ObjectiveAnnounceDelayMs or 0, function()
      if inst.status == 'active' and inst.currentNode == nodeId then
        notify(inst, 'objective', node.label)
      end
    end)
  end

  local ok, err = pcall(taskType.start, inst.taskCtx)
  if not ok then
    SWLog.Error('instance %d: task "%s" start errored: %s', inst.id, node.type, tostring(err))
    return finishInstance(inst, 'failed', T('mission_broken'))
  end

  -- persist again after start: tasks may have written resume-critical state
  -- (e.g. goto's captured origin) during start
  if inst.status == 'active' then
    persist(inst)
    broadcastObjectiveBlip(inst) -- K2: tasks that resolved a fixed target get a map blip
  end
end

function SWInstances.NodeFinished(inst, success)
  local node = inst.taskNode
  stopCurrentTask(inst)

  local edge = success and node.onSuccess or node.onFailure
  if edge then
    return enterNode(inst, edge)
  end

  -- no edge declared: success with no onSuccess completes; failure with no
  -- onFailure fails (B3 defaults)
  if success then
    finishInstance(inst, 'completed', T('mission_completed'))
  else
    finishInstance(inst, 'failed', T('mission_failed'))
  end
end

finishInstance = function(inst, status, message)
  if inst.status ~= 'active' then return end
  stopCurrentTask(inst)
  inst.status = status
  persist(inst)

  local variant = status == 'completed' and 'complete' or (status == 'cancelled' and 'cancelled' or 'failed')
  local title = status == 'completed' and T('mission_over_title')
    or (status == 'cancelled' and T('mission_cancelled_title') or T('mission_failed_title'))
  notifyCard(inst, variant, title, message)

  for charIdentifier in pairs(inst.participants) do
    byChar[tostring(charIdentifier)] = nil
  end
  active[inst.id] = nil
  SWLog.Info('instance %d (%s) finished: %s', inst.id, inst.missionCode, status)
end

-- public API -------------------------------------------------------------------

---Start a published mission for a player. Returns ok, errLocaleKey.
function SWInstances.Start(source, missionCode)
  local character = charOf(source)
  if not character then return false, 'no_character' end

  local charIdentifier = tostring(character.charIdentifier)
  if byChar[charIdentifier] then return false, 'already_on_mission' end

  local entry = SWMissions.GetByCode(missionCode)
  if not entry then return false, 'unknown_mission' end

  local insertId = MySQL.insert.await([[
    INSERT INTO `sovereign_mission_instances` (`mission_id`, `mission_code`, `status`, `current_node`, `state`)
    VALUES (?, ?, 'active', ?, '{}')
  ]], { entry.id, entry.code, entry.def.start })
  if not insertId then return false, 'mission_broken' end

  MySQL.insert.await([[
    INSERT INTO `sovereign_instance_participants` (`instance_id`, `char_identifier`, `role`)
    VALUES (?, ?, 'leader')
  ]], { insertId, charIdentifier })

  local inst = {
    id = insertId,
    missionCode = entry.code,
    def = entry.def,
    currentNode = entry.def.start,
    state = {},
    status = 'active',
    participants = { [charIdentifier] = { source = source } },
  }
  active[insertId] = inst
  byChar[charIdentifier] = insertId

  sendK4(source, { kind = 'card', variant = 'started', title = T('mission_started_title'), body = entry.title })
  SWLog.Info('instance %d started: %s (char %s)', insertId, entry.code, charIdentifier)

  enterNode(inst, entry.def.start)
  return true
end

---Cancel the caller's active mission. Returns ok, errLocaleKey.
function SWInstances.Cancel(source)
  local character = charOf(source)
  if not character then return false, 'no_character' end

  local instanceId = byChar[tostring(character.charIdentifier)]
  local inst = instanceId and active[instanceId]
  if not inst then return false, 'no_active_mission' end

  finishInstance(inst, 'cancelled', T('mission_cancelled'))
  return true
end

function SWInstances.GetByCharIdentifier(charIdentifier)
  local instanceId = byChar[tostring(charIdentifier)]
  return instanceId and active[instanceId] or nil
end

-- resume & lifecycle wiring ------------------------------------------------------

---Boot: load active instances into memory (participants offline until they connect);
---expire the stale ones.
function SWInstances.ResumeFromBoot()
  local expiry = ConfigRuntime.InstanceExpiryHours
  MySQL.update.await([[
    UPDATE `sovereign_mission_instances`
    SET `status` = 'cancelled', `finished_at` = NOW()
    WHERE `status` = 'active' AND `updated_at` < (NOW() - INTERVAL ? HOUR)
  ]], { expiry })

  local rows = MySQL.query.await([[
    SELECT i.`id`, i.`mission_code`, i.`current_node`, i.`state`, p.`char_identifier`
    FROM `sovereign_mission_instances` i
    JOIN `sovereign_instance_participants` p ON p.`instance_id` = i.`id`
    WHERE i.`status` = 'active'
  ]]) or {}

  local count = 0
  for _, row in ipairs(rows) do
    local entry = SWMissions.GetByCode(row.mission_code)
    if entry then
      local inst = active[row.id]
      if not inst then
        local okState, state = pcall(json.decode, row.state or '{}')
        inst = {
          id = row.id,
          missionCode = row.mission_code,
          def = entry.def,
          currentNode = row.current_node,
          state = (okState and type(state) == 'table') and state or {},
          status = 'active',
          participants = {},
        }
        active[row.id] = inst
        count = count + 1
      end
      inst.participants[tostring(row.char_identifier)] = { source = nil }
      byChar[tostring(row.char_identifier)] = row.id
    else
      MySQL.update.await("UPDATE `sovereign_mission_instances` SET `status` = 'cancelled', `finished_at` = NOW() WHERE `id` = ?", { row.id })
      SWLog.Warn('instance %d cancelled at boot: mission "%s" is no longer published', row.id, row.mission_code)
    end
  end
  if count > 0 then SWLog.Info('%d active instance(s) restored, awaiting their players.', count) end
end

---A character came online: bind their source and re-arm the current node.
local function resumeForCharacter(source, character)
  local inst = SWInstances.GetByCharIdentifier(character.charIdentifier)
  if not inst then return end

  inst.participants[tostring(character.charIdentifier)].source = source

  -- Re-enter the current node only if its task isn't already running (solo V1:
  -- the sole participant returning always re-arms it).
  if not inst.taskCtx then
    sendK4(source, { kind = 'card', variant = 'started', title = T('mission_resumed_title'), body = inst.def.title })
    SWLog.Info('instance %d resumed by char %s', inst.id, tostring(character.charIdentifier))
    enterNode(inst, inst.currentNode)
  end
end

AddEventHandler('vorp:SelectedCharacter', function(source, eventCharacter)
  -- resolve the character through the core rather than trusting the event
  -- payload's shape (it differs between vorp_core versions)
  local character = charOf(source) or eventCharacter
  if not character or not character.charIdentifier then return end
  local ok, err = pcall(resumeForCharacter, source, character)
  if not ok then SWLog.Error('resume failed for source %s: %s', source, tostring(err)) end
end)

AddEventHandler('playerDropped', function()
  local source = source
  for _, inst in pairs(active) do
    for charIdentifier, p in pairs(inst.participants) do
      if p.source == source then
        p.source = nil
        -- solo V1: nobody left online → park the task; state persists, node re-arms on return
        stopCurrentTask(inst)
        persist(inst)
        SWLog.Info('instance %d parked (char %s disconnected)', inst.id, charIdentifier)
      end
    end
  end
end)

-- runtime tick -------------------------------------------------------------------

CreateThread(function()
  while true do
    Wait(ConfigRuntime.PositionPollMs)
    for _, inst in pairs(active) do
      if inst.status == 'active' and inst.taskCtx and inst.taskNode then
        local taskType = SWTasks.Get(inst.taskNode.type)
        if taskType and taskType.tick then
          local ok, err = pcall(taskType.tick, inst.taskCtx)
          if not ok then
            SWLog.Error('instance %d: task "%s" tick errored: %s', inst.id, inst.taskNode.type, tostring(err))
          end
        end
      end
    end
  end
end)

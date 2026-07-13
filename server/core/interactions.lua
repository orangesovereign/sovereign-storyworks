-- Sovereign Storyworks — server-validated interactions
-- Phase 2 | Features: B2 (hold-action, choice, deliver), L2
-- The client only DISPLAYS prompts and reports "the player finished the hold".
-- The server decides whether to believe it: the interaction must be the one it
-- armed, the player must actually be where it lives, enough time must have
-- passed for the hold to be physically possible, and the report is rate-limited.

SWInteractions = {}

local nextId = 1
local bySource = {} -- source -> { id, inst, spec, armedAt, onDone }

---Arm an interaction for every online participant of an instance.
---spec = {
---  mode = 'hold' | 'choice',
---  label,                       (hold) prompt text
---  question, optionA, optionB,  (choice) texts
---  target = {x,y,z} or nil,     where it lives (nil = anywhere)
---  radius,                      show/validate distance (default 2.5)
---  holdMs,                      hold duration override
---}
---onDone(source, choiceIndex) is called after validation passes.
function SWInteractions.Arm(inst, spec, onDone)
  local id = nextId
  nextId = nextId + 1

  for charIdentifier, p in pairs(inst.participants) do
    if p.source then
      bySource[p.source] = {
        id = id,
        inst = inst,
        spec = spec,
        armedAt = os.time(),
        onDone = onDone,
      }
      TriggerClientEvent('sovereign_storyworks:client:interaction', p.source, {
        id = id,
        mode = spec.mode,
        label = spec.label,
        question = spec.question,
        optionA = spec.optionA,
        optionB = spec.optionB,
        target = spec.target,
        radius = spec.radius or 2.5,
        holdMs = spec.holdMs,
      })
    end
  end
  return id
end

---Clear the interaction for every online participant of an instance.
function SWInteractions.Clear(inst)
  for _, p in pairs(inst.participants) do
    if p.source and bySource[p.source] and bySource[p.source].inst == inst then
      bySource[p.source] = nil
      TriggerClientEvent('sovereign_storyworks:client:interaction', p.source, nil)
    end
  end
end

function SWInteractions.DropSource(source)
  bySource[source] = nil
end

RegisterNetEvent('sovereign_storyworks:server:interactionDone', function(id, choiceIndex)
  local source = source

  if SWRateLimit.IsLimited(source, 'interactionDone') then return end

  local rec = bySource[source]
  if not rec or rec.id ~= id then
    SWLog.Debug('interaction report from %s rejected: stale/unknown id %s', source, tostring(id))
    return
  end

  local spec = rec.spec

  -- time plausibility: a hold cannot complete faster than its hold duration
  local holdMs = spec.holdMs or (spec.mode == 'choice' and ConfigRuntime.Interact.choiceHoldMs or ConfigRuntime.Interact.defaultHoldMs)
  if (os.time() - rec.armedAt) < math.floor(holdMs / 1000) then
    SWLog.Warn('interaction report from %s rejected: too fast', source)
    return
  end

  -- position: the player must actually be at the interaction
  if spec.target then
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return end
    local c = GetEntityCoords(ped)
    local allowed = (spec.radius or 2.5) + ConfigRuntime.Interact.positionSlack
    local dx, dy, dz = c.x - spec.target.x, c.y - spec.target.y, c.z - spec.target.z
    if (dx * dx + dy * dy + dz * dz) > (allowed * allowed) then
      SWLog.Warn('interaction report from %s rejected: out of position', source)
      return
    end
  end

  if spec.mode == 'choice' and choiceIndex ~= 1 and choiceIndex ~= 2 then
    return
  end

  local onDone = rec.onDone
  bySource[source] = nil
  onDone(source, choiceIndex)
end)

AddEventHandler('playerDropped', function()
  bySource[source] = nil
end)

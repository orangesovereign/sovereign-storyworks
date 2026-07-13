-- Sovereign Storyworks — task module: talk to an NPC
-- Phase 2 | Features: E1 (branching dialogue), E2 (voice files), B2, B3
-- An NPC waits at a spot; hold [G] to talk; the SERVER paces the conversation
-- line by line (subtitles via sovereign_notify, optional .ogg voice per line);
-- an optional two-way response routes the story's edges (A=success, B=failure).
--
-- config:
--   npc        { model, x, y, z, heading? } (required)
--   radius     talk prompt radius (default 2.5)
--   lines      array of { speaker, text, voice?, durationMs? } (min 1)
--   choice     optional { optionA, optionB } shown after the last line
--   timeLimitSeconds  optional; expiring routes the FAILURE edge (B3)

local function sendNpc(ctx, payload)
  ctx.ForEachParticipant(function(src)
    TriggerClientEvent('sovereign_storyworks:client:npc', src, payload)
  end)
end

local function sendVoice(ctx, file)
  ctx.ForEachParticipant(function(src)
    TriggerClientEvent('sovereign_storyworks:client:voice', src, { file = file })
  end)
end

local function playLines(ctx, index)
  -- abort (loudly, for the console record) if the mission moved on mid-talk
  if ctx.instance.status ~= 'active' or ctx.instance.taskCtx ~= ctx then
    SWLog.Info('talk: dialogue aborted at line %d (instance %d status=%s, ctx %s)',
      index, ctx.instance.id, tostring(ctx.instance.status),
      ctx.instance.taskCtx == ctx and 'current' or 'stale')
    return
  end

  local line = ctx.config.lines[index]
  if not line then
    -- conversation over: choice or straight completion
    local choice = ctx.config.choice
    if choice then
      SWLog.Info('talk: dialogue done, arming response choice (instance %d)', ctx.instance.id)
      ctx.ArmInteraction({
        mode = 'choice',
        question = ctx.config.lines[#ctx.config.lines].text,
        optionA = choice.optionA,
        optionB = choice.optionB,
      }, function(_, choiceIndex)
        ctx.Notify('tip', choiceIndex == 1 and choice.optionA or choice.optionB)
        ctx.Complete(choiceIndex == 1)
      end)
    else
      ctx.Complete(true)
    end
    return
  end

  local ms = line.durationMs
  if not ms then
    local d = ConfigRuntime.Dialogue
    local _, words = line.text:gsub('%S+', '')
    ms = math.min(d.maxLineMs, math.max(d.minLineMs, d.baseLineMs + words * d.msPerWord))
  end
  ctx.NotifySubtitle(line.speaker, line.text, ms)
  if line.voice then sendVoice(ctx, line.voice) end

  SetTimeout(ms + (ConfigRuntime.Dialogue.lineGapMs or 250), function()
    playLines(ctx, index + 1)
  end)
end

SWTasks.Register('talk', {
  label = 'Speak with someone',

  validate = function(config)
    local npc = config.npc
    if type(npc) ~= 'table' or type(npc.model) ~= 'string' or not SWValidPoint(npc) then
      return false, 'npc needs model and x/y/z or originOffset'
    end
    if type(config.lines) ~= 'table' or #config.lines < 1 then
      return false, 'talk needs at least one dialogue line'
    end
    for i, line in ipairs(config.lines) do
      if type(line) ~= 'table' or type(line.text) ~= 'string' or line.text == '' then
        return false, ('line %d needs text'):format(i)
      end
    end
    if config.choice ~= nil then
      if type(config.choice.optionA) ~= 'string' or type(config.choice.optionB) ~= 'string' then
        return false, 'choice needs optionA and optionB'
      end
    end
    if config.timeLimitSeconds ~= nil and type(config.timeLimitSeconds) ~= 'number' then
      return false, 'timeLimitSeconds must be a number'
    end
    return true
  end,

  start = function(ctx)
    local npc = ctx.config.npc
    ctx.state.propSeq = (ctx.state.propSeq or 0) + 1
    local npcId = ctx.state.propSeq
    local pos = { x = npc.x + 0.0, y = npc.y + 0.0, z = npc.z + 0.0 }

    ctx.deadline = ctx.config.timeLimitSeconds and (os.time() + ctx.config.timeLimitSeconds) or nil

    sendNpc(ctx, { action = 'spawnNpc', npcId = npcId, model = npc.model, x = pos.x, y = pos.y, z = pos.z, heading = npc.heading })
    ctx.UpdateTarget(pos)

    ctx.ArmInteraction({
      mode = 'hold', label = T('talk_prompt'), target = pos, radius = ctx.config.radius or 2.5,
    }, function()
      playLines(ctx, 1)
    end)
  end,

  tick = function(ctx)
    if ctx.deadline and os.time() > ctx.deadline then
      ctx.Notify('tip', T('goto_out_of_time'))
      ctx.Complete(false)
    end
  end,

  stop = function(ctx)
    ctx.ClearInteraction()
    ctx.target = nil
    -- the NPC stays for the scene; the engine wipes all mission NPCs at
    -- mission end/cancel (same policy as carry props)
  end,
})

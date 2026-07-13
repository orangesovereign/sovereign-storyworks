-- Sovereign Storyworks — task module: search an area
-- Phase 2 | Features: B2 (search area), B3 (time-limit failure edge)
-- The player must stand inside the area while a search timer accumulates;
-- stepping out pauses the search. Server-authoritative throughout.
--
-- config:
--   x, y, z            area center (required)
--   radius             area radius in meters (default 10.0)
--   searchSeconds      accumulated in-area time required (default 8)
--   timeLimitSeconds   optional; expiring routes the FAILURE edge (B3)

SWTasks.Register('search', {
  label = 'Search an area',

  validate = function(config)
    if not SWValidPoint(config) then
      return false, 'search needs x/y/z or originOffset'
    end
    if config.searchSeconds ~= nil and (type(config.searchSeconds) ~= 'number' or config.searchSeconds <= 0) then
      return false, 'searchSeconds must be a number > 0'
    end
    if config.timeLimitSeconds ~= nil and type(config.timeLimitSeconds) ~= 'number' then
      return false, 'timeLimitSeconds must be a number'
    end
    return true
  end,

  start = function(ctx)
    ctx.target = { x = ctx.config.x + 0.0, y = ctx.config.y + 0.0, z = ctx.config.z + 0.0 }
    ctx.radius = (ctx.config.radius or 10.0) + 0.0
    ctx.needed = ctx.config.searchSeconds or 8
    ctx.accumulated = 0
    ctx.lastTick = os.time()
    ctx.wasInside = false
    ctx.deadline = ctx.config.timeLimitSeconds and (os.time() + ctx.config.timeLimitSeconds) or nil
    ctx.nextPing = 0
  end,

  tick = function(ctx)
    if not ctx.target then return end

    if ctx.deadline and os.time() > ctx.deadline then
      ctx.Notify('tip', T('goto_out_of_time'))
      return ctx.Complete(false)
    end

    local now = os.time()
    local elapsed = now - ctx.lastTick
    ctx.lastTick = now

    local inside = false
    ctx.ForEachParticipant(function(src)
      if inside then return end
      local ped = GetPlayerPed(src)
      if not ped or ped == 0 then return end
      local c = GetEntityCoords(ped)
      local dx, dy = c.x - ctx.target.x, c.y - ctx.target.y
      if (dx * dx + dy * dy) <= (ctx.radius * ctx.radius) then inside = true end
    end)

    if inside then
      if not ctx.wasInside then ctx.Notify('tip', T('search_started')) end
      ctx.accumulated = ctx.accumulated + elapsed
      if ctx.accumulated >= ctx.needed then
        ctx.Notify('tip', T('search_done'))
        return ctx.Complete(true)
      end
      local pingEvery = ConfigRuntime.GotoProgressPingSeconds or 0
      if pingEvery > 0 and now >= ctx.nextPing then
        ctx.nextPing = now + pingEvery
        ctx.Notify('tip', T('search_progress', math.floor(ctx.accumulated), ctx.needed))
      end
    elseif ctx.wasInside then
      ctx.Notify('tip', T('search_paused'))
    end
    ctx.wasInside = inside
  end,

  stop = function(ctx)
    ctx.target = nil
  end,
})

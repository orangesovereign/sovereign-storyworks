-- Sovereign Storyworks — task module: go to location
-- Phase 1 (Mission Runtime Core) | Features: B2 (goto), B3 (time-limit failure edge), L2
-- Fully server-authoritative: the SERVER reads participant positions each poll;
-- the client is never asked and never trusted.
--
-- config:
--   x, y, z            absolute target (world coords), OR
--   relative           { origin = true } → the mission-start point, OR
--   departure          { distance = meters } → complete when a participant is at
--                      least that far from the mission-start point (any direction)
--   radius             arrival radius in meters (default ConfigRuntime.DefaultGotoRadius)
--   timeLimitSeconds   optional; expiring routes the FAILURE edge (B3)
--
-- Round 1 note: the "relative forward" heading-based target is GONE — server-side
-- heading proved unreliable (owner walked forever hunting a mislaid point), and with
-- no map marker until Phase 2 a blind fixed point is untestable anyway. Departure
-- mode is direction-free; progress pings guide the tester (K2 blips replace them).

local function resolveStartOrigin(ctx)
  -- capture the mission's start position once, into persistent state (resume-safe)
  if ctx.state.origin then return true end
  local captured = false
  ctx.ForEachParticipant(function(src)
    if captured then return end
    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
      local c = GetEntityCoords(ped)
      ctx.state.origin = { x = c.x, y = c.y, z = c.z }
      captured = true
    end
  end)
  return captured
end

local function distance2d(ax, ay, bx, by)
  local dx, dy = ax - bx, ay - by
  return math.sqrt(dx * dx + dy * dy)
end

SWTasks.Register('goto', {
  label = 'Go to location',

  validate = function(config)
    local absolute = SWValidPoint(config)
    local toOrigin = type(config.relative) == 'table' and config.relative.origin == true
    local departure = type(config.departure) == 'table' and type(config.departure.distance) == 'number'
      and config.departure.distance > 0
    if not absolute and not toOrigin and not departure then
      return false, 'goto needs x/y/z (or originOffset), relative.origin, or departure.distance'
    end
    if config.timeLimitSeconds ~= nil and type(config.timeLimitSeconds) ~= 'number' then
      return false, 'timeLimitSeconds must be a number'
    end
    return true
  end,

  start = function(ctx)
    local cfg = ctx.config

    if not resolveStartOrigin(ctx) and not (cfg.x and cfg.y and cfg.z) then
      SWLog.Error('goto: could not capture origin for instance %d', ctx.instance.id)
      return ctx.Complete(false)
    end

    if cfg.x and cfg.y and cfg.z then
      ctx.target = { x = cfg.x + 0.0, y = cfg.y + 0.0, z = cfg.z + 0.0 }
    elseif type(cfg.relative) == 'table' and cfg.relative.origin then
      local o = ctx.state.origin
      ctx.target = { x = o.x, y = o.y, z = o.z }
    elseif type(cfg.departure) == 'table' then
      ctx.departDistance = cfg.departure.distance + 0.0
    end

    ctx.radius = (cfg.radius or ConfigRuntime.DefaultGotoRadius) + 0.0
    ctx.deadline = cfg.timeLimitSeconds and cfg.timeLimitSeconds > 0 and (os.time() + cfg.timeLimitSeconds) or nil
    ctx.nextPing = 0
  end,

  tick = function(ctx)
    if not ctx.target and not ctx.departDistance then return end

    if ctx.deadline and os.time() > ctx.deadline then
      ctx.Notify('tip', T('goto_out_of_time'))
      return ctx.Complete(false)
    end

    local done = false
    local pingText = nil

    ctx.ForEachParticipant(function(src)
      if done then return end
      local ped = GetPlayerPed(src)
      if not ped or ped == 0 then return end
      local c = GetEntityCoords(ped)

      if ctx.departDistance then
        local travelled = distance2d(c.x, c.y, ctx.state.origin.x, ctx.state.origin.y)
        if travelled >= ctx.departDistance then
          done = true
        else
          pingText = T('goto_progress_depart', math.floor(travelled), math.floor(ctx.departDistance))
        end
      else
        local dist = distance2d(c.x, c.y, ctx.target.x, ctx.target.y)
        local dz = math.abs(c.z - ctx.target.z)
        -- 2D check with a generous vertical allowance: terrain height drift must
        -- not strand a tester standing visibly "on" the spot
        if dist <= ctx.radius and dz <= math.max(ctx.radius, 6.0) then
          done = true
        else
          pingText = T('goto_progress_reach', math.floor(dist))
        end
      end
    end)

    if done then
      ctx.Notify('tip', T('goto_arrived'))
      return ctx.Complete(true)
    end

    local pingEvery = ConfigRuntime.GotoProgressPingSeconds or 0
    if pingText and pingEvery > 0 and os.time() >= ctx.nextPing then
      ctx.nextPing = os.time() + pingEvery
      ctx.Notify('tip', pingText)
    end
  end,

  stop = function(ctx)
    ctx.target = nil
    ctx.departDistance = nil
  end,
})

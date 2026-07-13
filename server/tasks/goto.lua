-- Sovereign Storyworks — task module: go to location
-- Phase 1 (Mission Runtime Core) | Features: B2 (goto), B3 (time-limit failure edge), L2
-- Fully server-authoritative: the SERVER reads participant positions each poll;
-- the client is never asked and never trusted.
--
-- config:
--   x, y, z            absolute target (world coords), OR
--   relative           { forward = meters } target ahead of mission-start point, or
--                      { origin = true } the mission-start point itself
--   radius             arrival radius in meters (default ConfigRuntime.DefaultGotoRadius)
--   timeLimitSeconds   optional; expiring routes the FAILURE edge (B3)

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
      -- "forward" from heading math — GetEntityForwardVector is not a server native
      local rad = math.rad(GetEntityHeading(ped))
      ctx.state.originForward = { x = -math.sin(rad), y = math.cos(rad) }
      captured = true
    end
  end)
  return captured
end

local function resolveTarget(ctx)
  local cfg = ctx.config
  if cfg.x and cfg.y and cfg.z then
    return { x = cfg.x + 0.0, y = cfg.y + 0.0, z = cfg.z + 0.0 }
  end

  if cfg.relative then
    if not resolveStartOrigin(ctx) then return nil end
    local origin = ctx.state.origin
    if cfg.relative.origin then
      return { x = origin.x, y = origin.y, z = origin.z }
    end
    if cfg.relative.forward then
      local dir = ctx.state.originForward or { x = 0.0, y = 1.0 }
      return {
        x = origin.x + dir.x * cfg.relative.forward,
        y = origin.y + dir.y * cfg.relative.forward,
        z = origin.z,
      }
    end
  end
  return nil
end

SWTasks.Register('goto', {
  label = 'Go to location',

  validate = function(config)
    local absolute = config.x ~= nil and config.y ~= nil and config.z ~= nil
    local relative = type(config.relative) == 'table'
      and (config.relative.origin == true or type(config.relative.forward) == 'number')
    if not absolute and not relative then
      return false, 'goto needs x/y/z or a relative target'
    end
    if config.timeLimitSeconds ~= nil and type(config.timeLimitSeconds) ~= 'number' then
      return false, 'timeLimitSeconds must be a number'
    end
    return true
  end,

  start = function(ctx)
    local target = resolveTarget(ctx)
    if not target then
      SWLog.Error('goto: could not resolve target for instance %d', ctx.instance.id)
      return ctx.Complete(false)
    end
    ctx.target = target
    ctx.radius = (ctx.config.radius or ConfigRuntime.DefaultGotoRadius) + 0.0
    ctx.deadline = ctx.config.timeLimitSeconds and (os.time() + ctx.config.timeLimitSeconds) or nil
  end,

  tick = function(ctx)
    if not ctx.target then return end

    if ctx.deadline and os.time() > ctx.deadline then
      ctx.Notify('tip', T('goto_out_of_time'))
      return ctx.Complete(false)
    end

    local arrived = false
    ctx.ForEachParticipant(function(src)
      if arrived then return end
      local ped = GetPlayerPed(src)
      if ped and ped ~= 0 then
        local c = GetEntityCoords(ped)
        local dx, dy, dz = c.x - ctx.target.x, c.y - ctx.target.y, c.z - ctx.target.z
        if (dx * dx + dy * dy + dz * dz) <= (ctx.radius * ctx.radius) then
          arrived = true
        end
      end
    end)

    if arrived then
      ctx.Notify('tip', T('goto_arrived'))
      ctx.Complete(true)
    end
  end,

  stop = function(ctx)
    ctx.target = nil
  end,
})

-- Sovereign Storyworks — task module: multi-checkpoint route
-- Phase 2 | Features: B2 (checkpoint route), B3 (time-limit failure edge)
-- Server-authoritative: the server polls positions; the blip/tracker advance
-- checkpoint by checkpoint. Progress survives resume (index in instance state).
--
-- config:
--   checkpoints        array of {x, y, z} in ride order (min 2)
--   radius             arrival radius per checkpoint (default ConfigRuntime.DefaultGotoRadius)
--   timeLimitSeconds   optional; expiring routes the FAILURE edge (B3)

SWTasks.Register('route', {
  label = 'Ride a route',

  validate = function(config)
    if type(config.checkpoints) ~= 'table' or #config.checkpoints < 2 then
      return false, 'route needs at least 2 checkpoints'
    end
    for i, cp in ipairs(config.checkpoints) do
      if not SWValidPoint(cp) then
        return false, ('checkpoint %d needs x/y/z or originOffset'):format(i)
      end
    end
    if config.timeLimitSeconds ~= nil and type(config.timeLimitSeconds) ~= 'number' then
      return false, 'timeLimitSeconds must be a number'
    end
    return true
  end,

  start = function(ctx)
    ctx.nodeState.route = ctx.nodeState.route or { index = 1 }
    local cp = ctx.config.checkpoints[ctx.nodeState.route.index]
    ctx.radius = (ctx.config.radius or ConfigRuntime.DefaultGotoRadius) + 0.0
    ctx.deadline = ctx.config.timeLimitSeconds and ctx.config.timeLimitSeconds > 0 and (os.time() + ctx.config.timeLimitSeconds) or nil
    ctx.UpdateTarget({ x = cp.x + 0.0, y = cp.y + 0.0, z = cp.z + 0.0 })
    ctx.Notify('tip', T('route_checkpoint', ctx.nodeState.route.index, #ctx.config.checkpoints))
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
      if not ped or ped == 0 then return end
      local c = GetEntityCoords(ped)
      local dx, dy = c.x - ctx.target.x, c.y - ctx.target.y
      if (dx * dx + dy * dy) <= (ctx.radius * ctx.radius)
        and math.abs(c.z - ctx.target.z) <= math.max(ctx.radius, 6.0) then
        arrived = true
      end
    end)
    if not arrived then return end

    local total = #ctx.config.checkpoints
    if ctx.nodeState.route.index >= total then
      ctx.Notify('tip', T('route_done'))
      return ctx.Complete(true)
    end

    ctx.nodeState.route.index = ctx.nodeState.route.index + 1
    local cp = ctx.config.checkpoints[ctx.nodeState.route.index]
    ctx.UpdateTarget({ x = cp.x + 0.0, y = cp.y + 0.0, z = cp.z + 0.0 })
    ctx.Notify('tip', T('route_checkpoint', ctx.nodeState.route.index, total))
  end,

  stop = function(ctx)
    ctx.target = nil
    -- route index stays in state for resume; a FRESH entry to this node later
    -- in the same mission is rare in V1 and restarts where it left off by design
  end,
})

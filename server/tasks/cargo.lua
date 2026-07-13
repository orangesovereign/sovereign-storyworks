-- Sovereign Storyworks — task module: load/unload cargo
-- Phase 2 | Features: B6 (ruling #8), B3 (time-limit failure edge)
-- "Load 5 crates onto the wagon" / "unload the shipment at the depot" —
-- crate by crate through the validated interaction layer; the server counts.
--
-- config:
--   mode               'load' (ground → wagon) | 'unload' (wagon → ground)
--   model              prop model (default 'p_crate01x')
--   count              crates to move (default 1)
--   takePoint          {x,y,z} where crates come FROM (stack / wagon side)
--   putPoint           {x,y,z} where they go TO (wagon side / stack)
--   radius             prompt radius (default 3.0)
--   timeLimitSeconds   optional; expiring routes the FAILURE edge (B3)
--
-- Progress (crates moved) persists across resume; a crate in hand at
-- disconnect restarts from the take point — never orphaned.

local function sendCarry(ctx, payload)
  ctx.ForEachParticipant(function(src)
    TriggerClientEvent('sovereign_storyworks:client:carry', src, payload)
  end)
end

local armNextCrate

armNextCrate = function(ctx)
  local cfg = ctx.config
  local cargo = ctx.nodeState.cargo
  local total = cfg.count or 1
  local radius = cfg.radius or 3.0
  local model = cfg.model or 'p_crate01x'
  local take = { x = cfg.takePoint.x + 0.0, y = cfg.takePoint.y + 0.0, z = cfg.takePoint.z + 0.0 }
  local put = { x = cfg.putPoint.x + 0.0, y = cfg.putPoint.y + 0.0, z = cfg.putPoint.z + 0.0 }

  ctx.state.propSeq = (ctx.state.propSeq or 0) + 1
  local propId = ctx.state.propSeq

  ctx.UpdateTarget(take)

  if cfg.mode == 'load' then
    sendCarry(ctx, { action = 'spawnProp', propId = propId, model = model, x = take.x, y = take.y, z = take.z })
  end

  ctx.ArmInteraction({
    mode = 'hold',
    label = cfg.mode == 'load' and T('cargo_take_prompt') or T('cargo_unload_prompt'),
    target = take,
    radius = radius,
  }, function()
    if cfg.mode == 'load' then
      sendCarry(ctx, { action = 'attach', propId = propId })
    else
      sendCarry(ctx, { action = 'spawnCarried', propId = propId, model = model })
    end
    ctx.UpdateTarget(put)

    ctx.ArmInteraction({
      mode = 'hold',
      label = cfg.mode == 'load' and T('cargo_load_prompt') or T('carry_setdown_prompt'),
      target = put,
      radius = radius,
    }, function()
      if cfg.mode == 'load' then
        sendCarry(ctx, { action = 'attachToWagon', propId = propId, slot = cargo.moved + 1 })
      else
        sendCarry(ctx, { action = 'detachPlace', propId = propId, x = put.x, y = put.y, z = put.z })
      end

      cargo.moved = cargo.moved + 1
      ctx.Notify('tip', T(cfg.mode == 'load' and 'cargo_progress_load' or 'cargo_progress_unload', cargo.moved, total))

      if cargo.moved >= total then
        ctx.Notify('tip', T('cargo_done'))
        ctx.Complete(true)
      else
        armNextCrate(ctx)
      end
    end)
  end)
end

SWTasks.Register('cargo', {
  label = 'Load/unload cargo',

  validate = function(config)
    if config.mode ~= 'load' and config.mode ~= 'unload' then
      return false, "mode must be 'load' or 'unload'"
    end
    for _, key in ipairs({ 'takePoint', 'putPoint' }) do
      if not SWValidPoint(config[key]) then
        return false, key .. ' needs x/y/z or originOffset'
      end
    end
    if config.count ~= nil and (type(config.count) ~= 'number' or config.count < 1) then
      return false, 'count must be >= 1'
    end
    if config.timeLimitSeconds ~= nil and type(config.timeLimitSeconds) ~= 'number' then
      return false, 'timeLimitSeconds must be a number'
    end
    return true
  end,

  start = function(ctx)
    ctx.nodeState.cargo = ctx.nodeState.cargo or { moved = 0 }
    ctx.deadline = ctx.config.timeLimitSeconds and (os.time() + ctx.config.timeLimitSeconds) or nil
    if ctx.nodeState.cargo.moved >= (ctx.config.count or 1) then
      return ctx.Complete(true) -- resumed after the last crate was already moved
    end
    armNextCrate(ctx)
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
  end,
})

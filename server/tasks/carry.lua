-- Sovereign Storyworks — task module: physical carry
-- Phase 2 | Features: B5 (ruling #8), B3 (time-limit failure edge)
-- Pick up a real prop, haul it, set it down at the target — attach route per
-- TECH_SPEC S6. The client renders; every transition is a server-validated
-- interaction, and the crate count/state lives here.
-- Resume honesty: disconnecting mid-carry returns the crate to the pickup
-- point (no orphaned props, ever).
--
-- config:
--   model              prop model (default 'p_crate01x')
--   pickup             {x,y,z} where the prop waits (required)
--   dropoff            {x,y,z} where it must be set down (required)
--   radius             prompt radius (default 2.5)
--   timeLimitSeconds   optional; expiring routes the FAILURE edge (B3)

local function sendCarry(ctx, payload)
  ctx.ForEachParticipant(function(src)
    TriggerClientEvent('sovereign_storyworks:client:carry', src, payload)
  end)
end

SWTasks.Register('carry', {
  label = 'Carry',

  validate = function(config)
    for _, key in ipairs({ 'pickup', 'dropoff' }) do
      local p = config[key]
      if type(p) ~= 'table' or p.x == nil or p.y == nil or p.z == nil then
        return false, key .. ' needs x/y/z'
      end
    end
    if config.timeLimitSeconds ~= nil and type(config.timeLimitSeconds) ~= 'number' then
      return false, 'timeLimitSeconds must be a number'
    end
    return true
  end,

  start = function(ctx)
    local cfg = ctx.config
    ctx.state.propSeq = (ctx.state.propSeq or 0) + 1
    local propId = ctx.state.propSeq
    local model = cfg.model or 'p_crate01x'
    local radius = cfg.radius or 2.5
    local pickup = { x = cfg.pickup.x + 0.0, y = cfg.pickup.y + 0.0, z = cfg.pickup.z + 0.0 }
    local dropoff = { x = cfg.dropoff.x + 0.0, y = cfg.dropoff.y + 0.0, z = cfg.dropoff.z + 0.0 }

    ctx.deadline = cfg.timeLimitSeconds and (os.time() + cfg.timeLimitSeconds) or nil

    sendCarry(ctx, { action = 'spawnProp', propId = propId, model = model, x = pickup.x, y = pickup.y, z = pickup.z })
    ctx.UpdateTarget(pickup)

    ctx.ArmInteraction({
      mode = 'hold', label = T('carry_pickup_prompt'), target = pickup, radius = radius,
    }, function()
      sendCarry(ctx, { action = 'attach', propId = propId })
      ctx.Notify('tip', T('carry_picked_up'))
      ctx.UpdateTarget(dropoff)

      ctx.ArmInteraction({
        mode = 'hold', label = T('carry_setdown_prompt'), target = dropoff, radius = radius,
      }, function()
        sendCarry(ctx, { action = 'detachPlace', propId = propId, x = dropoff.x, y = dropoff.y, z = dropoff.z })
        ctx.Notify('tip', T('carry_delivered'))
        ctx.Complete(true)
      end)
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
    -- props stay in the world (a delivered crate SHOULD sit where it landed);
    -- the engine wipes them all when the mission ends or is cancelled
  end,
})

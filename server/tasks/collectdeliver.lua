-- Sovereign Storyworks — task module: collect / deliver items
-- Phase 2 | Features: B2 (collect/deliver), B3 (time-limit failure edge)
-- Inventory items via vorp_inventory (S1-verified exports). Two modes:
--   collect: the objective completes once the participant's inventory holds
--            the required count (server polls — gather them however you like)
--   deliver: bring the items to a place and hold [G]; the server takes them
--
-- config:
--   mode               'collect' | 'deliver' (required)
--   item               vorp item name (required)
--   count              how many (default 1)
--   x, y, z            deliver: drop-off point (required for deliver)
--   radius             deliver: prompt radius (default 2.5)
--   promptLabel        deliver: prompt text (default locale deliver_prompt)
--   timeLimitSeconds   optional; expiring routes the FAILURE edge (B3)

local function itemCount(source, item, cb)
  exports.vorp_inventory:getItemCount(source, cb, item)
end

local function armDeliver(ctx)
  ctx.ArmInteraction({
    mode = 'hold',
    label = ctx.config.promptLabel or T('deliver_prompt', ctx.needed, ctx.config.item),
    target = ctx.target,
    radius = ctx.config.radius or 2.5,
  }, function(source)
    -- server-side inventory check at the moment of handover
    itemCount(source, ctx.config.item, function(count)
      if (count or 0) >= ctx.needed then
        exports.vorp_inventory:subItem(source, ctx.config.item, ctx.needed, nil, function(ok)
          if ok then
            ctx.Notify('tip', T('deliver_done'))
            ctx.Complete(true)
          else
            ctx.Notify('tip', T('deliver_missing', ctx.needed))
            armDeliver(ctx)
          end
        end)
      else
        ctx.Notify('tip', T('deliver_missing', ctx.needed - (count or 0)))
        armDeliver(ctx) -- try again after gathering the rest (deadline unchanged)
      end
    end)
  end)
end

SWTasks.Register('collectdeliver', {
  label = 'Collect / deliver items',

  validate = function(config)
    if config.mode ~= 'collect' and config.mode ~= 'deliver' then
      return false, "mode must be 'collect' or 'deliver'"
    end
    if type(config.item) ~= 'string' or config.item == '' then
      return false, 'item is required'
    end
    if config.mode == 'deliver' and (config.x == nil or config.y == nil or config.z == nil) then
      return false, 'deliver needs x/y/z'
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
    ctx.needed = ctx.config.count or 1
    ctx.deadline = ctx.config.timeLimitSeconds and (os.time() + ctx.config.timeLimitSeconds) or nil
    ctx.nextInvPoll = 0
    ctx.checking = false

    if ctx.config.mode == 'deliver' then
      ctx.target = { x = ctx.config.x + 0.0, y = ctx.config.y + 0.0, z = ctx.config.z + 0.0 }
      armDeliver(ctx)
    end
  end,

  tick = function(ctx)
    if ctx.deadline and os.time() > ctx.deadline then
      ctx.Notify('tip', T('goto_out_of_time'))
      return ctx.Complete(false)
    end

    if ctx.config.mode ~= 'collect' or ctx.checking then return end

    local now = GetGameTimer()
    if now < ctx.nextInvPoll then return end
    ctx.nextInvPoll = now + (ConfigRuntime.InventoryPollMs or 2000)

    ctx.ForEachParticipant(function(src)
      if ctx.checking then return end
      ctx.checking = true
      itemCount(src, ctx.config.item, function(count)
        ctx.checking = false
        if (count or 0) >= ctx.needed then
          ctx.Notify('tip', T('collect_done'))
          ctx.Complete(true)
        end
      end)
    end)
  end,

  stop = function(ctx)
    ctx.ClearInteraction()
    ctx.target = nil
  end,
})

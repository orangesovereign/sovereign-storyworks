-- Sovereign Storyworks — task module: hold-action
-- Phase 2 | Features: B2 (hold-action), B3 (time-limit failure edge)
-- "Go here and hold [G] to do the thing" — repair the wheel, light the fuse,
-- pry the lockbox. Completion is server-validated (position + timing).
--
-- config:
--   x, y, z            where the action lives (required)
--   radius             prompt/validation radius (default 2.5)
--   promptLabel        text on the hold prompt (required)
--   holdMs             hold duration (default ConfigRuntime.Interact.defaultHoldMs)
--   timeLimitSeconds   optional; expiring routes the FAILURE edge (B3)

SWTasks.Register('holdaction', {
  label = 'Perform an action',

  validate = function(config)
    if not SWValidPoint(config) then
      return false, 'holdaction needs x/y/z or originOffset'
    end
    if type(config.promptLabel) ~= 'string' or config.promptLabel == '' then
      return false, 'holdaction needs promptLabel'
    end
    if config.timeLimitSeconds ~= nil and type(config.timeLimitSeconds) ~= 'number' then
      return false, 'timeLimitSeconds must be a number'
    end
    return true
  end,

  start = function(ctx)
    ctx.target = { x = ctx.config.x + 0.0, y = ctx.config.y + 0.0, z = ctx.config.z + 0.0 }
    ctx.deadline = ctx.config.timeLimitSeconds and (os.time() + ctx.config.timeLimitSeconds) or nil

    ctx.ArmInteraction({
      mode = 'hold',
      label = ctx.config.promptLabel,
      target = ctx.target,
      radius = ctx.config.radius or 2.5,
      holdMs = ctx.config.holdMs,
    }, function()
      ctx.Notify('tip', T('holdaction_done'))
      ctx.Complete(true)
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
  end,
})

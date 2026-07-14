-- Sovereign Storyworks — logic node: chance branch
-- Phase 4 (Story Logic, Progression & Scheduling) | Features: C5
-- Instant-resolving, SERVER-rolled: with `percent`% probability follow the
-- SUCCESS edge, otherwise the FAILURE edge. The roll is never client-visible
-- or client-influenced.
--
-- config:
--   percent   0-100 chance of the SUCCESS edge (default 50)

SWTasks.Register('chance', {
  label = 'Roll the dice',

  validate = function(config)
    if config.percent ~= nil and (type(config.percent) ~= 'number' or config.percent < 0 or config.percent > 100) then
      return false, 'percent must be 0-100'
    end
    return true
  end,

  start = function(ctx)
    local percent = ctx.config.percent or 50
    local roll = math.random() * 100
    ctx.Complete(roll < percent)
  end,
})

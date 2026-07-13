-- Sovereign Storyworks — task module: end mission
-- Phase 1 (Mission Runtime Core) | Features: B2 (end mission)
-- Terminal node: finishes the instance with a declared outcome the moment it
-- is entered.
--
-- config:
--   outcome   'completed' (default) or 'failed'
--   message   optional player-facing closing line (already-localized mission text)

SWTasks.Register('end', {
  label = 'End mission',

  validate = function(config)
    if config.outcome ~= nil and config.outcome ~= 'completed' and config.outcome ~= 'failed' then
      return false, "outcome must be 'completed' or 'failed'"
    end
    return true
  end,

  start = function(ctx)
    local outcome = ctx.config.outcome or 'completed'
    local message = ctx.config.message
    if not message or message == '' then
      message = outcome == 'completed' and T('mission_completed') or T('mission_failed')
    end
    ctx.FinishMission(outcome, message)
  end,
})

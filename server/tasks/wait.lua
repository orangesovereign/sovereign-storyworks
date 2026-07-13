-- Sovereign Storyworks — task module: timed wait
-- Phase 2 | Features: B2 (timed wait)
-- Holds the mission for a configured stretch, counting down in the ticks.
-- Resume note: the countdown restarts if the player disconnects mid-wait
-- (server-honest: the world kept turning, their story did not).
--
-- config:
--   seconds        how long to wait (required, > 0)
--   showCountdown  false to hide the tick countdown (default true)

SWTasks.Register('wait', {
  label = 'Wait',

  validate = function(config)
    if type(config.seconds) ~= 'number' or config.seconds <= 0 then
      return false, 'wait needs seconds > 0'
    end
    return true
  end,

  start = function(ctx)
    ctx.deadline = os.time() + ctx.config.seconds
    ctx.nextPing = 0
  end,

  tick = function(ctx)
    local remaining = ctx.deadline - os.time()
    if remaining <= 0 then
      return ctx.Complete(true)
    end

    if ctx.config.showCountdown ~= false then
      local pingEvery = ConfigRuntime.GotoProgressPingSeconds or 0
      if pingEvery > 0 and os.time() >= ctx.nextPing then
        ctx.nextPing = os.time() + pingEvery
        ctx.Notify('tip', T('wait_remaining', remaining))
      end
    end
  end,
})

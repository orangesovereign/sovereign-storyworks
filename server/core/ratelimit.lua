-- Sovereign Storyworks — per-player fixed-window rate limiter
-- Phase 1 (Mission Runtime Core) | Features: L2
-- The single limiter every server command/callback uses. Limits live in
-- config_limits.lua, never in code.

SWRateLimit = {}

local windows = {}

---True when `source` has exceeded ConfigLimits.RateLimits[limitName].
---Unknown limit names are never limited (but logged once so they get added).
local warned = {}

function SWRateLimit.IsLimited(source, limitName)
  local limit = ConfigLimits.RateLimits[limitName]
  if not limit then
    if not warned[limitName] then
      warned[limitName] = true
      SWLog.Warn('rate limit "%s" is not defined in config_limits.lua', limitName)
    end
    return false
  end

  local now = os.time()
  local key = ('%s:%s'):format(source, limitName)
  local win = windows[key]

  if not win or (now - win.startedAt) >= limit.window then
    windows[key] = { startedAt = now, count = 1 }
    return false
  end

  win.count = win.count + 1
  return win.count > limit.max
end

AddEventHandler('playerDropped', function()
  local source = source
  local prefix = ('%s:'):format(source)
  for key in pairs(windows) do
    if key:sub(1, #prefix) == prefix then windows[key] = nil end
  end
end)

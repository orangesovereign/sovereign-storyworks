-- Sovereign Storyworks — game-clock cache (server)
-- Phase 4 | Features: C3 (time-of-day conditions)
-- The server can't call GetClockHours (client native). RDR2 game time is
-- server-synced/global, so clients heartbeat their hour and we keep the latest
-- as the authoritative game hour. Rate-limited; falls back to real-clock hour
-- until the first report arrives.

SWGameTime = {}

local cachedHour = tonumber(os.date('%H')) or 12

function SWGameTime.Hour()
  return cachedHour
end

RegisterNetEvent('sovereign_storyworks:server:gameHour', function(hour)
  local source = source
  if SWRateLimit.IsLimited(source, 'gameHour') then return end
  hour = tonumber(hour)
  if hour and hour >= 0 and hour <= 23 then
    cachedHour = math.floor(hour)
  end
end)

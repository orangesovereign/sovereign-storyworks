-- Sovereign Storyworks — Phase 0 spike harness (server side)
-- Phase 0 (Foundations & Spikes) | TECH_SPEC spikes S2–S6 | Features: L2 (ace + rate limit pattern)
-- Owner-run verification commands. ACE-gated, rate-limited, disabled by config after Phase 0.

local VALID_SPIKES = {
  ped = true, speech = true, outfit = true, ptfx = true, postfx = true,
  sound = true, carriable = true, place = true, attach = true, cleanup = true,
}

local SPIKE_LIST = 'ped, speech, outfit, ptfx, postfx, sound, carriable, place, attach, cleanup'

-- simple per-player fixed-window rate limiter (the L2 pattern all later callbacks reuse)
local rateWindows = {}

local function isRateLimited(source, limitKey)
  local limit = ConfigLimits.RateLimits[limitKey]
  if not limit then return false end

  local now = os.time()
  local key = ('%s:%s'):format(source, limitKey)
  local win = rateWindows[key]

  if not win or (now - win.startedAt) >= limit.window then
    rateWindows[key] = { startedAt = now, count = 1 }
    return false
  end

  win.count = win.count + 1
  return win.count > limit.max
end

local function chat(source, message)
  TriggerClientEvent('chat:addMessage', source, { args = { '^6Storyworks', message } })
end

RegisterCommand('swspike', function(source, args)
  if source == 0 then
    SWLog.Info('spikes run in-game; use /swspike from a client. Valid: %s', SPIKE_LIST)
    return
  end

  if not Config.Spikes.enabled then
    return chat(source, T('spike_disabled'))
  end

  if not IsPlayerAceAllowed(source, Config.Ace.admin) then
    SWLog.Warn('player %s tried /swspike without %s', source, Config.Ace.admin)
    return chat(source, T('no_permission'))
  end

  if isRateLimited(source, 'spikeCommand') then
    return chat(source, T('rate_limited'))
  end

  local spike = args[1] and string.lower(args[1]) or nil
  if not spike or spike == 'list' then
    return chat(source, T('spike_usage') .. ' — ' .. SPIKE_LIST)
  end

  if not VALID_SPIKES[spike] then
    return chat(source, T('spike_unknown', SPIKE_LIST))
  end

  table.remove(args, 1)
  SWLog.Info('spike "%s" started by player %s', spike, source)
  TriggerClientEvent('sovereign_storyworks:client:runSpike', source, spike, args)
  chat(source, T('spike_started', spike))
end, false)

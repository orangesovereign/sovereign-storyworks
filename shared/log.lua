-- Sovereign Storyworks — tagged logging
-- Phase 0 (Foundations & Spikes) | Features: L1 (Config.Debug)

SWLog = {}

local TAG = '^6[sovereign_storyworks]^7'

local function fmt(msg, ...)
  if select('#', ...) > 0 then
    local ok, formatted = pcall(string.format, msg, ...)
    if ok then return formatted end
  end
  return msg
end

function SWLog.Info(msg, ...)
  print(('%s %s'):format(TAG, fmt(msg, ...)))
end

function SWLog.Warn(msg, ...)
  print(('%s ^3WARN^7 %s'):format(TAG, fmt(msg, ...)))
end

function SWLog.Error(msg, ...)
  print(('%s ^1ERROR^7 %s'):format(TAG, fmt(msg, ...)))
end

function SWLog.Debug(msg, ...)
  if Config.Debug then
    print(('%s ^5DEBUG^7 %s'):format(TAG, fmt(msg, ...)))
  end
end

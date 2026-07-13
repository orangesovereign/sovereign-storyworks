-- Sovereign Storyworks — K4 client bridge
-- Phase 2 | Features: K4 (ruling #9)
-- Relays server notification events into the HUD NUI and pushes the
-- server-configured presentation once at load. The HUD never takes focus.

local configPushed = false

local function pushConfig()
  SendNUIMessage({ type = 'k4:config', config = ConfigNotifications })
  configPushed = true
end

CreateThread(function()
  Wait(1000) -- let the NUI frame finish loading
  pushConfig()
end)

RegisterNetEvent('sovereign_storyworks:client:notify', function(payload)
  if type(payload) ~= 'table' or type(payload.type) ~= 'string' then return end
  if not configPushed then pushConfig() end
  SendNUIMessage(payload)
end)

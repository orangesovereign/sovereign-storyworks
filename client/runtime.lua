-- Sovereign Storyworks — client runtime display
-- Phase 2 | Features: K1 (objective tracker), K2 (objective map blips)
-- Display only: the server decides everything; this file just shows it.
-- Distance in the tracker is computed client-side FOR DISPLAY — the server
-- still judges arrival on its own poll.

local objectiveBlip = nil
local currentTarget = nil
local trackerConfigPushed = false

local function pushTrackerConfig()
  SendNUIMessage({ type = 'k1:config', config = ConfigRuntime.Tracker })
  trackerConfigPushed = true
end

CreateThread(function()
  Wait(1000)
  pushTrackerConfig()
end)

local function removeObjectiveBlip()
  if objectiveBlip then
    RemoveBlip(objectiveBlip)
    objectiveBlip = nil
  end
end

local function clearObjective()
  removeObjectiveBlip()
  currentTarget = nil
  SendNUIMessage({ type = 'k1:clear' })
end

RegisterNetEvent('sovereign_storyworks:client:objectiveBlip', function(data)
  removeObjectiveBlip()
  currentTarget = nil

  if type(data) ~= 'table' then
    return clearObjective()
  end

  if not trackerConfigPushed then pushTrackerConfig() end
  SendNUIMessage({
    type = 'k1:objective',
    title = data.title or '',
    label = data.label or '',
    hasTarget = data.x ~= nil,
  })

  if data.x then
    currentTarget = vector3(data.x, data.y, data.z)
    local style = ConfigRuntime.ObjectiveBlipStyle
    if style and style ~= 0 then
      objectiveBlip = Citizen.InvokeNative(0x554D9D53F696D002, style, currentTarget) -- BlipAddForCoords (vorp_utils blips.lua:22)
      if objectiveBlip and data.label and data.label ~= '' then
        Citizen.InvokeNative(0x9CB1A1623062F402, objectiveBlip, data.label) -- SetBlipName (vorp_utils blips.lua:31)
      end
    end
  end
end)

-- tracker distance loop (display only)
CreateThread(function()
  while true do
    Wait(500)
    if currentTarget then
      local coords = GetEntityCoords(PlayerPedId())
      SendNUIMessage({ type = 'k1:distance', meters = #(coords - currentTarget) })
    end
  end
end)

-- C3: game-hour heartbeat (server can't read GetClockHours; RDR2 time is global)
CreateThread(function()
  while true do
    TriggerServerEvent('sovereign_storyworks:server:gameHour', GetClockHours())
    Wait(30000)
  end
end)

AddEventHandler('onResourceStop', function(resourceName)
  if resourceName == GetCurrentResourceName() then
    clearObjective()
  end
end)

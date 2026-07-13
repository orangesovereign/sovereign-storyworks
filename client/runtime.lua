-- Sovereign Storyworks — client runtime display
-- Phase 2 | Features: K2 (objective map blips)
-- Display only: the server decides everything; this file just shows it.

local objectiveBlip = nil

local function removeObjectiveBlip()
  if objectiveBlip then
    RemoveBlip(objectiveBlip)
    objectiveBlip = nil
  end
end

RegisterNetEvent('sovereign_storyworks:client:objectiveBlip', function(data)
  removeObjectiveBlip()

  if type(data) ~= 'table' or not data.x then return end
  local style = ConfigRuntime.ObjectiveBlipStyle
  if not style or style == 0 then return end

  objectiveBlip = Citizen.InvokeNative(0x554D9D53F696D002, style, vector3(data.x, data.y, data.z)) -- BlipAddForCoords (vorp_utils blips.lua:22)
  if objectiveBlip and data.label and data.label ~= '' then
    Citizen.InvokeNative(0x9CB1A1623062F402, objectiveBlip, data.label) -- SetBlipName (vorp_utils blips.lua:31)
  end
end)

AddEventHandler('onResourceStop', function(resourceName)
  if resourceName == GetCurrentResourceName() then
    removeObjectiveBlip()
  end
end)

-- Sovereign Storyworks — client mission-NPC rendering
-- Phase 2 | Features: E1 (dialogue NPCs)
-- Display only: NPCs are local, frozen, invincible set dressing; everything
-- that matters (dialogue flow, choices, completion) is server state.
-- Natives per the Phase 0 spike + vorp_utils patterns.

local npcs = {} -- npcId -> ped

local function loadModel(hash)
  if not IsModelValid(hash) then return false end
  RequestModel(hash, false)
  local tries = 0
  while not HasModelLoaded(hash) and tries < 300 do
    Wait(10)
    tries = tries + 1
  end
  return HasModelLoaded(hash)
end

local handlers = {}

function handlers.spawnNpc(data)
  if npcs[data.npcId] then return end
  local hash = joaat(data.model)
  if not loadModel(hash) then return end

  local x, y, z = data.x, data.y, data.z
  local found, groundZ = GetGroundZAndNormalFor_3dCoord(x, y, z + 1.0)
  if found then z = groundZ end

  local ped = CreatePed(hash, x, y, z, data.heading or 0.0, false, true, false, false)
  SetModelAsNoLongerNeeded(hash)
  if not ped or ped == 0 then return end

  Citizen.InvokeNative(0x283978A15512B2FE, ped, true)  -- SetRandomOutfitVariation (peds invisible without it)
  Citizen.InvokeNative(0x9587913B9E772D29, ped, true)  -- place entity on ground (vorp_utils peds.lua:104)
  SetEntityInvincible(ped, true)
  FreezeEntityPosition(ped, true)
  npcs[data.npcId] = ped
end

function handlers.deleteNpc(data)
  local ped = npcs[data.npcId]
  if ped then
    DeletePed(ped)
    npcs[data.npcId] = nil
  end
end

function handlers.clearAll()
  for id, ped in pairs(npcs) do
    if DoesEntityExist(ped) then DeletePed(ped) end
    npcs[id] = nil
  end
end

RegisterNetEvent('sovereign_storyworks:client:npc', function(data)
  if type(data) ~= 'table' or type(data.action) ~= 'string' then return end
  local handler = handlers[data.action]
  if handler then
    CreateThread(function() handler(data) end)
  end
end)

-- E2: creator-supplied voice files (.ogg in audio/) play through the tracker NUI
RegisterNetEvent('sovereign_storyworks:client:voice', function(data)
  if type(data) ~= 'table' or type(data.file) ~= 'string' then return end
  -- keep it inside audio/ — no path tricks
  local file = data.file:gsub('[^%w%._%-]', '')
  SendNUIMessage({ type = 'k1:voice', file = 'audio/' .. file, volume = ConfigRuntime.Dialogue.voiceVolume })
end)

AddEventHandler('onResourceStop', function(resourceName)
  if resourceName == GetCurrentResourceName() then
    handlers.clearAll()
  end
end)

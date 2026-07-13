-- Sovereign Storyworks — client carry & cargo rendering
-- Phase 2 | Features: B5 (physical carry), B6 (load/unload cargo)
-- Attach route (TECH_SPEC S6 ruling). This file only RENDERS what the server
-- authorized: props are local objects, the carry state machine, prompts, and
-- all counting live server-side behind the validated interaction layer.

local props = {} -- propId -> entity
local carryingId = nil
local restrictThread = false

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

local function loadDict(dict)
  RequestAnimDict(dict)
  local tries = 0
  while not HasAnimDictLoaded(dict) and tries < 300 do
    Wait(10)
    tries = tries + 1
  end
  return HasAnimDictLoaded(dict)
end

local function playCarryAnim(clip, loop)
  local cfg = ConfigRuntime.Carry
  if not loadDict(cfg.animDict) then return end
  -- flag 31: upper body + allow movement (pattern per vorp_inventory UtilityService)
  TaskPlayAnim(PlayerPedId(), cfg.animDict, clip, 8.0, 8.0, loop and -1 or 1200, loop and 31 or 1, 0, false, false, false)
end

local function attachBoneIndex()
  local cfg = ConfigRuntime.Carry
  local model = GetEntityModel(PlayerPedId())
  if model == joaat('mp_female') then return cfg.attachBoneBySkeleton.mp_female end
  return cfg.attachBoneBySkeleton.mp_male
end

local function startCarryRestrictions()
  if restrictThread then return end
  restrictThread = true
  CreateThread(function()
    local cfg = ConfigRuntime.Carry
    while carryingId do
      Wait(0)
      for _, control in ipairs(cfg.blockedControls) do
        DisableControlAction(0, control, true)
      end
      if not IsEntityPlayingAnim(PlayerPedId(), cfg.animDict, cfg.animIdle, 25) then
        playCarryAnim(cfg.animIdle, true)
      end
    end
    restrictThread = false
    ClearPedTasks(PlayerPedId(), true, true)
  end)
end

local function groundSnap(x, y, z)
  local found, groundZ = GetGroundZAndNormalFor_3dCoord(x, y, z + 1.0)
  if found then return x, y, groundZ end
  return x, y, z
end

local handlers = {}

function handlers.spawnProp(data)
  if props[data.propId] then return end
  local hash = joaat(data.model)
  if not loadModel(hash) then return end
  local x, y, z = groundSnap(data.x, data.y, data.z)
  local obj = CreateObject(hash, x, y, z, false, true, false)
  SetModelAsNoLongerNeeded(hash)
  if obj and obj ~= 0 then
    PlaceObjectOnGroundProperly(obj) -- pattern per kibook/redm-carry
    props[data.propId] = obj
  end
end

function handlers.attach(data)
  local obj = props[data.propId]
  if not obj then return end
  local cfg = ConfigRuntime.Carry
  playCarryAnim(cfg.animPickup, false)
  Wait(450)
  local off = cfg.attachOffset
  AttachEntityToEntity(obj, PlayerPedId(), attachBoneIndex(), off.x, off.y, off.z, 0.0, 0.0, 0.0, false, false, true, false, 0, true, false, false)
  carryingId = data.propId
  startCarryRestrictions()
end

function handlers.detachPlace(data)
  local obj = props[data.propId]
  if not obj then return end
  local cfg = ConfigRuntime.Carry
  if carryingId == data.propId then carryingId = nil end
  playCarryAnim(cfg.animPutdown, false)
  Wait(450)
  DetachEntity(obj, false, true)
  if data.x then
    local x, y, z = groundSnap(data.x, data.y, data.z)
    SetEntityCoords(obj, x, y, z, false, false, false, false)
  end
  PlaceObjectOnGroundProperly(obj)
end

function handlers.attachToWagon(data)
  local obj = props[data.propId]
  if not obj then return end
  local cfg = ConfigRuntime.Carry
  if carryingId == data.propId then carryingId = nil end
  playCarryAnim(cfg.animPutdown, false)
  Wait(450)
  DetachEntity(obj, false, true)

  -- the player's current or last wagon, if it stands near the load point
  local ped = PlayerPedId()
  local vehicle = GetVehiclePedIsIn(ped, false)
  if vehicle == 0 then vehicle = GetVehiclePedIsIn(ped, true) end
  local ok = false
  if vehicle ~= 0 and DoesEntityExist(vehicle) then
    local dist = #(GetEntityCoords(vehicle) - GetEntityCoords(ped))
    if dist <= cfg.wagonSearchRadius then
      local slot = cfg.wagonSlots[((data.slot - 1) % #cfg.wagonSlots) + 1]
      AttachEntityToEntity(obj, vehicle, 0, slot.x, slot.y, slot.z, 0.0, 0.0, 0.0, false, false, true, false, 0, true, false, false)
      ok = true
    end
  end
  if not ok then
    -- no wagon in reach: set the crate down instead (the count still stands —
    -- the server authorized the load at the load point)
    PlaceObjectOnGroundProperly(obj)
  end
end

function handlers.spawnCarried(data)
  -- unload mode: a crate appears already in your arms (taken off the wagon)
  local hash = joaat(data.model)
  if not loadModel(hash) then return end
  local c = GetEntityCoords(PlayerPedId())
  local obj = CreateObject(hash, c.x, c.y, c.z, false, true, false)
  SetModelAsNoLongerNeeded(hash)
  if obj and obj ~= 0 then
    props[data.propId] = obj
    handlers.attach({ propId = data.propId })
  end
end

function handlers.deleteProp(data)
  local obj = props[data.propId]
  if obj then
    if carryingId == data.propId then carryingId = nil end
    DeleteObject(obj)
    props[data.propId] = nil
  end
end

function handlers.clearAll()
  carryingId = nil
  for id, obj in pairs(props) do
    if DoesEntityExist(obj) then DeleteObject(obj) end
    props[id] = nil
  end
end

RegisterNetEvent('sovereign_storyworks:client:carry', function(data)
  if type(data) ~= 'table' or type(data.action) ~= 'string' then return end
  local handler = handlers[data.action]
  if handler then
    CreateThread(function() handler(data) end)
  end
end)

AddEventHandler('onResourceStop', function(resourceName)
  if resourceName == GetCurrentResourceName() then
    handlers.clearAll()
  end
end)

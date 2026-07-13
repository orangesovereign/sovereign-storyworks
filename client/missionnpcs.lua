-- Sovereign Storyworks — mission-NPC lifecycle rendering (client)
-- Phase 3 | Features: B2 combat tasks
-- Spawns and OWNS combat/mission peds; detects death, escort arrival, and
-- player separation; reports each up to the server (which decides). Every ped
-- is a mission entity in a master registry wiped on despawn, clearAll, and
-- resource stop — guaranteed cleanup, no orphans. Natives verified in
-- vorp_utils/rdr3_discoveries; escort locomotion flagged S7.

local batches = {} -- batchId -> { peds = {{ent, dead}}, kind, moveTo, arriveRadius, maxSeparation, blips = {}, arrivedReported, separatedReported }
local relationshipReady = false

local function ensureRelationship()
  if relationshipReady then return end
  local grp = ConfigRuntime.Combat.enemyRelGroup
  AddRelationshipGroup(grp)
  local grpHash = GetHashKey(grp)
  local player = GetHashKey('PLAYER')
  SetRelationshipBetweenGroups(6, grpHash, player) -- 6 = HATE: enemies hate the player
  SetRelationshipBetweenGroups(6, player, grpHash) -- and are enemies to the player
  relationshipReady = true
end

local function loadModel(hash)
  if not IsModelValid(hash) then return false end
  RequestModel(hash, false)
  local tries = 0
  while not HasModelLoaded(hash) and tries < 400 do Wait(10); tries = tries + 1 end
  return HasModelLoaded(hash)
end

local function groundZ(x, y, z)
  local found, gz = GetGroundZAndNormalFor_3dCoord(x, y, z + 1.0)
  return found and gz or z
end

local function makeBlip(ent, style, name)
  if not style or style == 0 then return nil end
  if type(style) == 'string' then style = joaat(style) end -- named blip styles (BLIP_STYLE_*)
  local blip = Citizen.InvokeNative(0x23f74c2fda6e7c61, style, ent) -- BlipAddForEntity (vorp_utils peds.lua:154)
  if blip and name then Citizen.InvokeNative(0x9CB1A1623062F402, blip, name) end -- SetBlipName
  return blip
end

local handlers = {}

function handlers.spawn(data)
  if batches[data.batchId] then return end
  ensureRelationship()
  local hash = joaat(data.model)
  if not loadModel(hash) then return end

  local rec = {
    peds = {}, kind = data.kind, blips = {},
    moveTo = data.moveTo and vector3(data.moveTo.x, data.moveTo.y, data.moveTo.z) or nil,
    arriveRadius = data.arriveRadius or 4.0,
    maxSeparation = data.maxSeparation,
    arrivedReported = false, separatedReported = false,
  }

  for i, pt in ipairs(data.peds) do
    local z = groundZ(pt.x, pt.y, pt.z)
    local ped = CreatePed(hash, pt.x, pt.y, z, pt.heading or 0.0, false, true, false, false)
    if ped and ped ~= 0 then
      Citizen.InvokeNative(0x283978A15512B2FE, ped, true)   -- SetRandomOutfitVariation (else invisible)
      Citizen.InvokeNative(0x9587913B9E772D29, ped, true)   -- place on ground
      SetEntityAsMissionEntity(ped, true, true)             -- reliable deletion (vorp_core coreactions.lua:144)
      if data.health then SetEntityHealth(ped, data.health) end

      if data.kind == 'enemy' then
        SetPedRelationshipGroupHash(ped, GetHashKey(ConfigRuntime.Combat.enemyRelGroup))
        if data.weapon then
          GiveWeaponToPed(ped, GetHashKey(data.weapon), data.ammo or 250, false, true, 0, false, 0.5, 1.0, 0, false, 0.0, false)
        end
        SetPedCombatAttributes(ped, 46, true)  -- CA_ALWAYS_FIGHT
        SetPedCombatMovement(ped, 2)           -- offensive
        SetPedCombatRange(ped, 2)
        SetPedCombatAbility(ped, 2)
        if data.hostile then
          Citizen.InvokeNative(0xF166E48407BAC484, ped, PlayerPedId(), 0, 16) -- TaskCombatPed (attack player)
        end
      elseif data.kind == 'target' then
        if data.flees then
          SetPedFleeAttributes(ped, 0, true)   -- bolt when threatened (hunting quarry)
        end
      elseif data.kind == 'ally' then
        if data.invincible then
          SetEntityInvincible(ped, true)       -- protected escort
        end
        if rec.moveTo then
          -- S7: escort locomotion — TaskFollowNavMeshToCoord flagged for dev-server
          -- confirmation; fallback candidates noted in TECH_SPEC.
          TaskFollowNavMeshToCoord(ped, rec.moveTo.x, rec.moveTo.y, rec.moveTo.z, data.walkSpeed or 1.0, -1, 1.0, false, 0)
        end
      end

      rec.peds[i] = { ent = ped, dead = false }
      local blip = makeBlip(ped, data.blipStyle, data.blipName)
      if blip then rec.blips[i] = blip end
    end
  end

  SetModelAsNoLongerNeeded(hash)
  batches[data.batchId] = rec
end

local function deletePed(entry, blip)
  if blip then RemoveBlip(blip) end
  if entry and entry.ent and DoesEntityExist(entry.ent) then
    DeletePed(entry.ent)
    if DoesEntityExist(entry.ent) then DeleteEntity(entry.ent) end
  end
end

function handlers.despawn(data)
  local rec = batches[data.batchId]
  if not rec then return end
  for i, entry in pairs(rec.peds) do deletePed(entry, rec.blips[i]) end
  batches[data.batchId] = nil
end

function handlers.clearAll()
  for id, rec in pairs(batches) do
    for i, entry in pairs(rec.peds) do deletePed(entry, rec.blips[i]) end
    batches[id] = nil
  end
end

RegisterNetEvent('sovereign_storyworks:client:missionnpc', function(data)
  if type(data) ~= 'table' or type(data.action) ~= 'string' then return end
  local h = handlers[data.action]
  if h then CreateThread(function() h(data) end) end
end)

-- monitor: death, escort arrival, escort separation
CreateThread(function()
  while true do
    Wait(400)
    local player = PlayerPedId()
    local pcoords = GetEntityCoords(player)
    for batchId, rec in pairs(batches) do
      -- deaths
      for i, entry in ipairs(rec.peds) do
        if not entry.dead and (not DoesEntityExist(entry.ent) or IsEntityDead(entry.ent)) then
          entry.dead = true
          if rec.blips[i] then RemoveBlip(rec.blips[i]); rec.blips[i] = nil end
          TriggerServerEvent('sovereign_storyworks:server:npcKilled', batchId, i)
        end
      end
      -- escort arrival + separation (lead ped = first alive ally)
      if rec.kind == 'ally' then
        local lead = nil
        for _, entry in ipairs(rec.peds) do if not entry.dead then lead = entry; break end end
        if lead then
          local lc = GetEntityCoords(lead.ent)
          if rec.moveTo and not rec.arrivedReported and #(lc - rec.moveTo) <= rec.arriveRadius then
            rec.arrivedReported = true
            TriggerServerEvent('sovereign_storyworks:server:npcArrived', batchId)
          end
          if rec.maxSeparation and not rec.separatedReported and #(lc - pcoords) > rec.maxSeparation then
            rec.separatedReported = true
            TriggerServerEvent('sovereign_storyworks:server:npcSeparated', batchId)
          end
        end
      end
    end
  end
end)

AddEventHandler('onResourceStop', function(resourceName)
  if resourceName == GetCurrentResourceName() then
    handlers.clearAll()
  end
end)

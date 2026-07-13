-- Sovereign Storyworks — Phase 0 spike harness (client side)
-- Phase 0 (Foundations & Spikes) | TECH_SPEC spikes S2–S6
-- Every native below is sourced from femga/rdr3_discoveries examples or the
-- community-discovered natives list; the source is named next to each hash.
-- This harness exists so the owner can verify natives in-game. It is disabled
-- via Config.Spikes.enabled after the Phase 0 exit gate.

local spawnedEntities = {} -- everything a spike creates, for /swspike cleanup
local ptfxHandle = nil
local soundsetLoadedRef = nil
local lastSpikePed = nil
local lastSpikeProp = nil

-- helpers -----------------------------------------------------------------

local function report(msg, ...)
  if select('#', ...) > 0 then msg = msg:format(...) end
  print(('[sovereign_storyworks] [spike] %s'):format(msg))
end

local function aheadOfPlayer(meters)
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  local fwd = GetEntityForwardVector(ped)
  return coords + fwd * meters
end

local function loadModel(model)
  local hash = joaat(model)
  if not IsModelValid(hash) then
    report('model "%s" is NOT valid on this build.', model)
    return nil
  end
  RequestModel(hash)
  local tries = 0
  while not HasModelLoaded(hash) and tries < 300 do
    Wait(10)
    tries = tries + 1
  end
  if not HasModelLoaded(hash) then
    report('model "%s" failed to load after 3s.', model)
    return nil
  end
  return hash
end

local function spawnSpikePed(model)
  local hash = loadModel(model or Config.Spikes.pedModel)
  if not hash then return nil end
  local pos = aheadOfPlayer(2.5)
  local ped = CreatePed(hash, pos.x, pos.y, pos.z, 0.0, false, true, false, false)
  Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- SetRandomOutfitVariation (vorp_utils peds.lua:109 — peds are invisible without it)
  SetEntityInvincible(ped, true)
  FreezeEntityPosition(ped, true)
  SetModelAsNoLongerNeeded(hash)
  spawnedEntities[#spawnedEntities + 1] = ped
  lastSpikePed = ped
  return ped
end

local function spawnSpikeProp(model)
  local hash = loadModel(model or Config.Spikes.propModel)
  if not hash then return nil end
  local pos = aheadOfPlayer(2.0)
  local prop = CreateObject(hash, pos.x, pos.y, pos.z + 0.2, false, true, false, false, true)
  PlaceObjectOnGroundProperly(prop, true)
  SetModelAsNoLongerNeeded(hash)
  spawnedEntities[#spawnedEntities + 1] = prop
  lastSpikeProp = prop
  return prop
end

-- S2 — native ped speech (audio/audio_banks/README.md example, native 0x8E04FEDD28D42462 PLAY_AMBIENT_SPEECH1)
local function playAmbientSpeechFromEntity(entity, soundRef, soundName, paramsString, line)
  local struct = DataView.ArrayBuffer(128)
  local soundNameLit = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, 'LITERAL_STRING', soundName, Citizen.ResultAsLong())
  local soundRefLit = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, 'LITERAL_STRING', soundRef, Citizen.ResultAsLong())
  local speechParams = GetHashKey(paramsString)

  local nameBig = DataView.ArrayBuffer(16); nameBig:SetInt64(0, soundNameLit)
  local refBig = DataView.ArrayBuffer(16); refBig:SetInt64(0, soundRefLit)
  local paramsBig = DataView.ArrayBuffer(16); paramsBig:SetInt64(0, speechParams)

  struct:SetInt64(0, nameBig:GetInt64(0))
  struct:SetInt64(8, refBig:GetInt64(0))
  struct:SetInt32(16, line)
  struct:SetInt64(24, paramsBig:GetInt64(0))
  struct:SetInt32(32, 0)
  struct:SetInt32(40, 1)
  struct:SetInt32(48, 1)
  struct:SetInt32(56, 1)

  Citizen.InvokeNative(0x8E04FEDD28D42462, entity, struct:Buffer())
end

-- spikes ------------------------------------------------------------------

local spikes = {}

function spikes.ped(args)
  local ped = spawnSpikePed(args[1])
  if ped then
    report('S-base OK: ped spawned and visible ahead of you? If yes, spawning pipeline works.')
  end
end

function spikes.speech(args)
  local ped = lastSpikePed
  if not ped or not DoesEntityExist(ped) then ped = spawnSpikePed() end
  if not ped then return end

  local s = Config.Spikes.speech
  local soundRef = args[1] or s.soundRef
  local soundName = args[2] or s.soundName
  local line = tonumber(args[3]) or s.line

  report('S2: playing speech ref="%s" name="%s" line=%d params=%s', soundRef, soundName, line, s.params)
  playAmbientSpeechFromEntity(ped, soundRef, soundName, s.params, line)
  report('S2: if you HEARD the ped speak, S2 PASSES. Try other refs/names: /swspike speech <ref> <name> [line]')
end

function spikes.outfit(args)
  local ped = lastSpikePed
  if not ped or not DoesEntityExist(ped) then ped = spawnSpikePed() end
  if not ped then return end

  local outfitHash = tonumber(args[1]) or Config.Spikes.outfitHash
  report('S3: applying metaped outfit 0x%X', outfitHash)
  Citizen.InvokeNative(0x1902C4CFCC5BE57C, ped, outfitHash) -- _APPLY_NON_REQUESTED_METAPED_OUTFIT (peds_customization/ped_outfits.lua example)
  Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, false, true, true, true, false) -- _UPDATE_PED_VARIATION (same example)
  report('S3: did the ped\'s appearance change? If yes, S3 PASSES.')
end

function spikes.ptfx(args)
  local ped = lastSpikePed
  if not ped or not DoesEntityExist(ped) then ped = spawnSpikePed() end
  if not ped then return end

  local dict = args[1] or Config.Spikes.ptfx.dict
  local name = args[2] or Config.Spikes.ptfx.name
  local dictHash = GetHashKey(dict)

  -- graphics/ptfx/ptfx_assets_looped.lua example natives:
  if not Citizen.InvokeNative(0x65BB72F29138F5D6, dictHash) then -- HasNamedPtfxAssetLoaded
    Citizen.InvokeNative(0xF2B2353BBC0D4E8F, dictHash)           -- RequestNamedPtfxAsset
    local tries = 0
    while not Citizen.InvokeNative(0x65BB72F29138F5D6, dictHash) and tries < 300 do
      Wait(10); tries = tries + 1
    end
  end

  if not Citizen.InvokeNative(0x65BB72F29138F5D6, dictHash) then
    return report('S4: ptfx dictionary "%s" failed to load — try another.', dict)
  end

  Citizen.InvokeNative(0xA10DB07FC234DD12, dict) -- UseParticleFxAsset
  ptfxHandle = Citizen.InvokeNative(0x8F90AB32E1944BDE, name, ped,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0, 0, 0) -- StartNetworkedParticleFxLoopedOnEntity
  report('S4: looped ptfx "%s"/"%s" started on the spike ped — do you SEE it? /swspike cleanup stops it.', dict, name)
end

function spikes.postfx(args)
  local name = args[1] or Config.Spikes.animpostfx.name
  local seconds = tonumber(args[2]) or Config.Spikes.animpostfx.seconds
  AnimpostfxPlay(name) -- graphics/animpostfx/animpostfx.lua documented natives
  report('S4b: screen effect "%s" playing for %ds — do you SEE it?', name, seconds)
  SetTimeout(seconds * 1000, function()
    AnimpostfxStop(name)
    report('S4b: screen effect "%s" stopped.', name)
  end)
end

function spikes.sound(args)
  local ref = args[1] or Config.Spikes.soundset.ref
  local name = args[2] or Config.Spikes.soundset.name

  -- audio/soundsets/README.md example natives:
  local tries = 0
  while not Citizen.InvokeNative(0xD9130842D7226045, ref, 0) and tries < 300 do -- load soundset
    Wait(10); tries = tries + 1
  end
  if not Citizen.InvokeNative(0xD9130842D7226045, ref, 0) then
    return report('S5: soundset "%s" failed to load — its audio bank may need loading first.', ref)
  end

  soundsetLoadedRef = ref
  local pos = aheadOfPlayer(3.0)
  Citizen.InvokeNative(0xCCE219C922737BFA, name, pos.x, pos.y, pos.z - 1.0, ref, true, 0, true, 0) -- PLAY_SOUND_FROM_POSITION
  report('S5: playing "%s" from soundset "%s" just ahead of you — do you HEAR it?', name, ref)
end

function spikes.carriable(args)
  local prop = spawnSpikeProp(args[1])
  if not prop then return end

  FreezeEntityPosition(prop, false)
  for _, flag in ipairs(Config.Spikes.carryingFlags) do
    Citizen.InvokeNative(0x18FF3110CF47115D, prop, flag, true) -- carrying-flag setter (AI/CARRYING_FLAGS/README.md)
  end
  report('S6a: crate spawned with carrying flags %s.', table.concat(Config.Spikes.carryingFlags, ','))
  report('S6a: walk to it — does a PICK UP prompt appear? Can you carry it, stow it on your horse, drop it?')
  report('S6a: while carrying, run /swspike place to test native placement.')
end

function spikes.place()
  local ped = PlayerPedId()
  local carried = Citizen.InvokeNative(0xD806CD2A4F2C2996, ped) -- GET_PED_CARRIED_ENTITY (community natives list)
  if not carried or carried == 0 then
    return report('S6b: you are not carrying anything the game recognizes. Pick up the spike crate first.')
  end
  local pos = aheadOfPlayer(2.0)
  Citizen.InvokeNative(0xC7F0B43DCDC57E3D, ped, carried, pos.x, pos.y, pos.z, 10.0, 1) -- TASK_PLACE_CARRIED_ENTITY_AT_COORD (community natives list)
  report('S6b: placement tasked — did your character physically set the object down ahead? If yes, native route PASSES.')
end

function spikes.attach(args)
  local prop = spawnSpikeProp(args[1])
  if not prop then return end

  local ped = PlayerPedId()
  -- Fallback route probe: named native (no raw hash). If this errors, the F8
  -- console shows it — that itself is the spike result.
  local ok, err = pcall(function()
    AttachEntityToEntity(prop, ped, 0, 0.0, 0.35, 0.55, 0.0, 0.0, 0.0, false, false, false, false, 2, true, false, false)
  end)
  if ok then
    report('S6c: crate attached to your torso (no animation — that is Phase 2 work). Fallback route core PASSES.')
    report('S6c: /swspike cleanup removes it.')
  else
    report('S6c: AttachEntityToEntity FAILED: %s — record this in TECH_SPEC.', tostring(err))
  end
end

function spikes.cleanup()
  if ptfxHandle then
    if Citizen.InvokeNative(0x9DD5AFF561E88F2A, ptfxHandle) then -- DoesParticleFxLoopedExist
      Citizen.InvokeNative(0x459598F579C98929, ptfxHandle, false) -- RemoveParticleFx
    end
    ptfxHandle = nil
  end
  if soundsetLoadedRef then
    Citizen.InvokeNative(0x531A78D6BF27014B, soundsetLoadedRef) -- release soundset (required per soundsets README)
    soundsetLoadedRef = nil
  end
  for _, entity in ipairs(spawnedEntities) do
    if DoesEntityExist(entity) then
      if IsEntityAttached(entity) then DetachEntity(entity, true, true) end
      DeleteEntity(entity)
    end
  end
  spawnedEntities = {}
  lastSpikePed = nil
  lastSpikeProp = nil
  report('cleanup done — all spike entities and effects removed.')
end

-- dispatcher ---------------------------------------------------------------

RegisterNetEvent('sovereign_storyworks:client:runSpike', function(spike, args)
  local fn = spikes[spike]
  if not fn then return report('unknown spike "%s"', tostring(spike)) end
  CreateThread(function()
    local ok, err = pcall(fn, args or {})
    if not ok then
      report('spike "%s" ERRORED: %s — paste this line to Claude.', spike, tostring(err))
    end
  end)
end)

-- safety: remove spike entities if the resource stops mid-test
AddEventHandler('onResourceStop', function(resourceName)
  if resourceName == GetCurrentResourceName() then
    spikes.cleanup()
  end
end)

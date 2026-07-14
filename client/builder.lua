-- Sovereign Storyworks — builder client bridge
-- Phase 5 (Builder NUI I) | Features: A5 (in-world capture), A7 (ACE-gated open)
-- Opens the builder NUI (focus), relays NUI actions to the server on tokens and
-- resolves the replies, and serves in-world coordinate capture locally.

local pending = {}         -- token -> NUI cb
local canOpenCb = nil
local builderOpen = false
local nextToken = 0

local function newToken()
  nextToken = nextToken + 1
  return ('%d_%d'):format(GetGameTimer(), nextToken)
end

-- server request/reply --------------------------------------------------------

RegisterNetEvent('sovereign_storyworks:client:builderReply', function(token, ok, data)
  local cb = pending[token]
  if cb then
    pending[token] = nil
    cb({ ok = ok, data = data or {} })
  end
end)

-- NUI relays every builder data action through here
RegisterNUICallback('builder', function(body, cb)
  if type(body) ~= 'table' or type(body.action) ~= 'string' then return cb({ ok = false }) end
  local token = newToken()
  pending[token] = cb
  TriggerServerEvent('sovereign_storyworks:server:builder', body.action, token, body.payload)
end)

-- in-world capture (A5): resolve locally, no server round-trip
RegisterNUICallback('capture', function(_, cb)
  local ped = PlayerPedId()
  local c = GetEntityCoords(ped)
  cb({ x = math.floor(c.x * 100 + 0.5) / 100, y = math.floor(c.y * 100 + 0.5) / 100, z = math.floor(c.z * 100 + 0.5) / 100, heading = math.floor(GetEntityHeading(ped) * 10 + 0.5) / 10 })
end)

-- close from within the NUI
RegisterNUICallback('builder:close', function(_, cb)
  builderOpen = false
  SetNuiFocus(false, false)
  cb({ ok = true })
end)

-- open flow -------------------------------------------------------------------

RegisterNetEvent('sovereign_storyworks:client:builderCanOpen', function(token, allowed)
  if canOpenCb then
    local fn = canOpenCb
    canOpenCb = nil
    fn(allowed)
  end
end)

local function openBuilder()
  if builderOpen then return end
  canOpenCb = function(allowed)
    if not allowed then
      exports.sovereign_notify:Card(nil, 'Builder', 'You do not have builder permission.')
      return
    end
    builderOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'builder:open' })
  end
  TriggerServerEvent('sovereign_storyworks:server:builderCanOpen', newToken())
end

RegisterCommand('storyworks', openBuilder, false)

-- Esc closes (NUI also has a close control)
CreateThread(function()
  while true do
    if builderOpen then
      Wait(0)
      if IsControlJustReleased(0, 0x156F7119) then -- INPUT_FRONTEND_CANCEL (Esc)
        builderOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ type = 'builder:close' })
      end
    else
      Wait(250)
    end
  end
end)

AddEventHandler('onResourceStop', function(resourceName)
  if resourceName == GetCurrentResourceName() and builderOpen then
    SetNuiFocus(false, false)
  end
end)

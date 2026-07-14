-- Sovereign Storyworks — builder server API
-- Phase 5 (Builder NUI I) | Features: A4, A7 (ACE gate), J1 (draft persistence), L2
-- Request/reply over net events: the client NUI relays a token; we ACE-check,
-- act, and reply on that token. Every builder action requires storyworks.builder.

local function isBuilder(source)
  return IsPlayerAceAllowed(source, 'storyworks.builder')
end

local function reply(source, token, ok, data)
  TriggerClientEvent('sovereign_storyworks:client:builderReply', source, token, ok, data)
end

local function guard(source, token)
  if SWRateLimit.IsLimited(source, 'builderAction') then
    reply(source, token, false, { error = 'Slow down a moment.' })
    return false
  end
  if not isBuilder(source) then
    reply(source, token, false, { error = 'You do not have builder permission.' })
    return false
  end
  return true
end

RegisterNetEvent('sovereign_storyworks:server:builder', function(action, token, payload)
  local source = source
  if not guard(source, token) then return end

  if action == 'bootstrap' then
    reply(source, token, true, {
      schemas = SWSchemas.All(),
      missions = SWMissions.List(),
    })

  elseif action == 'list' then
    reply(source, token, true, { missions = SWMissions.List() })

  elseif action == 'load' then
    local def = SWMissions.Load(payload and payload.code)
    if def then reply(source, token, true, { def = def })
    else reply(source, token, false, { error = 'That mission could not be loaded.' }) end

  elseif action == 'save' then
    if type(payload) ~= 'table' or type(payload.def) ~= 'table' then
      return reply(source, token, false, { error = 'Nothing to save.' })
    end
    local ok, err = SWMissions.SaveDraft(payload.def)
    if ok then
      SWLog.Info('builder: draft saved "%s" by %s', tostring(payload.def.code), source)
      reply(source, token, true, { missions = SWMissions.List() })
    else
      reply(source, token, false, { error = err })
    end

  elseif action == 'publish' then
    if type(payload) ~= 'table' or type(payload.def) ~= 'table' then
      return reply(source, token, false, { error = 'Nothing to publish.' })
    end
    -- always keep a draft copy saved first, so a failed publish never loses work
    SWMissions.SaveDraft(payload.def)
    local ok, err = SWMissions.Publish(payload.def)
    if ok then
      SWLog.Info('builder: published "%s" by %s', tostring(payload.def.code), source)
      reply(source, token, true, { missions = SWMissions.List() })
    else
      reply(source, token, false, { error = err }) -- creator-friendly validation message
    end

  elseif action == 'archive' then
    SWMissions.Archive(payload and payload.code)
    reply(source, token, true, { missions = SWMissions.List() })

  else
    reply(source, token, false, { error = 'Unknown builder action.' })
  end
end)

-- expose the ACE result so the client only opens the builder for the permitted
RegisterNetEvent('sovereign_storyworks:server:builderCanOpen', function(token)
  local source = source
  TriggerClientEvent('sovereign_storyworks:client:builderCanOpen', source, token, isBuilder(source))
end)

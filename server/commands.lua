-- Sovereign Storyworks — runtime admin/test commands
-- Phase 1 (Mission Runtime Core) | Features: B1, L2 (ACE + rate limit on every command)
-- Phase-1 test surface; players get missions through the journal/NPCs in later phases.

local function chat(source, message)
  TriggerClientEvent('chat:addMessage', source, { args = { '^6Storyworks', message } })
end

local function guard(source)
  if source == 0 then
    SWLog.Info('runtime commands need a player (they act on your character).')
    return false
  end
  if not IsPlayerAceAllowed(source, Config.Ace.admin) then
    chat(source, T('no_permission'))
    return false
  end
  if SWRateLimit.IsLimited(source, 'runtimeCommand') then
    chat(source, T('rate_limited'))
    return false
  end
  return true
end

RegisterCommand('swstart', function(source, args)
  if not guard(source) then return end

  local code = args[1]
  if not code then return chat(source, T('swstart_usage')) end

  local ok, errKey = SWInstances.Start(source, code)
  if not ok then chat(source, T(errKey)) end
end, false)

RegisterCommand('swcancel', function(source)
  if not guard(source) then return end

  local ok, errKey = SWInstances.Cancel(source)
  if not ok then chat(source, T(errKey)) end
end, false)

RegisterCommand('swmissions', function(source)
  if not guard(source) then return end

  local codes = SWMissions.ListCodes()
  if #codes == 0 then return chat(source, T('no_missions')) end
  chat(source, T('missions_header', #codes))
  for _, line in ipairs(codes) do chat(source, line) end
end, false)

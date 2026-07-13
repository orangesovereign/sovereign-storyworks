-- Sovereign Storyworks — client prompt display
-- Phase 2 | Features: B2 (hold-action, choice, deliver prompts)
-- Display only. The client draws the prompt and reports "held to completion";
-- the SERVER validates the report (armed id, position, timing, rate limit)
-- before anything happens. All natives verified against vorp_banking /
-- vorp_core respawnsystem / vorp_inventory (UiPrompt family).

local promptGroup = GetRandomIntInRange(0, 0xffffff)
local current = nil -- { id, mode, prompts = {p1, p2?}, target, radius, reported }

local function makePrompt(keyHash, text, holdMs)
  local prompt = UiPromptRegisterBegin()
  UiPromptSetControlAction(prompt, keyHash)
  UiPromptSetText(prompt, VarString(10, 'LITERAL_STRING', text))
  UiPromptSetEnabled(prompt, true)
  UiPromptSetVisible(prompt, true)
  UiPromptSetHoldMode(prompt, holdMs) -- vorp_core respawnsystem.lua:196
  UiPromptSetGroup(prompt, promptGroup, 0)
  UiPromptRegisterEnd(prompt)
  return prompt
end

local function destroyCurrent()
  if not current then return end
  for _, p in ipairs(current.prompts) do
    UiPromptDelete(p) -- vorp_inventory InventoryService.lua:479
  end
  current = nil
end

RegisterNetEvent('sovereign_storyworks:client:interaction', function(data)
  destroyCurrent()
  if type(data) ~= 'table' then return end

  local keys = ConfigRuntime.Interact
  local prompts = {}

  if data.mode == 'hold' then
    prompts[1] = makePrompt(keys.holdKey, data.label or '', data.holdMs or keys.defaultHoldMs)
  elseif data.mode == 'choice' then
    prompts[1] = makePrompt(keys.choiceKeyA, data.optionA or 'Option 1', data.holdMs or keys.choiceHoldMs)
    prompts[2] = makePrompt(keys.choiceKeyB, data.optionB or 'Option 2', data.holdMs or keys.choiceHoldMs)
  else
    return
  end

  current = {
    id = data.id,
    mode = data.mode,
    prompts = prompts,
    target = data.target and vector3(data.target.x, data.target.y, data.target.z) or nil,
    radius = data.radius or 2.5,
    groupLabel = data.question or data.label or '',
    reported = false,
  }
end)

CreateThread(function()
  while true do
    if not current then
      Wait(250)
    else
      Wait(0)
      local show = true
      if current.target then
        local dist = #(GetEntityCoords(PlayerPedId()) - current.target)
        show = dist <= current.radius
      end

      if show then
        UiPromptSetActiveGroupThisFrame(promptGroup, VarString(10, 'LITERAL_STRING', current.groupLabel), 0, 0, 0, 0) -- vorp_banking client.lua:153

        if not current.reported then
          if current.mode == 'hold' then
            if UiPromptHasHoldModeCompleted(current.prompts[1]) then
              current.reported = true
              TriggerServerEvent('sovereign_storyworks:server:interactionDone', current.id)
            end
          else
            if UiPromptHasHoldModeCompleted(current.prompts[1]) then
              current.reported = true
              TriggerServerEvent('sovereign_storyworks:server:interactionDone', current.id, 1)
            elseif UiPromptHasHoldModeCompleted(current.prompts[2]) then
              current.reported = true
              TriggerServerEvent('sovereign_storyworks:server:interactionDone', current.id, 2)
            end
          end
        end
      end
    end
  end
end)

AddEventHandler('onResourceStop', function(resourceName)
  if resourceName == GetCurrentResourceName() then
    destroyCurrent()
  end
end)

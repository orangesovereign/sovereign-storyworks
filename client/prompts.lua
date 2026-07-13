-- Sovereign Storyworks — client prompt display
-- Phase 2 | Features: B2 (hold-action, choice, deliver prompts)
-- Display only. The client draws the prompt and reports "held to completion";
-- the SERVER validates the report (armed id, position, timing, rate limit)
-- before anything happens. All natives verified against vorp_banking /
-- vorp_core respawnsystem / vorp_inventory (UiPrompt family).

local current = nil -- { id, mode, group, prompts = {p1, p2?}, target, radius, reported }

local function makePrompt(group, keyHash, text, holdMs)
  local prompt = UiPromptRegisterBegin()
  UiPromptSetControlAction(prompt, keyHash)
  UiPromptSetText(prompt, VarString(10, 'LITERAL_STRING', text))
  UiPromptSetEnabled(prompt, true)
  UiPromptSetVisible(prompt, true)
  UiPromptSetHoldMode(prompt, holdMs) -- vorp_core respawnsystem.lua:196
  UiPromptSetGroup(prompt, group, 0)
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

  print(('[sovereign_storyworks] interaction received: %s #%s'):format(tostring(data.mode), tostring(data.id)))

  local keys = ConfigRuntime.Interact
  local prompts = {}
  -- fresh group per interaction (round 2: choice prompts registered into a
  -- group that had been emptied seconds earlier never displayed)
  local group = GetRandomIntInRange(0, 0xffffff)

  if data.mode == 'hold' then
    prompts[1] = makePrompt(group, keys.holdKey, data.label or '', data.holdMs or keys.defaultHoldMs)
  elseif data.mode == 'choice' then
    prompts[1] = makePrompt(group, keys.choiceKeyA, data.optionA or 'Option 1', data.holdMs or keys.choiceHoldMs)
    prompts[2] = makePrompt(group, keys.choiceKeyB, data.optionB or 'Option 2', data.holdMs or keys.choiceHoldMs)
  else
    return
  end

  current = {
    id = data.id,
    mode = data.mode,
    group = group,
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
      -- snapshot: the clear event can null `current` DURING the Wait above
      -- (owner-reported nil-index crash); skip the frame if it did
      local cur = current
      if cur then
        local show = true
        if cur.target then
          local dist = #(GetEntityCoords(PlayerPedId()) - cur.target)
          show = dist <= cur.radius
        end

        if show then
          UiPromptSetActiveGroupThisFrame(cur.group, VarString(10, 'LITERAL_STRING', cur.groupLabel), 0, 0, 0, 0) -- vorp_banking client.lua:153

          if not cur.reported then
            if cur.mode == 'hold' then
              if UiPromptHasHoldModeCompleted(cur.prompts[1]) then
                cur.reported = true
                TriggerServerEvent('sovereign_storyworks:server:interactionDone', cur.id)
              end
            else
              if UiPromptHasHoldModeCompleted(cur.prompts[1]) then
                cur.reported = true
                TriggerServerEvent('sovereign_storyworks:server:interactionDone', cur.id, 1)
              elseif UiPromptHasHoldModeCompleted(cur.prompts[2]) then
                cur.reported = true
                TriggerServerEvent('sovereign_storyworks:server:interactionDone', cur.id, 2)
              end
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

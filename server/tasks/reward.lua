-- Sovereign Storyworks — logic node: grant rewards
-- Phase 4 (Story Logic, Progression & Scheduling) | Features: B4, C4
-- Grants one or more rewards, then follows the SUCCESS edge. Money/gold/xp and
-- inventory items, all through the S1-verified VORP surface. Item grants are
-- async; the node completes once every grant has been applied.
--
-- config:
--   money, gold, xp   numeric amounts to grant (any subset)
--   items             { { item = 'name', amount = n }, ... }
--   announce          false to suppress the "you received" tip (default true)

SWTasks.Register('reward', {
  label = 'Grant a reward',

  validate = function(config)
    for _, k in ipairs({ 'money', 'gold', 'xp' }) do
      if config[k] ~= nil and type(config[k]) ~= 'number' then
        return false, k .. ' must be a number'
      end
    end
    if config.items ~= nil then
      if type(config.items) ~= 'table' then return false, 'items must be an array' end
      for i, it in ipairs(config.items) do
        if type(it) ~= 'table' or type(it.item) ~= 'string' then
          return false, ('items[%d] needs an item name'):format(i)
        end
      end
    end
    return true
  end,

  start = function(ctx)
    local cfg = ctx.config
    local source, char = ctx.Leader()
    if not char then return ctx.Complete(true) end -- nothing to grant to; don't stall the story

    local parts = {}
    for _, kind in ipairs({ 'money', 'gold', 'xp' }) do
      if cfg[kind] and cfg[kind] > 0 then
        SWVorp.GiveCurrency(char, kind, cfg[kind])
        parts[#parts + 1] = T('reward_currency_' .. kind, cfg[kind])
      end
    end

    local items = cfg.items or {}
    local pending = #items

    local function finish()
      if cfg.announce ~= false and #parts > 0 then
        ctx.Notify('tip', T('reward_received', table.concat(parts, ', ')))
      end
      ctx.Complete(true)
    end

    if pending == 0 then return finish() end

    for _, it in ipairs(items) do
      local amount = it.amount or 1
      SWVorp.GiveItem(source, it.item, amount, function()
        parts[#parts + 1] = ('%dx %s'):format(amount, it.item)
        pending = pending - 1
        if pending == 0 then finish() end
      end)
    end
  end,
})

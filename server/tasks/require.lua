-- Sovereign Storyworks — logic node: requirement gate
-- Phase 4 (Story Logic, Progression & Scheduling) | Features: B4, C3, C4
-- Checks a resource requirement and branches: SUCCESS edge if met, FAILURE edge
-- if not. Optionally CONSUMES the requirement when met (C4). Items and currency
-- both supported; item reads are async through vorp_inventory.
--
-- config:
--   kind      'item' | 'money' | 'gold' | 'xp' | 'job' | 'grade'
--   item      item name (kind='item')
--   amount    quantity/threshold (default 1)
--   job       required job (kind='job')
--   consume   true → take the item/currency when the requirement is met (C4)
--   message   optional tip shown when the requirement is NOT met

local function fail(ctx)
  if ctx.config.message then ctx.Notify('tip', ctx.config.message) end
  ctx.Complete(false)
end

SWTasks.Register('require', {
  label = 'Require something',

  validate = function(config)
    local kinds = { item=true, money=true, gold=true, xp=true, job=true, grade=true }
    if not kinds[config.kind] then return false, 'require kind must be item/money/gold/xp/job/grade' end
    if config.kind == 'item' and (type(config.item) ~= 'string' or config.item == '') then
      return false, 'require item needs an item name'
    end
    if config.kind == 'job' and (type(config.job) ~= 'string' or config.job == '') then
      return false, 'require job needs a job name'
    end
    return true
  end,

  start = function(ctx)
    local cfg = ctx.config
    local source, char = ctx.Leader()
    if not char then return fail(ctx) end
    local amount = cfg.amount or 1

    if cfg.kind == 'job' then
      return ctx.Complete(SWVorp.Job(char) == cfg.job)
    elseif cfg.kind == 'grade' then
      return ctx.Complete(SWVorp.Grade(char) >= amount)
    elseif cfg.kind == 'money' or cfg.kind == 'gold' or cfg.kind == 'xp' then
      local have = SWVorp.CurrencyAmount(char, cfg.kind)
      if have < amount then return fail(ctx) end
      if cfg.consume then SWVorp.TakeCurrency(char, cfg.kind, amount) end
      return ctx.Complete(true)
    elseif cfg.kind == 'item' then
      SWVorp.ItemCount(source, cfg.item, function(count)
        if (count or 0) < amount then return fail(ctx) end
        if cfg.consume then
          SWVorp.TakeItem(source, cfg.item, amount, function() ctx.Complete(true) end)
        else
          ctx.Complete(true)
        end
      end)
    end
  end,
})

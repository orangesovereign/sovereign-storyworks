-- Sovereign Storyworks — logic node: condition branch
-- Phase 4 (Story Logic, Progression & Scheduling) | Features: C3
-- Instant-resolving: evaluates a comparison and follows SUCCESS (true) or
-- FAILURE (false) edge. Synchronous checks only (variables, job, grade,
-- money, gold, xp, time of day) — item/resource checks live in the `require`
-- node because inventory reads are async.
--
-- config:
--   source   'var' | 'job' | 'grade' | 'money' | 'gold' | 'xp' | 'timeofday'
--   name     variable name (source='var')
--   op       'eq' | 'ne' | 'gte' | 'lte' | 'gt' | 'lt' | 'contains' | 'exists'
--   value    comparison operand (for timeofday: hour 0-23; two values via
--            value/value2 make an inclusive hour window)
--   value2   optional upper bound for timeofday window

local function readSource(ctx)
  local src = ctx.config.source
  if src == 'var' then return ctx.GetVar(ctx.config.name) end
  local _, char = ctx.Leader()
  if src == 'job' then return char and char.job or nil end
  if src == 'grade' then return char and tonumber(char.jobgrade) or 0 end
  if src == 'money' then return char and tonumber(char.money) or 0 end
  if src == 'gold' then return char and tonumber(char.gold) or 0 end
  if src == 'xp' then return char and tonumber(char.xp) or 0 end
  if src == 'timeofday' then return nil end -- handled specially
  return nil
end

local function compare(op, a, b)
  if op == 'exists' then return a ~= nil end
  if op == 'eq' then return a == b or tostring(a) == tostring(b) end
  if op == 'ne' then return not (a == b or tostring(a) == tostring(b)) end
  if op == 'contains' then return type(a) == 'string' and a:find(tostring(b), 1, true) ~= nil end
  local na, nb = tonumber(a), tonumber(b)
  if na == nil or nb == nil then return false end
  if op == 'gte' then return na >= nb end
  if op == 'lte' then return na <= nb end
  if op == 'gt' then return na > nb end
  if op == 'lt' then return na < nb end
  return false
end

SWTasks.Register('condition', {
  label = 'Check a condition',

  validate = function(config)
    local sources = { ['var']=true, job=true, grade=true, money=true, gold=true, xp=true, timeofday=true }
    if not sources[config.source] then
      return false, 'condition source must be var/job/grade/money/gold/xp/timeofday'
    end
    if config.source == 'var' and (type(config.name) ~= 'string' or config.name == '') then
      return false, 'condition on a var needs a name'
    end
    return true
  end,

  start = function(ctx)
    local result

    if ctx.config.source == 'timeofday' then
      local hour = SWGameTime.Hour()
      local lo = tonumber(ctx.config.value) or 0
      local hi = ctx.config.value2 ~= nil and tonumber(ctx.config.value2) or lo
      if lo <= hi then
        result = hour >= lo and hour <= hi
      else
        result = hour >= lo or hour <= hi -- window wraps midnight
      end
    else
      result = compare(ctx.config.op or 'eq', readSource(ctx), ctx.config.value)
    end

    ctx.Complete(result and true or false)
  end,
})

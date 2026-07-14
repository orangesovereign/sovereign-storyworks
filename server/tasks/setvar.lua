-- Sovereign Storyworks — logic node: set a story variable
-- Phase 4 (Story Logic, Progression & Scheduling) | Features: C3
-- Instant-resolving: mutates a variable and follows the SUCCESS edge. Variables
-- live in the instance state and persist across resume; on story completion the
-- persisted set carries to the next chapter (C2).
--
-- config:
--   name    variable name (required)
--   op      'set' | 'add' | 'sub' | 'toggle' | 'append'  (default 'set')
--   value   the operand (number for add/sub, string for append, any for set)

SWTasks.Register('setvar', {
  label = 'Remember a value',

  validate = function(config)
    if type(config.name) ~= 'string' or config.name == '' then
      return false, 'setvar needs a name'
    end
    local op = config.op or 'set'
    local ops = { set = true, add = true, sub = true, toggle = true, append = true }
    if not ops[op] then return false, 'op must be set/add/sub/toggle/append' end
    return true
  end,

  start = function(ctx)
    local name = ctx.config.name
    local op = ctx.config.op or 'set'
    local cur = ctx.GetVar(name)
    local val = ctx.config.value

    if op == 'set' then
      ctx.SetVar(name, val)
    elseif op == 'add' then
      ctx.SetVar(name, (tonumber(cur) or 0) + (tonumber(val) or 0))
    elseif op == 'sub' then
      ctx.SetVar(name, (tonumber(cur) or 0) - (tonumber(val) or 0))
    elseif op == 'toggle' then
      ctx.SetVar(name, not cur)
    elseif op == 'append' then
      ctx.SetVar(name, tostring(cur or '') .. tostring(val or ''))
    end

    ctx.Complete(true)
  end,
})

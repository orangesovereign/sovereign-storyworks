-- Sovereign Storyworks — task-type registry
-- Phase 1 (Mission Runtime Core) | Features: B1
-- Every task type is a self-contained module registered here with a declared
-- lifecycle. The builder (Phase 5) renders task config generically from these
-- declarations, so new task types never require NUI rework.

SWTasks = {}

local types = {}

---Register a task type.
---def = {
---  label     = human-readable name,
---  validate  = function(config) -> ok, err   (publish/seed-time config check)
---  start     = function(ctx)                 (node entered; arm whatever is needed)
---  tick      = function(ctx) or nil          (called every runtime poll while active)
---  stop      = function(ctx) or nil          (node left for ANY reason; release everything)
---}
---ctx = {
---  instance,             -- runtime instance table
---  node,                 -- the mission-definition node
---  config,               -- node.config
---  state,                -- instance-persistent state table (survives resume)
---  Complete(success),    -- report the task finished; engine follows the edge
---  ForEachParticipant(fn(source, charIdentifier)),
---  Notify(kind, text),   -- participant notification through K4 ('objective' or 'tip')
---}
function SWTasks.Register(name, def)
  if types[name] then
    SWLog.Warn('task type "%s" registered twice — keeping the first', name)
    return
  end
  if type(def.start) ~= 'function' then
    SWLog.Error('task type "%s" has no start function — ignored', name)
    return
  end
  types[name] = def
  SWLog.Debug('task type registered: %s', name)
end

function SWTasks.Get(name)
  return types[name]
end

function SWTasks.List()
  local names = {}
  for name in pairs(types) do names[#names + 1] = name end
  table.sort(names)
  return names
end

-- Sovereign Storyworks — mission definition store & validation
-- Phase 1 (Mission Runtime Core) | Features: B1, B3 (edge validation)
-- Definitions are JSON documents (schema 1). Hand-authored in Phase 1;
-- the builder authors them from Phase 5. Only validated, published missions
-- can be started.

SWMissions = {}

local published = {} -- code -> { id, code, title, def }

---Validate a decoded mission definition. Returns ok, err.
function SWMissions.Validate(def)
  if type(def) ~= 'table' then return false, 'definition is not a table' end
  if def.schema ~= 1 then return false, ('unsupported schema version %s'):format(tostring(def.schema)) end
  if type(def.code) ~= 'string' or def.code == '' then return false, 'missing code' end
  if type(def.title) ~= 'string' or def.title == '' then return false, 'missing title' end
  if type(def.nodes) ~= 'table' then return false, 'missing nodes table' end
  if type(def.start) ~= 'string' or not def.nodes[def.start] then
    return false, ('start node "%s" does not exist'):format(tostring(def.start))
  end

  local count = 0
  for nodeId, node in pairs(def.nodes) do
    count = count + 1
    if type(node) ~= 'table' then return false, ('node "%s" is not a table'):format(nodeId) end

    local taskType = SWTasks.Get(node.type)
    if not taskType then
      return false, ('node "%s" uses unknown task type "%s"'):format(nodeId, tostring(node.type))
    end

    if taskType.validate then
      local ok, err = taskType.validate(node.config or {})
      if not ok then return false, ('node "%s": %s'):format(nodeId, tostring(err)) end
    end

    for _, edge in ipairs({ 'onSuccess', 'onFailure' }) do
      local target = node[edge]
      if target ~= nil and not def.nodes[target] then
        return false, ('node "%s" %s points to missing node "%s"'):format(nodeId, edge, target)
      end
    end
  end

  if count == 0 then return false, 'mission has no nodes' end
  return true
end

---Insert or update a mission from a JSON string; publishes it when valid.
---Returns ok, err.
function SWMissions.UpsertFromJson(jsonStr, sourceName)
  local ok, def = pcall(json.decode, jsonStr)
  if not ok or type(def) ~= 'table' then
    return false, ('%s: JSON did not parse'):format(sourceName or '?')
  end

  local valid, err = SWMissions.Validate(def)
  if not valid then
    return false, ('%s: %s'):format(sourceName or '?', err)
  end

  local id = MySQL.query.await([[
    INSERT INTO `sovereign_missions` (`code`, `title`, `status`, `definition`)
    VALUES (?, ?, 'published', ?)
    ON DUPLICATE KEY UPDATE `title` = VALUES(`title`), `definition` = VALUES(`definition`),
      `status` = 'published', `id` = LAST_INSERT_ID(`id`)
  ]], { def.code, def.title, jsonStr })

  local row = MySQL.single.await('SELECT `id` FROM `sovereign_missions` WHERE `code` = ?', { def.code })
  published[def.code] = { id = row and row.id, code = def.code, title = def.title, def = def }
  return true
end

---Load every published mission from the DB into the cache.
function SWMissions.LoadAll()
  published = {}
  local rows = MySQL.query.await("SELECT `id`, `code`, `title`, `definition` FROM `sovereign_missions` WHERE `status` = 'published'") or {}
  for _, row in ipairs(rows) do
    local ok, def = pcall(json.decode, row.definition)
    if ok and type(def) == 'table' then
      local valid, err = SWMissions.Validate(def)
      if valid then
        published[row.code] = { id = row.id, code = row.code, title = row.title, def = def }
      else
        SWLog.Warn('published mission "%s" failed validation and was skipped: %s', row.code, tostring(err))
      end
    else
      SWLog.Warn('published mission "%s" has unparseable JSON and was skipped', row.code)
    end
  end
  SWLog.Info('%d published mission(s) loaded.', SWMissions.Count())
end

function SWMissions.GetByCode(code)
  return published[code]
end

function SWMissions.Count()
  local n = 0
  for _ in pairs(published) do n = n + 1 end
  return n
end

function SWMissions.ListCodes()
  local codes = {}
  for code, entry in pairs(published) do codes[#codes + 1] = ('%s — %s'):format(code, entry.title) end
  table.sort(codes)
  return codes
end

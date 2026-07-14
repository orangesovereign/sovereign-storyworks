-- Sovereign Storyworks — per-character progression, scheduling & availability
-- Phase 4 (Story Logic, Progression & Scheduling) | Features: C1, C2, D1, D3
-- Completion history + persisted story variables per (character, mission), plus
-- the availability gate that combines access (D2, via SWVorp), unlock
-- prerequisites (C1), repeatability (D3), and daily/weekly/monthly reset cycles
-- (D1). Scheduling is real-world time (server os.time) — server-authoritative.

SWProgress = {}

-- history ---------------------------------------------------------------------

---Load a character's progress row for a mission: { count, lastAt (epoch|nil), vars }.
function SWProgress.Load(charIdentifier, missionCode)
  local row = MySQL.single.await(
    'SELECT `completion_count`, UNIX_TIMESTAMP(`last_completed_at`) AS last_at, `vars` FROM `sovereign_story_progress` WHERE `char_identifier` = ? AND `mission_code` = ?',
    { charIdentifier, missionCode }
  )
  if not row then return { count = 0, lastAt = nil, vars = {} } end
  local vars = {}
  if row.vars then
    local ok, decoded = pcall(json.decode, row.vars)
    if ok and type(decoded) == 'table' then vars = decoded end
  end
  return { count = tonumber(row.completion_count) or 0, lastAt = row.last_at and tonumber(row.last_at) or nil, vars = vars }
end

---Record a completion: bump count, stamp time, persist the story variables (C2).
function SWProgress.RecordCompletion(charIdentifier, missionCode, vars)
  local payload = json.encode(vars or {})
  MySQL.query.await([[
    INSERT INTO `sovereign_story_progress` (`char_identifier`, `mission_code`, `completion_count`, `last_completed_at`, `vars`)
    VALUES (?, ?, 1, NOW(), ?)
    ON DUPLICATE KEY UPDATE `completion_count` = `completion_count` + 1, `last_completed_at` = NOW(), `vars` = VALUES(`vars`)
  ]], { charIdentifier, missionCode, payload })
end

function SWProgress.CompletionCount(charIdentifier, missionCode)
  return SWProgress.Load(charIdentifier, missionCode).count
end

-- reset cycles (D1) -----------------------------------------------------------

---Epoch of the current cycle's start boundary for a schedule cycle
---('daily'|'weekly'|'monthly'). A completion before this boundary means the
---mission is available again.
function SWProgress.CycleStart(cycle)
  local cfg = ConfigRuntime.Schedule
  local resetHour = cfg.resetHour or 6
  local now = os.time()
  local t = os.date('*t', now)

  -- today's reset moment
  local todayReset = os.time({ year = t.year, month = t.month, day = t.day, hour = resetHour, min = 0, sec = 0 })

  if cycle == 'daily' then
    if now >= todayReset then return todayReset end
    return todayReset - 86400 -- before today's reset → cycle started yesterday
  elseif cycle == 'weekly' then
    -- most recent configured week-start day at reset hour
    local wday = t.wday -- 1=Sunday … 7=Saturday (Lua)
    local weekStart = cfg.weekStart or 1
    local daysBack = (wday - weekStart) % 7
    local startDay = todayReset - daysBack * 86400
    if daysBack == 0 and now < todayReset then startDay = startDay - 7 * 86400 end
    return startDay
  elseif cycle == 'monthly' then
    local monthReset = os.time({ year = t.year, month = t.month, day = 1, hour = resetHour, min = 0, sec = 0 })
    if now >= monthReset then return monthReset end
    -- before the 1st's reset hour → previous month
    local pm = t.month - 1
    local py = t.year
    if pm < 1 then pm = 12; py = py - 1 end
    return os.time({ year = py, month = pm, day = 1, hour = resetHour, min = 0, sec = 0 })
  end
  return 0
end

-- availability gate -----------------------------------------------------------

---Can this character start this mission right now?
---Returns ok, reasonLocaleKey. Meta is the mission's optional metadata:
---  access   = { jobs, minGrade, maxGrade }        (D2)
---  unlock   = { requires = { 'missionCode', ... } } (C1 prereqs)
---  schedule = { cycle = 'daily'|'weekly'|'monthly' } (D1)
---  repeat   = 'once' | 'per_cycle' | 'unlimited'   (D3; default 'unlimited')
function SWProgress.CanStart(char, charIdentifier, meta)
  meta = meta or {}

  -- D2 access
  local okAccess, reason = SWVorp.MeetsAccess(char, meta.access)
  if not okAccess then return false, reason end

  -- C1 unlock prerequisites
  if meta.unlock and type(meta.unlock.requires) == 'table' then
    for _, code in ipairs(meta.unlock.requires) do
      if SWProgress.CompletionCount(charIdentifier, code) < 1 then
        return false, 'locked_prereq'
      end
    end
  end

  local prog = SWProgress.Load(charIdentifier, meta.__code or '')
  local repeatMode = meta['repeat'] or (meta.schedule and 'per_cycle') or 'unlimited'

  -- D3 once-ever
  if repeatMode == 'once' and prog.count > 0 then
    return false, 'already_done_once'
  end

  -- D1 per-cycle (daily/weekly/monthly): a completion inside the current cycle blocks
  if (repeatMode == 'per_cycle' or meta.schedule) and prog.lastAt then
    local cycle = (meta.schedule and meta.schedule.cycle) or 'daily'
    if prog.lastAt >= SWProgress.CycleStart(cycle) then
      return false, 'on_cooldown_' .. cycle
    end
  end

  return true
end

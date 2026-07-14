-- Sovereign Storyworks — VORP integration surface
-- Phase 4 (Story Logic, Progression & Scheduling) | Features: C3, C4, D2
-- One place for every VORP read/write the runtime needs — requirements,
-- rewards, and access gating. Signatures are the S1-verified ones (TECH_SPEC
-- §1). Currency codes: 0 money, 1 gold, 2 rol. NOTE: never call the buggy
-- vorp_core removeXp — XP down goes through addXp(-n).

SWVorp = {}

local function core() return GetVorpCore() end

function SWVorp.Character(source)
  local user = core() and core().getUser(source)
  return user and user.getUsedCharacter or nil
end

-- reads -----------------------------------------------------------------------

function SWVorp.Job(char) return char and char.job or nil end
function SWVorp.Grade(char) return char and tonumber(char.jobgrade) or 0 end
function SWVorp.Money(char) return char and tonumber(char.money) or 0 end
function SWVorp.Gold(char) return char and tonumber(char.gold) or 0 end
function SWVorp.Xp(char) return char and tonumber(char.xp) or 0 end

local CURRENCY = { money = 0, gold = 1, rol = 2 }

---Read a currency amount by name ('money'|'gold'|'xp').
function SWVorp.CurrencyAmount(char, kind)
  if kind == 'money' then return SWVorp.Money(char) end
  if kind == 'gold' then return SWVorp.Gold(char) end
  if kind == 'xp' then return SWVorp.Xp(char) end
  return 0
end

-- grants (rewards) ------------------------------------------------------------

function SWVorp.GiveCurrency(char, kind, amount)
  if not char or amount == nil or amount <= 0 then return false end
  if kind == 'xp' then
    char.addXp(math.floor(amount))
    return true
  end
  local code = CURRENCY[kind]
  if code == nil then return false end
  char.addCurrency(code, amount)
  return true
end

function SWVorp.TakeCurrency(char, kind, amount)
  if not char or amount == nil or amount <= 0 then return false end
  if kind == 'xp' then
    char.addXp(-math.floor(amount)) -- removeXp is buggy in vorp_core (TECH_SPEC §1)
    return true
  end
  local code = CURRENCY[kind]
  if code == nil then return false end
  char.removeCurrency(code, amount)
  return true
end

-- items (async through vorp_inventory) ---------------------------------------

function SWVorp.ItemCount(source, item, cb)
  exports.vorp_inventory:getItemCount(source, cb, item)
end

function SWVorp.GiveItem(source, item, amount, cb)
  exports.vorp_inventory:addItem(source, item, amount, nil, function(ok) if cb then cb(ok) end end)
end

function SWVorp.TakeItem(source, item, amount, cb)
  exports.vorp_inventory:subItem(source, item, amount, nil, function(ok) if cb then cb(ok) end end)
end

-- access gating (D2) ----------------------------------------------------------

---True when the character satisfies an access spec:
---access = { jobs = {'sheriff', ...} | 'sheriff', minGrade = n, maxGrade = n }
---Returns ok, reasonLocaleKey.
function SWVorp.MeetsAccess(char, access)
  if not access then return true end
  if not char then return false, 'access_no_character' end

  if access.jobs then
    local jobs = type(access.jobs) == 'table' and access.jobs or { access.jobs }
    local job = SWVorp.Job(char)
    local match = false
    for _, j in ipairs(jobs) do if j == job then match = true break end end
    if not match then return false, 'access_wrong_job' end
  end

  local grade = SWVorp.Grade(char)
  if access.minGrade and grade < access.minGrade then return false, 'access_grade_low' end
  if access.maxGrade and grade > access.maxGrade then return false, 'access_grade_high' end

  return true
end

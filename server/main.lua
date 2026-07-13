-- Sovereign Storyworks — server boot
-- Phase 1 (Mission Runtime Core) | Features: B1, C2, L1, L2; hard VORP dependency (ruling #2)

local VorpCore = nil

local function bootRuntime()
  SWMissions.LoadAll()
  SWSeed.Run()
  SWMissions.LoadAll() -- re-read after seeding so seeded missions are live
  SWInstances.ResumeFromBoot()
  SWLog.Info('runtime ready — task types: %s', table.concat(SWTasks.List(), ', '))
  SWLog.Info('boot complete. /swmissions lists published missions; /swstart <code> runs one.')
end

local function boot()
  SWLog.Info('Sovereign Storyworks %s booting (Phase 1 — Mission Runtime Core)...',
    GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '?')

  -- Hard VORP dependency (ruling #2): fail loudly if the core is absent.
  local ok, core = pcall(function() return exports.vorp_core:GetCore() end)
  if not ok or not core then
    SWLog.Error('vorp_core is REQUIRED and was not found. Storyworks will not run. (%s)', tostring(core))
    return
  end
  VorpCore = core
  SWLog.Info('vorp_core connected.')

  if Config.AutoMigrate then
    SWMigrations.Run(function(success)
      if success then
        SWLog.Info('database ready.')
        bootRuntime()
      else
        SWLog.Error('boot HALTED: database migration failed — see error above.')
      end
    end)
  else
    SWLog.Warn('AutoMigrate is off — verify schema manually.')
    bootRuntime()
  end
end

---Shared accessor for later modules (Phase 1+).
function GetVorpCore()
  return VorpCore
end

MySQL.ready(boot)

-- Sovereign Storyworks — server boot
-- Phase 0 (Foundations & Spikes) | Features: L1, L2 scaffolding; hard VORP dependency (ruling #2)

local VorpCore = nil

local function boot()
  SWLog.Info('Sovereign Storyworks %s booting (Phase 0 — Foundations & Spikes)...',
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
        SWLog.Info('boot complete. Spike commands %s (/swspike list).',
          Config.Spikes.enabled and 'ENABLED' or 'disabled')
      else
        SWLog.Error('boot HALTED: database migration failed — see error above.')
      end
    end)
  else
    SWLog.Warn('AutoMigrate is off — verify schema manually.')
    SWLog.Info('boot complete.')
  end
end

---Shared accessor for later modules (Phase 1+).
function GetVorpCore()
  return VorpCore
end

MySQL.ready(boot)

-- Sovereign Storyworks — mission seeding from data files
-- Phase 1 (Mission Runtime Core) | Phase-1 test fixture (builder replaces this in Phase 5)

SWSeed = {}

function SWSeed.Run()
  if not ConfigRuntime.SeedMissionsFromData then return end

  for _, path in ipairs(ConfigRuntime.SeedFiles) do
    local jsonStr = LoadResourceFile(GetCurrentResourceName(), path)
    if not jsonStr then
      SWLog.Warn('seed file "%s" not found — skipped', path)
    else
      local ok, err = SWMissions.UpsertFromJson(jsonStr, path)
      if ok then
        SWLog.Info('seeded mission from %s', path)
      else
        SWLog.Error('seed failed: %s', tostring(err))
      end
    end
  end
end

-- Sovereign Storyworks — schema migration runner
-- Phase 0 (Foundations & Spikes) | Features: L1 (Config.AutoMigrate)
-- Migrations run in order, exactly once, tracked in sovereign_storyworks_migrations.
-- Must run clean on a fresh DB AND an existing one (standing rule).

SWMigrations = {}

SWMigrations.list = {
  {
    version = 1,
    name = 'phase0_foundations',
    queries = {
      [[
        CREATE TABLE IF NOT EXISTS `sovereign_storyworks_kv` (
          `k` VARCHAR(100) NOT NULL,
          `v` LONGTEXT NULL,
          `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`k`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      ]],
    },
  },
  -- Phase 1 adds mission/instance tables here as version 2+.
}

---Run all pending migrations. Calls cb(true) on success, cb(false) on failure.
function SWMigrations.Run(cb)
  local ok, err = pcall(function()
    MySQL.query.await([[
      CREATE TABLE IF NOT EXISTS `sovereign_storyworks_migrations` (
        `version` INT NOT NULL,
        `name` VARCHAR(100) NOT NULL,
        `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`version`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    local row = MySQL.single.await('SELECT MAX(`version`) AS v FROM `sovereign_storyworks_migrations`')
    local current = (row and row.v) or 0

    for _, migration in ipairs(SWMigrations.list) do
      if migration.version > current then
        SWLog.Info('applying migration %d (%s)...', migration.version, migration.name)
        for _, query in ipairs(migration.queries) do
          MySQL.query.await(query)
        end
        MySQL.insert.await(
          'INSERT INTO `sovereign_storyworks_migrations` (`version`, `name`) VALUES (?, ?)',
          { migration.version, migration.name }
        )
        SWLog.Info('migration %d applied.', migration.version)
      end
    end
  end)

  if not ok then
    SWLog.Error('migration failed: %s', tostring(err))
  end
  if cb then cb(ok) end
end

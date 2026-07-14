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
  {
    version = 2,
    name = 'phase1_runtime_core',
    queries = {
      [[
        CREATE TABLE IF NOT EXISTS `sovereign_missions` (
          `id` INT NOT NULL AUTO_INCREMENT,
          `code` VARCHAR(64) NOT NULL,
          `title` VARCHAR(128) NOT NULL,
          `status` VARCHAR(16) NOT NULL DEFAULT 'draft',
          `definition` LONGTEXT NOT NULL,
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          UNIQUE KEY `uq_code` (`code`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      ]],
      [[
        CREATE TABLE IF NOT EXISTS `sovereign_mission_instances` (
          `id` INT NOT NULL AUTO_INCREMENT,
          `mission_id` INT NULL,
          `mission_code` VARCHAR(64) NOT NULL,
          `status` VARCHAR(16) NOT NULL DEFAULT 'active',
          `current_node` VARCHAR(64) NOT NULL DEFAULT '',
          `state` LONGTEXT NULL,
          `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          `finished_at` TIMESTAMP NULL DEFAULT NULL,
          PRIMARY KEY (`id`),
          KEY `ix_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      ]],
      [[
        CREATE TABLE IF NOT EXISTS `sovereign_instance_participants` (
          `instance_id` INT NOT NULL,
          `char_identifier` VARCHAR(64) NOT NULL,
          `role` VARCHAR(16) NOT NULL DEFAULT 'leader',
          `joined_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`instance_id`, `char_identifier`),
          KEY `ix_char` (`char_identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      ]],
    },
  },
  {
    version = 3,
    name = 'phase4_progression',
    queries = {
      [[
        CREATE TABLE IF NOT EXISTS `sovereign_story_progress` (
          `char_identifier` VARCHAR(64) NOT NULL,
          `mission_code` VARCHAR(64) NOT NULL,
          `completion_count` INT NOT NULL DEFAULT 0,
          `last_completed_at` TIMESTAMP NULL DEFAULT NULL,
          `vars` LONGTEXT NULL,
          PRIMARY KEY (`char_identifier`, `mission_code`),
          KEY `ix_mission` (`mission_code`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
      ]],
    },
  },
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

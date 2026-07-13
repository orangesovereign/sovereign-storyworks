-- Sovereign Storyworks — fxmanifest
-- Phase 1 (Mission Runtime Core) | Features: B1, B3, C2 (partial), L1, L2, L3

fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

author 'Sovereign County RP'
description 'Sovereign Storyworks — all-in-one mission, story, NPC, dialogue and cutscene builder + runtime for RedM / VORP Core'
version '0.1.0-phase1'

shared_scripts {
  'config/config.lua',
  'config/config_limits.lua',
  'config/config_runtime.lua',
  'locales/en.lua',
  'shared/locale.lua',
  'shared/log.lua',
}

client_scripts {
  'client/util/dataview.lua',
  'client/main.lua',
  'client/runtime.lua',
  'client/spikes.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/db/migrations.lua',
  'server/core/ratelimit.lua',
  'server/core/registry.lua',
  'server/core/missions.lua',
  'server/core/instance.lua',
  'server/tasks/goto.lua',
  'server/tasks/end.lua',
  'server/core/seed.lua',
  'server/commands.lua',
  'server/spikes.lua',
  'server/main.lua',
}

dependencies {
  'oxmysql',
  'vorp_core',
  'sovereign_notify', -- K4 renderer (ruling #9) — extracted as a county-wide standalone
}

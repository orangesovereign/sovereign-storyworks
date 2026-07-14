-- Sovereign Storyworks — fxmanifest
-- Phase 1 (Mission Runtime Core) | Features: B1, B3, C2 (partial), L1, L2, L3

fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

author 'Sovereign County RP'
description 'Sovereign Storyworks — all-in-one mission, story, NPC, dialogue and cutscene builder + runtime for RedM / VORP Core'
version '0.4.0-alpha'

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
  'client/prompts.lua',
  'client/carry.lua',
  'client/npcs.lua',
  'client/missionnpcs.lua',
  'client/builder.lua',
  'client/spikes.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/db/migrations.lua',
  'server/core/ratelimit.lua',
  'server/core/registry.lua',
  'server/core/missions.lua',
  'server/core/interactions.lua',
  'server/core/missionnpcs.lua',
  'server/core/vorp.lua',
  'server/core/gametime.lua',
  'server/core/progress.lua',
  'server/core/schemas.lua',
  'server/core/instance.lua',
  'server/tasks/goto.lua',
  'server/tasks/route.lua',
  'server/tasks/wait.lua',
  'server/tasks/search.lua',
  'server/tasks/holdaction.lua',
  'server/tasks/choice.lua',
  'server/tasks/collectdeliver.lua',
  'server/tasks/carry.lua',
  'server/tasks/cargo.lua',
  'server/tasks/talk.lua',
  'server/tasks/eliminate.lua',
  'server/tasks/escort.lua',
  'server/tasks/defend.lua',
  'server/tasks/setvar.lua',
  'server/tasks/condition.lua',
  'server/tasks/chance.lua',
  'server/tasks/require.lua',
  'server/tasks/reward.lua',
  'server/tasks/end.lua',
  'server/core/seed.lua',
  'server/builder.lua',
  'server/commands.lua',
  'server/spikes.lua',
  'server/main.lua',
}

ui_page 'ui/dist/index.html'

files {
  'ui/dist/index.html',
  'ui/dist/assets/*',
  'audio/*.ogg', -- creator-supplied voice files (E2)
}

dependencies {
  'oxmysql',
  'vorp_core',
  'vorp_inventory',   -- collect/deliver objectives (S1-verified exports)
  'sovereign_notify', -- K4 renderer (ruling #9) — extracted as a county-wide standalone
}

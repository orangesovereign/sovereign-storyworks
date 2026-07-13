-- Sovereign Storyworks — fxmanifest
-- Phase 0 (Foundations & Spikes) | Features: L1, L3 scaffolding

fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

author 'Sovereign County RP'
description 'Sovereign Storyworks — all-in-one mission, story, NPC, dialogue and cutscene builder + runtime for RedM / VORP Core'
version '0.0.1-phase0'

shared_scripts {
  'config/config.lua',
  'config/config_limits.lua',
  'locales/en.lua',
  'shared/locale.lua',
  'shared/log.lua',
}

client_scripts {
  'client/util/dataview.lua',
  'client/main.lua',
  'client/spikes.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/db/migrations.lua',
  'server/main.lua',
  'server/spikes.lua',
}

dependencies {
  'oxmysql',
  'vorp_core',
}

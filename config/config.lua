-- Sovereign Storyworks — core configuration
-- Phase 0 (Foundations & Spikes) | Features: L1

Config = {}

-- General ---------------------------------------------------------------

Config.Debug = true      -- verbose [sovereign_storyworks] debug prints (turn off for production)
Config.Locale = 'en'     -- must match a file in locales/

-- Database --------------------------------------------------------------

Config.AutoMigrate = true -- run pending schema migrations automatically at resource start

-- Permissions (ACE) -------------------------------------------------------
-- add_ace group.admin storyworks.admin allow
-- add_ace group.admin storyworks.builder allow

Config.Ace = {
  builder = 'storyworks.builder', -- may open the builder (from Phase 5)
  admin = 'storyworks.admin',     -- admin/test commands, incl. Phase 0 spikes
}

-- Phase 0 spike harness ---------------------------------------------------
-- Owner-run in-game verification tests (/swspike). Every value here can be
-- overridden per-run via command arguments; these are safe verified defaults
-- taken from femga/rdr3_discoveries reference data.

Config.Spikes = {
  enabled = true, -- flip false once Phase 0 exit gate passes

  pedModel = 'a_m_m_valtownfolk_01',  -- peds_list.lua:459
  propModel = 'p_crate01x',           -- propsets_list.lua (0x04AC59BC)

  -- S2 native ped speech (audio_banks README example values)
  speech = {
    soundRef = '0132_G_M_M_UNICRIMINALS_01_BLACK_01',
    soundName = 'GIDDY_UP_ESCALATED',
    params = 'speech_params_force',
    line = 0, -- 0 = random line
  },

  -- S3 outfit natives (ped_outfits.lua README example value)
  outfitHash = 0x74D74B1C, -- metaped outfit example from reference data

  -- S4 particle / screen effects (ptfx_assets_looped.lua / animpostfx.lua)
  ptfx = { dict = 'des_alchemist', name = 'ent_amb_alchemist_post_cloud_smk' },
  animpostfx = { name = 'PauseMenuIn', seconds = 5 },

  -- S5 soundsets (soundsets README example values)
  soundset = { ref = 'RNATV2_Sounds', name = 'Alarm' },

  -- S6 carriable route (AI/CARRYING_FLAGS)
  carryingFlags = {
    2,  -- CARRYING_FLAG_CAN_BE_CARRIED_ON_FOOT
    3,  -- CARRYING_FLAG_CAN_BE_CARRIED_ON_MOUNT
    4,  -- CARRYING_FLAG_CAN_BE_DROPPED
    14, -- CARRYING_FLAG_CAN_BE_PLACED_ON_MOUNT
    21, -- CARRYING_FLAG_IS_INSTANT_PICKUP
  },
}

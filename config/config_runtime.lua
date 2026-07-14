-- Sovereign Storyworks — mission runtime configuration
-- Phase 1 (Mission Runtime Core) | Features: B1, C2, L1

ConfigRuntime = {}

-- Server-side position poll for location-based tasks (milliseconds).
-- The server reads player positions itself — clients are never trusted (L2).
ConfigRuntime.PositionPollMs = 750

-- Default arrival radius (meters) for location tasks when the mission doesn't set one.
ConfigRuntime.DefaultGotoRadius = 3.0

-- Progress ping for location tasks: distance callout every N seconds (0 disables).
-- Navigation aid until map blips land in Phase 2 (K2). Owner-set to 2 (round 2).
ConfigRuntime.GotoProgressPingSeconds = 2

-- Delay before announcing the next objective after a task completes (ms), so the
-- completion tip and the new objective don't collide on the same channel.
ConfigRuntime.ObjectiveAnnounceDelayMs = 1500

-- One mission at a time in V1 (participants-list core still party-ready, ruling #3).
ConfigRuntime.MaxActiveInstancesPerCharacter = 1

-- Active instances untouched for this many hours are cancelled at resource boot
-- (stale-state hygiene; disconnected players inside the window resume normally).
ConfigRuntime.InstanceExpiryHours = 48

-- Objective map blip (K2). Style hash from the proven vorp pattern
-- (vorp_utils blips.lua / vorp_banking). 0 disables blips entirely.
ConfigRuntime.ObjectiveBlipStyle = 1664425300

-- Objective tracker HUD (K1). Server-set, identical for every player.
ConfigRuntime.Tracker = {
  -- bottom-left | bottom-right | top-left | top-right | mid-left | mid-right
  anchor = 'mid-left', -- owner round 1: clear of the minimap corner
  scale = 1.0,
}

-- Interaction prompts (hold-action, choices, deliveries). Key hashes from the
-- rdr3_discoveries Controls dump; every key is on-foot safe.
ConfigRuntime.Interact = {
  holdKey = 0x760A9C6F,    -- [G] INPUT_INTERACT_OPTION1
  choiceKeyA = 0x760A9C6F, -- [G] option one
  choiceKeyB = 0x2EAB0795, -- [E] INPUT_DYNAMIC_SCENARIO — option two
  defaultHoldMs = 1200,    -- how long a hold prompt must be held
  choiceHoldMs = 500,      -- short hold on choices so a stray tap can't decide
  positionSlack = 3.0,     -- extra meters allowed in the server-side position check
}

-- How often the server re-checks inventories for collect-type objectives (ms).
ConfigRuntime.InventoryPollMs = 2000

-- Scheduling & resets (D1). Real-world clock (server os.time), server-authoritative.
ConfigRuntime.Schedule = {
  resetHour = 6,   -- daily/weekly/monthly cycles roll over at this hour (0-23, server local time)
  weekStart = 1,   -- 1 = Sunday … 7 = Saturday (Lua os.date %w is 0=Sun; we map 1..7 = Sun..Sat)
}

-- Combat & mission NPCs (Phase 3). Natives verified in vorp_utils/rdr3_discoveries;
-- escort locomotion native flagged S7. V1 = solo instances, so mission NPCs are
-- client-local: the client detects death/arrival/separation and reports; the server
-- owns counts, timers, and the complete/fail decision (same trust posture as the
-- interaction layer, rate-limited). V2 party missions revisit with networked NPCs.
ConfigRuntime.Combat = {
  enemyRelGroup = 'SOVEREIGN_SW_ENEMY',       -- our mission-enemy relationship group
  defaultEnemyModel = 'a_m_m_unigunslinger_01',
  defaultEnemyWeapon = 'WEAPON_REVOLVER_CATTLEMAN',
  defaultEnemyHealth = 120,                    -- round 1: 200 was a bullet-sponge; ~normal-person now, tunable
  enemyAmmo = 250,
  escortWalkSpeed = 1.0,                       -- 1.0 walk, 2.0+ run
  -- named blip styles (rdr3_discoveries blip_styles) — client joaats these; far
  -- more reliable than raw hashes (round 1: the guessed ally hash didn't render)
  enemyBlipStyle = 'BLIP_STYLE_ENEMY',
  allyBlipStyle = 'BLIP_STYLE_FRIENDLY',
  deathReportGraceMs = 250,                    -- debounce so one death reports once
}

-- Dialogue (E1/E2). Lines without their own durationMs time themselves by
-- length (owner round 1: fixed 3.5s was unreadably fast on long lines).
ConfigRuntime.Dialogue = {
  baseLineMs = 1800,  -- reading runway before per-word time starts counting
  msPerWord = 420,    -- added per word
  minLineMs = 3500,   -- floor for even the shortest line
  maxLineMs = 12000,  -- ceiling so a typo'd essay can't stall the story
  lineGapMs = 350,    -- breath between lines
  voiceVolume = 0.8,  -- 0.0–1.0 for creator-supplied .ogg voice files
}

-- Physical carry & cargo (B5/B6) — attach route per TECH_SPEC S6 ruling.
ConfigRuntime.Carry = {
  -- animation set verified in rdr3_discoveries ingameanims (mech_carry_box)
  animDict = 'mech_carry_box',
  animIdle = 'idle',
  animPickup = 'pickup',
  animPutdown = 'putdown',

  -- SKEL_Spine3 bone index per player skeleton (boneNames dumps; bone_id 14413)
  attachBoneBySkeleton = { mp_male = 134, mp_female = 218 },
  attachOffset = { x = 0.0, y = 0.45, z = 0.0 }, -- carried in front of the chest

  -- controls blocked while carrying (Controls dump: INPUT_SPRINT, INPUT_JUMP)
  blockedControls = { 0x8FFC75D6, 0xD9D0E1C0 },

  -- wagon-bed attachment slots (offsets from the vehicle root), used in order
  wagonSlots = {
    { x = -0.35, y = -1.6, z = 0.55 },
    { x = 0.35, y = -1.6, z = 0.55 },
    { x = -0.35, y = -2.2, z = 0.55 },
    { x = 0.35, y = -2.2, z = 0.55 },
    { x = 0.0, y = -1.9, z = 1.05 },
  },
  wagonSearchRadius = 8.0, -- how far the wagon may stand from the load point
}

-- Phase 1 test fixture: load data/*.json mission definitions at boot as published
-- missions (validated first). The builder replaces this pipeline in Phase 5.
ConfigRuntime.SeedMissionsFromData = true
ConfigRuntime.SeedFiles = {
  'data/test_mission.json',
  'data/test_mission_fail.json',
  'data/phase2_errand.json',
  'data/phase2_freight.json',
  'data/phase2_delivery.json',
  'data/phase3_skirmish.json',
  'data/phase4_ch1.json',
  'data/phase4_ch2.json',
  'data/phase4_ch3.json',
  'data/phase4_daily.json',
  'data/phase4_vars.json',
  'data/phase4_luck.json',
  'data/phase4_gated.json',
}

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

-- Phase 1 test fixture: load data/*.json mission definitions at boot as published
-- missions (validated first). The builder replaces this pipeline in Phase 5.
ConfigRuntime.SeedMissionsFromData = true
ConfigRuntime.SeedFiles = {
  'data/test_mission.json',
  'data/test_mission_fail.json',
}

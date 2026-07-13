-- Sovereign Storyworks — English locale
-- Phase 0 (Foundations & Spikes) | Features: L3
-- Every player-facing string lives here. Access via T('key').

Locales = Locales or {}

Locales['en'] = {
  -- generic
  no_permission = 'You do not have permission to do that.',
  rate_limited = 'Slow down — try again in a moment.',

  -- Phase 0 spike harness
  spike_disabled = 'Spike commands are disabled in the config.',
  spike_unknown = 'Unknown spike. Valid: %s',
  spike_usage = 'Usage: /swspike <name> — runs a Phase 0 verification test. /swspike list for options.',
  spike_started = 'Spike "%s" started — watch the F8 console and the game world.',

  -- Phase 1 mission runtime
  swstart_usage = 'Usage: /swstart <mission code> — /swmissions lists what is published.',
  no_character = 'No character selected.',
  already_on_mission = 'You already have an active mission — /swcancel first.',
  unknown_mission = 'No published mission carries that code. /swmissions lists them.',
  no_active_mission = 'You have no active mission.',
  no_missions = 'No missions are published.',
  missions_header = '%d published mission(s):',
  mission_started_title = 'Mission started',
  mission_resumed_title = 'Mission resumed',
  mission_over_title = 'Mission complete',
  mission_completed = 'Mission complete.',
  mission_failed = 'Mission failed.',
  mission_cancelled = 'Mission cancelled.',
  mission_broken = 'This mission is broken — the county clerk has been notified.',
  goto_arrived = 'You have arrived.',
  goto_out_of_time = 'Too slow — the moment has passed.',
}

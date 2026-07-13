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
}

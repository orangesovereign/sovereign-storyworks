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
  mission_started_title = 'Mission Undertaken',
  mission_resumed_title = 'Mission Resumed',
  mission_over_title = 'Mission Complete',
  mission_failed_title = 'Mission Failed',
  mission_cancelled_title = 'Mission Cancelled',
  mission_completed = 'Mission complete.',
  mission_failed = 'Mission failed.',
  mission_cancelled = 'Mission cancelled.',
  mission_broken = 'This mission is broken — the county clerk has been notified.',
  goto_arrived = 'You have arrived.',
  goto_out_of_time = 'Too slow — the moment has passed.',
  goto_progress_reach = 'Objective: %d meters away.',
  goto_progress_depart = 'Distance covered: %d of %d meters.',
  route_checkpoint = 'Checkpoint %d of %d.',
  route_done = 'Route complete.',
  wait_remaining = '%d seconds remain.',
  search_started = 'You begin searching the area...',
  search_progress = 'Searching: %d of %d seconds.',
  search_paused = 'You have left the search area — the trail goes cold until you return.',
  search_done = 'Your search turns something up.',
  holdaction_done = 'Done.',
  deliver_prompt = 'Deliver %d x %s',
  deliver_done = 'Delivered.',
  deliver_missing = 'You are short %d — gather the rest and return.',
  collect_done = 'You have gathered everything needed.',
  carry_pickup_prompt = 'Pick up',
  carry_setdown_prompt = 'Set down',
  carry_picked_up = 'Picked up — mind your step.',
  carry_delivered = 'Set down where it belongs.',
  cargo_take_prompt = 'Pick up a crate',
  cargo_load_prompt = 'Load onto the wagon',
  cargo_unload_prompt = 'Take down a crate',
  cargo_progress_load = 'Loaded %d of %d.',
  cargo_progress_unload = 'Unloaded %d of %d.',
  cargo_done = 'The cargo is where it needs to be.',
}

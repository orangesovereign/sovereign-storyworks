-- Sovereign Storyworks — K4 notification presentation
-- Phase 2 | Features: K4, L1 (ruling #9: server owner/dev sets this; identical
-- for every player — there are no per-player toggles by design)

ConfigNotifications = {
  -- where the objective slips + progress ticks stack:
  -- 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left'
  anchor = 'top-right',

  -- overall size multiplier for all K4 elements
  scale = 1.0,

  -- how long things stay on screen (milliseconds)
  durations = {
    objective = 7000,   -- parchment objective slips
    tick = 2600,        -- progress ticks (distance callouts etc.)
    cardStarted = 3800, -- mission-started card
    cardEnd = 5000,     -- mission complete/failed/cancelled cards
  },

  -- how many objective slips may stack before the oldest drops
  maxSlips = 3,
}

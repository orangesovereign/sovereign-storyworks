-- Sovereign Storyworks — safety limits & rate limiting
-- Phase 0 (Foundations & Spikes) | Features: L1, L2
-- Every server-side callback/command consults this file. No limit lives in code.

ConfigLimits = {}

ConfigLimits.RateLimits = {
  -- window is seconds; max is allowed calls per window per player
  spikeCommand = { max = 12, window = 60 },   -- Phase 0 /swspike (disabled post-gate)
  runtimeCommand = { max = 20, window = 60 }, -- Phase 1 /swstart /swcancel /swmissions
  interactionDone = { max = 30, window = 60 }, -- Phase 2 prompt completions from clients
  npcReport = { max = 120, window = 60 },      -- Phase 3 combat NPC death/arrival/separation reports
  gameHour = { max = 10, window = 60 },        -- Phase 4 game-clock heartbeat
}

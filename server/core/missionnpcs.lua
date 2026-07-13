-- Sovereign Storyworks — mission-NPC lifecycle manager (server)
-- Phase 3 | Features: B2 combat tasks (eliminate/escort/defend), L2
-- The single most bug-prone area, isolated on purpose. Combat/mission NPCs in
-- solo V1 are CLIENT-LOCAL: the client spawns them, detects death/arrival/
-- separation, and reports; the server owns the authoritative counts, timers,
-- and the complete/fail decision. Reports are validated (batch belongs to a
-- participant's active instance) and rate-limited — same posture as the
-- interaction layer. GUARANTEED cleanup is the whole point: every batch this
-- manager spawns is wiped on task stop, mission finish/cancel, disconnect, and
-- resource stop, so no combat NPC is ever orphaned.

SWMissionNpcs = {}

local nextBatchId = 1
local batches = {} -- batchId -> { inst, count, dead = {set}, deadCount, alive, events, arrived, separated }

-- events (all optional): onKilled(deadCount, alive), onAllDead(), onArrived(), onSeparated()

---Spawn a batch of mission NPCs for every participant of an instance.
---spec (server→client): {
---  kind = 'enemy' | 'target' | 'ally',
---  model, peds = { {x,y,z,heading?}, ... },   -- explicit positions, one per ped
---  weapon, health, ammo,                        -- enemy/ally combat kit
---  hostile,                                     -- enemy: attack the player
---  flees,                                       -- target: run when shot (hunting)
---  moveTo = {x,y,z}, walkSpeed, arriveRadius,   -- ally: escort destination
---  maxSeparation,                               -- ally: fail distance from player
---  invincible,                                  -- ally: protected escort
---  blipStyle, blipName,
---}
function SWMissionNpcs.Spawn(inst, spec, events)
  local batchId = nextBatchId
  nextBatchId = nextBatchId + 1

  batches[batchId] = {
    inst = inst,
    count = #spec.peds,
    dead = {},
    deadCount = 0,
    alive = #spec.peds,
    events = events or {},
    arrived = false,
    separated = false,
  }
  inst.npcBatches = inst.npcBatches or {}
  inst.npcBatches[batchId] = true

  local payload = {
    action = 'spawn',
    batchId = batchId,
    kind = spec.kind,
    model = spec.model,
    peds = spec.peds,
    weapon = spec.weapon,
    health = spec.health,
    ammo = spec.ammo,
    hostile = spec.hostile,
    flees = spec.flees,
    moveTo = spec.moveTo,
    walkSpeed = spec.walkSpeed,
    arriveRadius = spec.arriveRadius,
    maxSeparation = spec.maxSeparation,
    invincible = spec.invincible,
    blipStyle = spec.blipStyle,
    blipName = spec.blipName,
  }
  for _, p in pairs(inst.participants) do
    if p.source then TriggerClientEvent('sovereign_storyworks:client:missionnpc', p.source, payload) end
  end

  SWLog.Info('npc batch #%d spawned (%s x%d) for instance %d', batchId, spec.kind, #spec.peds, inst.id)
  return batchId
end

local function despawnBatch(inst, batchId)
  for _, p in pairs(inst.participants) do
    if p.source then
      TriggerClientEvent('sovereign_storyworks:client:missionnpc', p.source, { action = 'despawn', batchId = batchId })
    end
  end
  batches[batchId] = nil
  if inst.npcBatches then inst.npcBatches[batchId] = nil end
end

---Despawn one batch.
function SWMissionNpcs.Despawn(inst, batchId)
  if batchId and batches[batchId] and batches[batchId].inst == inst then
    despawnBatch(inst, batchId)
  end
end

---Wipe EVERY batch this instance owns (task stop / finish / cancel / disconnect).
function SWMissionNpcs.Clear(inst)
  if not inst.npcBatches then return end
  for batchId in pairs(inst.npcBatches) do
    batches[batchId] = nil
  end
  inst.npcBatches = {}
  for _, p in pairs(inst.participants) do
    if p.source then
      TriggerClientEvent('sovereign_storyworks:client:missionnpc', p.source, { action = 'clearAll' })
    end
  end
end

---Live count for a batch (for tasks polling progress).
function SWMissionNpcs.Alive(batchId)
  local b = batches[batchId]
  return b and b.alive or 0
end

local function batchForSource(source, batchId)
  local b = batches[batchId]
  if not b then return nil end
  -- the reporter must be a participant of the batch's instance
  for _, p in pairs(b.inst.participants) do
    if p.source == source then return b end
  end
  return nil
end

RegisterNetEvent('sovereign_storyworks:server:npcKilled', function(batchId, index)
  local source = source
  if SWRateLimit.IsLimited(source, 'npcReport') then return end
  local b = batchForSource(source, batchId)
  if not b or type(index) ~= 'number' then return end
  if b.dead[index] then return end -- each ped dies once
  if index < 1 or index > b.count then return end

  b.dead[index] = true
  b.deadCount = b.deadCount + 1
  b.alive = math.max(0, b.count - b.deadCount)

  if b.events.onKilled then b.events.onKilled(b.deadCount, b.alive) end
  if b.alive == 0 and b.events.onAllDead then b.events.onAllDead() end
end)

RegisterNetEvent('sovereign_storyworks:server:npcArrived', function(batchId)
  local source = source
  if SWRateLimit.IsLimited(source, 'npcReport') then return end
  local b = batchForSource(source, batchId)
  if not b or b.arrived then return end
  b.arrived = true
  if b.events.onArrived then b.events.onArrived() end
end)

RegisterNetEvent('sovereign_storyworks:server:npcSeparated', function(batchId)
  local source = source
  if SWRateLimit.IsLimited(source, 'npcReport') then return end
  local b = batchForSource(source, batchId)
  if not b or b.separated then return end
  b.separated = true
  if b.events.onSeparated then b.events.onSeparated() end
end)

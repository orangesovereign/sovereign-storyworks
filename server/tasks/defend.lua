-- Sovereign Storyworks — task module: defend an area
-- Phase 3 | Features: B2 (defend), B3 (leaving/dying is the failure edge)
-- Hold a position for a duration while waves of attackers spawn. Complete when
-- the timer runs out; FAIL if you leave the defense boundary. Attackers are
-- ordinary eliminate-style enemies from the lifecycle manager, spawned wave by
-- wave; leftover enemies are wiped by the manager when the task ends.
--
-- config:
--   center             {x,y,z} the point to hold (required)
--   durationSeconds    how long to survive (default 60)
--   boundary           leave-this-radius-and-fail, meters (default 40; 0 = no bound)
--   waves              number of attacker waves (default 3)
--   perWave            attackers per wave (default 3)
--   spread             attacker spawn scatter (default 25)
--   model, weapon, health   attacker kit (defaults from config)

local function scatter(center, spread, n)
  local pts = {}
  for i = 1, n do
    local ang = math.random() * math.pi * 2
    local dist = spread * (0.6 + math.random() * 0.4)
    pts[i] = { x = center.x + math.cos(ang) * dist, y = center.y + math.sin(ang) * dist, z = center.z }
  end
  return pts
end

SWTasks.Register('defend', {
  label = 'Defend an area',

  validate = function(config)
    if not SWValidPoint(config.center or {}) then return false, 'defend needs center x/y/z' end
    if config.durationSeconds ~= nil and (type(config.durationSeconds) ~= 'number' or config.durationSeconds <= 0) then
      return false, 'durationSeconds must be > 0'
    end
    return true
  end,

  start = function(ctx)
    local cfg = ctx.config
    local center = { x = cfg.center.x + 0.0, y = cfg.center.y + 0.0, z = cfg.center.z + 0.0 }
    ctx.center = center
    ctx.boundary = cfg.boundary ~= nil and cfg.boundary or 40.0
    ctx.duration = cfg.durationSeconds or 60
    ctx.endAt = os.time() + ctx.duration
    ctx.waves = cfg.waves or 3
    ctx.perWave = cfg.perWave or 3
    ctx.spread = cfg.spread or 25.0
    ctx.model = cfg.model or ConfigRuntime.Combat.defaultEnemyModel
    ctx.weapon = cfg.weapon or ConfigRuntime.Combat.defaultEnemyWeapon
    ctx.health = cfg.health or ConfigRuntime.Combat.defaultEnemyHealth
    ctx.batches = {}
    ctx.wavesSent = 0
    ctx.nextWaveAt = 0 -- first wave immediately
    ctx.nextPing = 0
    ctx.target = center
    ctx.UpdateTarget(center)
    ctx.Notify('tip', T('defend_started', ctx.duration))
  end,

  tick = function(ctx)
    local now = os.time()
    local remaining = ctx.endAt - now

    if remaining <= 0 then
      ctx.Notify('tip', T('defend_done'))
      return ctx.Complete(true)
    end

    -- leaving the boundary fails
    if ctx.boundary and ctx.boundary > 0 then
      local left = false
      ctx.ForEachParticipant(function(src)
        if left then return end
        local ped = GetPlayerPed(src)
        if not ped or ped == 0 then return end
        local c = GetEntityCoords(ped)
        local dx, dy = c.x - ctx.center.x, c.y - ctx.center.y
        if (dx * dx + dy * dy) > (ctx.boundary * ctx.boundary) then left = true end
      end)
      if left then
        ctx.Notify('tip', T('defend_abandoned'))
        return ctx.Complete(false)
      end
    end

    -- release waves across the duration
    if ctx.wavesSent < ctx.waves and GetGameTimer() >= ctx.nextWaveAt then
      ctx.wavesSent = ctx.wavesSent + 1
      local interval = math.floor((ctx.duration * 1000) / ctx.waves)
      ctx.nextWaveAt = GetGameTimer() + interval
      local batchId = ctx.SpawnNpcs({
        kind = 'enemy',
        model = ctx.model,
        peds = scatter(ctx.center, ctx.spread, ctx.perWave),
        weapon = ctx.weapon,
        health = ctx.health,
        ammo = ConfigRuntime.Combat.enemyAmmo,
        hostile = true,
        blipStyle = ConfigRuntime.Combat.enemyBlipStyle,
        blipName = T('defend_blip_foe'),
      })
      ctx.batches[#ctx.batches + 1] = batchId
      ctx.Notify('tip', T('defend_wave', ctx.wavesSent, ctx.waves))
    end

    -- countdown ping
    local pingEvery = ConfigRuntime.GotoProgressPingSeconds or 0
    if pingEvery > 0 and now >= ctx.nextPing then
      ctx.nextPing = now + pingEvery
      ctx.Notify('tip', T('defend_remaining', remaining))
    end
  end,

  stop = function(ctx)
    ctx.target = nil
    -- the manager wipes every wave batch on task stop
  end,
})

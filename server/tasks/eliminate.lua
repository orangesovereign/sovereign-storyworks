-- Sovereign Storyworks — task module: eliminate targets
-- Phase 3 | Features: B2 (eliminate), B3 (time-limit failure edge)
-- Spawn N peds and clear them out. Aggressive attackers (hostile) OR
-- non-aggressive hunting quarry (flees). The lifecycle manager owns the peds
-- and reports kills; this task counts and completes.
--
-- config:
--   model              ped model (default ConfigRuntime.Combat.defaultEnemyModel)
--   count              how many (default 3)
--   center             {x,y,z} spawn/objective center (required)
--   spread             spawn scatter radius in meters (default 12)
--   hunting            true → non-aggressive quarry that flees; false → armed attackers
--   weapon             enemy weapon (default config); ignored when hunting
--   health             per-ped health (default config)
--   timeLimitSeconds   optional; expiring routes the FAILURE edge (B3)

local function scatter(center, spread, n)
  local pts = {}
  for i = 1, n do
    local ang = (math.pi * 2) * (i / n) + math.random() * 0.8
    local dist = spread * (0.35 + math.random() * 0.65)
    pts[i] = { x = center.x + math.cos(ang) * dist, y = center.y + math.sin(ang) * dist, z = center.z }
  end
  return pts
end

SWTasks.Register('eliminate', {
  label = 'Eliminate targets',

  validate = function(config)
    if not SWValidPoint(config.center or {}) and not SWValidPoint({ x = config.x, y = config.y, z = config.z }) then
      return false, 'eliminate needs center x/y/z (or originOffset)'
    end
    if config.count ~= nil and (type(config.count) ~= 'number' or config.count < 1) then
      return false, 'count must be >= 1'
    end
    if config.timeLimitSeconds ~= nil and type(config.timeLimitSeconds) ~= 'number' then
      return false, 'timeLimitSeconds must be a number'
    end
    return true
  end,

  start = function(ctx)
    local cfg = ctx.config
    local center = cfg.center or { x = cfg.x, y = cfg.y, z = cfg.z }
    center = { x = center.x + 0.0, y = center.y + 0.0, z = center.z + 0.0 }
    local count = cfg.count or 3
    ctx.total = count
    ctx.deadline = cfg.timeLimitSeconds and cfg.timeLimitSeconds > 0 and (os.time() + cfg.timeLimitSeconds) or nil
    ctx.target = center
    ctx.UpdateTarget(center)

    ctx.batchId = ctx.SpawnNpcs({
      kind = cfg.hunting and 'target' or 'enemy',
      model = cfg.model or (cfg.hunting and 'a_c_deer_01' or ConfigRuntime.Combat.defaultEnemyModel),
      peds = scatter(center, cfg.spread or 12.0, count),
      weapon = cfg.hunting and nil or (cfg.weapon or ConfigRuntime.Combat.defaultEnemyWeapon),
      health = cfg.health or ConfigRuntime.Combat.defaultEnemyHealth,
      ammo = ConfigRuntime.Combat.enemyAmmo,
      hostile = not cfg.hunting,
      flees = cfg.hunting or false,
      blipStyle = ConfigRuntime.Combat.enemyBlipStyle,
      blipName = cfg.hunting and T('eliminate_blip_hunt') or T('eliminate_blip_foe'),
    }, {
      onKilled = function(dead, alive)
        if alive > 0 then ctx.Notify('tip', T('eliminate_progress', dead, ctx.total)) end
      end,
      onAllDead = function()
        ctx.Notify('tip', T('eliminate_done'))
        ctx.Complete(true)
      end,
    })

    ctx.Notify('tip', T('eliminate_progress', 0, count))
  end,

  tick = function(ctx)
    if ctx.deadline and os.time() > ctx.deadline then
      ctx.Notify('tip', T('goto_out_of_time'))
      ctx.Complete(false)
    end
  end,

  stop = function(ctx)
    ctx.target = nil
    -- the manager wipes the batch on task stop; nothing to do here
  end,
})

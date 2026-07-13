-- Sovereign Storyworks — task module: escort an NPC
-- Phase 3 | Features: B2 (escort), B3 (death/separation are failure edges)
-- An NPC travels from a start point to a destination; you keep it alive and
-- close. Complete on arrival; FAIL if it dies (mortal) or you stray too far.
-- Protected escorts are invincible (can't die, only arrival/separation matter).
-- Escort LOCOMOTION is spike S7 (arrival detection depends on it).
--
-- config:
--   model              escort ped model (default a townsfolk)
--   start              {x,y,z,heading?} spawn point (required)
--   destination        {x,y,z} where it must reach (required)
--   walkSpeed          1.0 walk / 2.0+ run (default config)
--   arriveRadius       arrival distance (default 5)
--   maxSeparation      fail if player strays beyond this (default 60; 0 = no limit)
--   protected          true → invincible escort (default false = mortal)
--   timeLimitSeconds   optional; expiring routes the FAILURE edge (B3)

SWTasks.Register('escort', {
  label = 'Escort',

  validate = function(config)
    if not SWValidPoint(config.start or {}) then return false, 'escort needs start x/y/z' end
    if not SWValidPoint(config.destination or {}) then return false, 'escort needs destination x/y/z' end
    if config.timeLimitSeconds ~= nil and type(config.timeLimitSeconds) ~= 'number' then
      return false, 'timeLimitSeconds must be a number'
    end
    return true
  end,

  start = function(ctx)
    local cfg = ctx.config
    local start = { x = cfg.start.x + 0.0, y = cfg.start.y + 0.0, z = cfg.start.z + 0.0, heading = cfg.start.heading }
    local dest = { x = cfg.destination.x + 0.0, y = cfg.destination.y + 0.0, z = cfg.destination.z + 0.0 }
    ctx.deadline = cfg.timeLimitSeconds and (os.time() + cfg.timeLimitSeconds) or nil
    ctx.target = dest
    ctx.UpdateTarget(dest)

    local maxSep = cfg.maxSeparation
    if maxSep == nil then maxSep = 60.0 end

    ctx.batchId = ctx.SpawnNpcs({
      kind = 'ally',
      model = cfg.model or 'a_m_m_valtownfolk_01',
      peds = { { x = start.x, y = start.y, z = start.z, heading = start.heading or 0.0 } },
      moveTo = dest,
      walkSpeed = cfg.walkSpeed or ConfigRuntime.Combat.escortWalkSpeed,
      arriveRadius = cfg.arriveRadius or 5.0,
      maxSeparation = (maxSep and maxSep > 0) and maxSep or nil,
      invincible = cfg.protected or false,
      blipStyle = ConfigRuntime.Combat.allyBlipStyle,
      blipName = T('escort_blip'),
    }, {
      onArrived = function()
        ctx.Notify('tip', T('escort_arrived'))
        ctx.Complete(true)
      end,
      onAllDead = function()
        if not cfg.protected then
          ctx.Notify('tip', T('escort_died'))
          ctx.Complete(false)
        end
      end,
      onSeparated = function()
        ctx.Notify('tip', T('escort_separated'))
        ctx.Complete(false)
      end,
    })

    ctx.Notify('tip', T('escort_started'))
  end,

  tick = function(ctx)
    if ctx.deadline and os.time() > ctx.deadline then
      ctx.Notify('tip', T('goto_out_of_time'))
      ctx.Complete(false)
    end
  end,

  stop = function(ctx)
    ctx.target = nil
  end,
})

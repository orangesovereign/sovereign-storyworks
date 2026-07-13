-- Sovereign Storyworks — task module: player choice
-- Phase 2 | Features: B2 (player choice), B3 (the two paths ARE the edges)
-- Two prompts, two roads: option A rides the SUCCESS edge, option B rides the
-- FAILURE edge (the builder will label them "path A / path B" — they are not
-- value judgments). An objective slip carries the question.
--
-- config:
--   question   the situation text (required)
--   optionA    label for path A → onSuccess (required)
--   optionB    label for path B → onFailure (required)
--   x, y, z    optional: tie the choice to a place
--   radius     prompt radius when placed (default 3.0)

SWTasks.Register('choice', {
  label = 'Make a choice',

  validate = function(config)
    if type(config.question) ~= 'string' or config.question == '' then
      return false, 'choice needs question'
    end
    if type(config.optionA) ~= 'string' or config.optionA == '' then
      return false, 'choice needs optionA'
    end
    if type(config.optionB) ~= 'string' or config.optionB == '' then
      return false, 'choice needs optionB'
    end
    return true
  end,

  start = function(ctx)
    if ctx.config.x then
      ctx.target = { x = ctx.config.x + 0.0, y = ctx.config.y + 0.0, z = ctx.config.z + 0.0 }
    end

    ctx.ArmInteraction({
      mode = 'choice',
      question = ctx.config.question,
      optionA = ctx.config.optionA,
      optionB = ctx.config.optionB,
      target = ctx.target,
      radius = ctx.config.radius or 3.0,
    }, function(_, choiceIndex)
      ctx.Notify('tip', choiceIndex == 1 and ctx.config.optionA or ctx.config.optionB)
      -- path A = success edge, path B = failure edge (B3 wiring)
      ctx.Complete(choiceIndex == 1)
    end)
  end,

  stop = function(ctx)
    ctx.ClearInteraction()
    ctx.target = nil
  end,
})

-- Sovereign Storyworks — task/node schema catalog
-- Phase 5 (Builder NUI I) | Features: A1, B1 (schema-driven forms)
-- The single description of every node type's editable config. The builder NUI
-- fetches this and renders property forms generically — no per-task UI code.
-- Keeping it beside the task modules is the payoff of B1's declared-schema design.
--
-- field widgets:
--   text | textarea | number | bool | select | coords | coordsList | items | voice
-- field extras: default, help, min, max, options (select), showIf {field,equals},
--   clears {other config paths to wipe when this field changes}
-- Dot-path keys write nested config (e.g. 'departure.distance', 'pickup.x').
-- A 'coords' widget owns a key prefix and writes <key>.x/.y/.z (+ heading).

SWSchemas = {}

SWSchemas.categories = { 'Movement', 'Interaction', 'Combat', 'Story Logic', 'Flow' }

SWSchemas.nodes = {
  ----------------------------------------------------------------- Movement ---
  {
    type = 'goto', label = 'Go to a location', category = 'Movement',
    summary = 'The player travels somewhere — a fixed point, back to the start, or simply a distance away.',
    fields = {
      { key = 'kind', label = 'Destination', widget = 'select', default = 'point',
        options = { { value = 'point', label = 'A fixed point (capture it)' }, { value = 'away', label = 'Get a distance away (any direction)' } },
        clears = { 'x', 'y', 'z', 'departure.distance' } },
      { key = '@root', label = 'The point', widget = 'coords', showIf = { field = 'kind', equals = 'point' } },
      { key = 'departure.distance', label = 'Distance away (m)', widget = 'number', default = 40, min = 5, showIf = { field = 'kind', equals = 'away' } },
      { key = 'radius', label = 'Arrival radius (m)', widget = 'number', default = 3, min = 1 },
      { key = 'timeLimitSeconds', label = 'Time limit (s, 0 = none)', widget = 'number', default = 0, min = 0 },
    },
  },
  {
    type = 'route', label = 'Ride a route', category = 'Movement',
    summary = 'An ordered set of checkpoints the player reaches in turn.',
    fields = {
      { key = 'checkpoints', label = 'Checkpoints (in order)', widget = 'coordsList', min = 2 },
      { key = 'radius', label = 'Checkpoint radius (m)', widget = 'number', default = 3, min = 1 },
      { key = 'timeLimitSeconds', label = 'Time limit (s, 0 = none)', widget = 'number', default = 0, min = 0 },
    },
  },
  {
    type = 'search', label = 'Search an area', category = 'Movement',
    summary = 'The player stands within an area while a search timer fills.',
    fields = {
      { key = '@root', label = 'Area centre', widget = 'coords' },
      { key = 'radius', label = 'Area radius (m)', widget = 'number', default = 10, min = 2 },
      { key = 'searchSeconds', label = 'Seconds of searching', widget = 'number', default = 8, min = 1 },
      { key = 'timeLimitSeconds', label = 'Time limit (s, 0 = none)', widget = 'number', default = 0, min = 0 },
    },
  },
  --------------------------------------------------------------- Interaction ---
  {
    type = 'talk', label = 'Speak with an NPC', category = 'Interaction',
    summary = 'A branching conversation with a spawned character, with optional voice.',
    fields = {
      { key = 'npc', label = 'Where the NPC stands', widget = 'coords' },
      { key = 'npc.model', label = 'NPC model', widget = 'text', default = 'a_m_m_valtownfolk_01', help = 'Ped model name (the NPC Maker & catalog will pick this in Phase 6).' },
      { key = 'lines', label = 'Dialogue lines', widget = 'lines' },
      { key = 'choice', label = 'End with a player choice', widget = 'choice' },
    },
  },
  {
    type = 'holdaction', label = 'Perform an action', category = 'Interaction',
    summary = 'Go to a spot and hold a button to do something (repair, light, pry…).',
    fields = {
      { key = '@root', label = 'Where', widget = 'coords' },
      { key = 'promptLabel', label = 'Prompt text', widget = 'text', default = 'Do it' },
      { key = 'holdMs', label = 'Hold time (ms)', widget = 'number', default = 1200, min = 200 },
      { key = 'timeLimitSeconds', label = 'Time limit (s, 0 = none)', widget = 'number', default = 0, min = 0 },
    },
  },
  {
    type = 'choice', label = 'Player choice', category = 'Interaction',
    summary = 'Two roads: option A takes the success path, option B the failure path.',
    fields = {
      { key = 'question', label = 'The question', widget = 'text' },
      { key = 'optionA', label = 'Option A (→ success path)', widget = 'text' },
      { key = 'optionB', label = 'Option B (→ failure path)', widget = 'text' },
      { key = '@root', label = 'Tie to a place (optional)', widget = 'coords', optional = true },
    },
  },
  {
    type = 'collectdeliver', label = 'Collect / deliver items', category = 'Interaction',
    summary = 'Gather inventory items, or hand them in at a drop-off.',
    fields = {
      { key = 'mode', label = 'Mode', widget = 'select', default = 'collect',
        options = { { value = 'collect', label = 'Collect (gather into inventory)' }, { value = 'deliver', label = 'Deliver (hand in at a point)' } } },
      { key = 'item', label = 'Item name', widget = 'text' },
      { key = 'count', label = 'How many', widget = 'number', default = 1, min = 1 },
      { key = '@root', label = 'Drop-off point', widget = 'coords', showIf = { field = 'mode', equals = 'deliver' } },
      { key = 'timeLimitSeconds', label = 'Time limit (s, 0 = none)', widget = 'number', default = 0, min = 0 },
    },
  },
  {
    type = 'carry', label = 'Physical carry', category = 'Interaction',
    summary = 'Pick up a prop, carry it, and set it down at a target.',
    fields = {
      { key = 'model', label = 'Prop model', widget = 'text', default = 'p_crate01x' },
      { key = 'pickup', label = 'Pick-up point', widget = 'coords' },
      { key = 'dropoff', label = 'Set-down point', widget = 'coords' },
      { key = 'timeLimitSeconds', label = 'Time limit (s, 0 = none)', widget = 'number', default = 0, min = 0 },
    },
  },
  {
    type = 'cargo', label = 'Load / unload cargo', category = 'Interaction',
    summary = 'Move crates between a stack and a wagon, one at a time.',
    fields = {
      { key = 'mode', label = 'Mode', widget = 'select', default = 'load',
        options = { { value = 'load', label = 'Load (stack → wagon)' }, { value = 'unload', label = 'Unload (wagon → stack)' } } },
      { key = 'model', label = 'Crate model', widget = 'text', default = 'p_crate01x' },
      { key = 'count', label = 'How many crates', widget = 'number', default = 3, min = 1 },
      { key = 'takePoint', label = 'Take from', widget = 'coords' },
      { key = 'putPoint', label = 'Put to', widget = 'coords' },
      { key = 'timeLimitSeconds', label = 'Time limit (s, 0 = none)', widget = 'number', default = 0, min = 0 },
    },
  },
  {
    type = 'wait', label = 'Wait', category = 'Interaction',
    summary = 'Hold the story for a set time, with an optional countdown.',
    fields = {
      { key = 'seconds', label = 'Seconds to wait', widget = 'number', default = 10, min = 1 },
      { key = 'showCountdown', label = 'Show a countdown', widget = 'bool', default = true },
    },
  },
  -------------------------------------------------------------------- Combat ---
  {
    type = 'eliminate', label = 'Eliminate targets', category = 'Combat',
    summary = 'Spawn attackers to fight, or quarry to hunt, and clear them out.',
    fields = {
      { key = 'center', label = 'Where they spawn', widget = 'coords' },
      { key = 'count', label = 'How many', widget = 'number', default = 3, min = 1 },
      { key = 'spread', label = 'Spawn spread (m)', widget = 'number', default = 12, min = 2 },
      { key = 'hunting', label = 'Non-aggressive quarry (hunting)', widget = 'bool', default = false },
      { key = 'model', label = 'Model (blank = default)', widget = 'text', optional = true },
      { key = 'health', label = 'Health each', widget = 'number', default = 120, min = 20 },
      { key = 'timeLimitSeconds', label = 'Time limit (s, 0 = none)', widget = 'number', default = 0, min = 0 },
    },
  },
  {
    type = 'escort', label = 'Escort an NPC', category = 'Combat',
    summary = 'An NPC travels to safety; keep them alive and close.',
    fields = {
      { key = 'start', label = 'NPC start', widget = 'coords' },
      { key = 'destination', label = 'Destination', widget = 'coords' },
      { key = 'model', label = 'NPC model', widget = 'text', default = 'a_m_m_valtownfolk_01' },
      { key = 'protected', label = 'Invincible (protected)', widget = 'bool', default = false },
      { key = 'maxSeparation', label = 'Fail if further than (m, 0 = none)', widget = 'number', default = 60, min = 0 },
      { key = 'timeLimitSeconds', label = 'Time limit (s, 0 = none)', widget = 'number', default = 0, min = 0 },
    },
  },
  {
    type = 'defend', label = 'Defend an area', category = 'Combat',
    summary = 'Hold a position for a duration against waves of attackers.',
    fields = {
      { key = 'center', label = 'The ground to hold', widget = 'coords' },
      { key = 'durationSeconds', label = 'Hold for (s)', widget = 'number', default = 60, min = 10 },
      { key = 'boundary', label = 'Leave-and-fail radius (m, 0 = none)', widget = 'number', default = 40, min = 0 },
      { key = 'waves', label = 'Attacker waves', widget = 'number', default = 3, min = 1 },
      { key = 'perWave', label = 'Attackers per wave', widget = 'number', default = 3, min = 1 },
    },
  },
  --------------------------------------------------------------- Story Logic ---
  {
    type = 'setvar', label = 'Remember a value', category = 'Story Logic',
    summary = 'Set, add to, or toggle a story variable that the mission remembers.',
    fields = {
      { key = 'name', label = 'Variable name', widget = 'text' },
      { key = 'op', label = 'Operation', widget = 'select', default = 'set',
        options = { { value = 'set', label = 'Set to' }, { value = 'add', label = 'Add' }, { value = 'sub', label = 'Subtract' }, { value = 'toggle', label = 'Toggle yes/no' }, { value = 'append', label = 'Append text' } } },
      { key = 'value', label = 'Value', widget = 'text', showIf = { field = 'op', notEquals = 'toggle' } },
    },
  },
  {
    type = 'condition', label = 'Check a condition', category = 'Story Logic',
    summary = 'Branch on a value: success path if true, failure path if false.',
    fields = {
      { key = 'source', label = 'Check', widget = 'select', default = 'var',
        options = { { value = 'var', label = 'A story variable' }, { value = 'job', label = 'Job' }, { value = 'grade', label = 'Job grade' }, { value = 'money', label = 'Money' }, { value = 'gold', label = 'Gold' }, { value = 'xp', label = 'XP' }, { value = 'timeofday', label = 'Time of day (hour)' } } },
      { key = 'name', label = 'Variable name', widget = 'text', showIf = { field = 'source', equals = 'var' } },
      { key = 'op', label = 'Comparison', widget = 'select', default = 'eq',
        options = { { value = 'eq', label = '= equals' }, { value = 'ne', label = '≠ not equals' }, { value = 'gte', label = '≥ at least' }, { value = 'lte', label = '≤ at most' }, { value = 'gt', label = '> more than' }, { value = 'lt', label = '< less than' }, { value = 'contains', label = 'contains' }, { value = 'exists', label = 'exists' } },
        showIf = { field = 'source', notEquals = 'timeofday' } },
      { key = 'value', label = 'Value / from-hour', widget = 'text' },
      { key = 'value2', label = 'To-hour (time windows)', widget = 'number', optional = true, showIf = { field = 'source', equals = 'timeofday' } },
    },
  },
  {
    type = 'chance', label = 'Roll the dice', category = 'Story Logic',
    summary = 'A server-rolled chance: success path on a win, failure path otherwise.',
    fields = {
      { key = 'percent', label = 'Chance of success (%)', widget = 'number', default = 50, min = 0, max = 100 },
    },
  },
  {
    type = 'require', label = 'Require something', category = 'Story Logic',
    summary = 'Gate on a resource: success path if met (optionally consumed), failure path if not.',
    fields = {
      { key = 'kind', label = 'Require', widget = 'select', default = 'item',
        options = { { value = 'item', label = 'An item' }, { value = 'money', label = 'Money' }, { value = 'gold', label = 'Gold' }, { value = 'xp', label = 'XP' }, { value = 'job', label = 'A job' }, { value = 'grade', label = 'A job grade' } } },
      { key = 'item', label = 'Item name', widget = 'text', showIf = { field = 'kind', equals = 'item' } },
      { key = 'job', label = 'Job name', widget = 'text', showIf = { field = 'kind', equals = 'job' } },
      { key = 'amount', label = 'Amount / threshold', widget = 'number', default = 1, min = 0 },
      { key = 'consume', label = 'Consume it when met', widget = 'bool', default = false },
      { key = 'message', label = 'Message if not met', widget = 'text', optional = true },
    },
  },
  {
    type = 'reward', label = 'Grant a reward', category = 'Story Logic',
    summary = 'Give money, gold, XP, and/or items.',
    fields = {
      { key = 'money', label = 'Money', widget = 'number', default = 0, min = 0 },
      { key = 'gold', label = 'Gold', widget = 'number', default = 0, min = 0 },
      { key = 'xp', label = 'XP', widget = 'number', default = 0, min = 0 },
      { key = 'items', label = 'Items', widget = 'items' },
    },
  },
  ---------------------------------------------------------------------- Flow ---
  {
    type = 'end', label = 'End the mission', category = 'Flow',
    summary = 'A terminal node: finish the mission as completed or failed.',
    fields = {
      { key = 'outcome', label = 'Outcome', widget = 'select', default = 'completed',
        options = { { value = 'completed', label = 'Completed (success)' }, { value = 'failed', label = 'Failed' } } },
      { key = 'message', label = 'Closing line', widget = 'textarea', optional = true },
    },
  },
}

-- mission-level metadata (D1/D2/D3/C1) shown in Mission Settings
SWSchemas.missionMeta = {
  { key = 'repeat', label = 'Repeatable', widget = 'select', default = 'unlimited',
    options = { { value = 'unlimited', label = 'Unlimited' }, { value = 'once', label = 'Once ever' }, { value = 'per_cycle', label = 'Once per reset cycle' } } },
  { key = 'schedule.cycle', label = 'Reset cycle', widget = 'select', default = '',
    options = { { value = '', label = 'None' }, { value = 'daily', label = 'Daily' }, { value = 'weekly', label = 'Weekly' }, { value = 'monthly', label = 'Monthly' } } },
  { key = 'access.jobs', label = 'Restrict to jobs (comma-separated, blank = all)', widget = 'csv' },
  { key = 'access.minGrade', label = 'Minimum grade', widget = 'number', optional = true },
  { key = 'unlock.requires', label = 'Requires these missions first (codes, comma-separated)', widget = 'csv' },
}

function SWSchemas.All()
  return { nodes = SWSchemas.nodes, categories = SWSchemas.categories, missionMeta = SWSchemas.missionMeta }
end

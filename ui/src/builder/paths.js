// Sovereign Storyworks — dot-path config helpers
// Phase 5 | The inspector reads/writes node config by dot path so schemas can
// target nested keys (departure.distance, pickup.x) without bespoke code.
// The special key '@root' addresses the config object itself (for tasks whose
// coords live at the top level, e.g. goto/search/holdaction).

export function getPath(obj, path) {
  if (path === '@root') return obj
  return path.split('.').reduce((o, k) => (o == null ? undefined : o[k]), obj)
}

export function setPath(obj, path, value) {
  const next = { ...obj }
  if (path === '@root') return { ...next, ...value }
  const keys = path.split('.')
  let cur = next
  for (let i = 0; i < keys.length - 1; i++) {
    const k = keys[i]
    cur[k] = (cur[k] && typeof cur[k] === 'object') ? { ...cur[k] } : {}
    cur = cur[k]
  }
  cur[keys[keys.length - 1]] = value
  return next
}

export function delPath(obj, path) {
  if (path === '@root') return obj
  const keys = path.split('.')
  const next = { ...obj }
  let cur = next
  for (let i = 0; i < keys.length - 1; i++) {
    const k = keys[i]
    if (!cur[k] || typeof cur[k] !== 'object') return next
    cur[k] = { ...cur[k] }
    cur = cur[k]
  }
  delete cur[keys[keys.length - 1]]
  return next
}

// Sovereign Storyworks — mission editor (node canvas + inspector)
// Phase 5 | Features: A1, A3 (connected blocks with branch paths), A5.
// Nodes are cards; success/failure edges are dropdowns pointing at other nodes;
// one node is the start. Selecting a card opens its schema-driven inspector.
// Save keeps a draft; Publish validates server-side and makes it startable.

import { useMemo, useState } from 'react'
import { action } from './nui.js'
import { setPath } from './paths.js'
import Inspector from './Inspector.jsx'

let nodeSeq = 0
function newNodeId(def) {
  nodeSeq += 1
  let id = 'n' + nodeSeq
  while (def.nodes[id]) { nodeSeq += 1; id = 'n' + nodeSeq }
  return id
}

function Palette({ schemas, onAdd }) {
  return (
    <div className="ed-palette">
      <div className="ed-palette-title">Add a step</div>
      {schemas.categories.map(cat => {
        const nodes = schemas.nodes.filter(n => n.category === cat)
        if (nodes.length === 0) return null
        return (
          <div className="ed-palette-cat" key={cat}>
            <div className="ed-cat-name">{cat}</div>
            {nodes.map(n => (
              <button key={n.type} className="ed-palette-btn" title={n.summary} onClick={() => onAdd(n.type)}>
                {n.label}
              </button>
            ))}
          </div>
        )
      })}
    </div>
  )
}

export default function Editor({ schemas, def, setDef, flash, onSaved, onBackToLibrary }) {
  const [selected, setSelected] = useState(null)
  const [showSettings, setShowSettings] = useState(false)
  const [busy, setBusy] = useState(false)

  const schemaFor = useMemo(() => {
    const map = {}
    schemas.nodes.forEach(n => { map[n.type] = n })
    return map
  }, [schemas])

  const nodeIds = Object.keys(def.nodes)

  const update = (patch) => setDef({ ...def, ...patch })
  const updateNode = (id, patch) => setDef({ ...def, nodes: { ...def.nodes, [id]: { ...def.nodes[id], ...patch } } })

  const addNode = (type) => {
    const id = newNodeId(def)
    const s = schemaFor[type]
    // seed select + non-zero-number defaults so conditional fields (showIf) work
    // at once; skip 0-defaults (e.g. "0 = none" time limits) so absence = default.
    let config = {}
    s.fields.forEach(f => {
      if (f.key === '@root' || f.default === undefined) return
      if (f.widget === 'number' && f.default === 0) return
      config = setPath(config, f.key, f.default)
    })
    const node = { type, label: '', config, onSuccess: '', onFailure: '' }
    const nodes = { ...def.nodes, [id]: node }
    const patch = { nodes }
    if (!def.start) patch.start = id
    setDef({ ...def, ...patch })
    setSelected(id)
  }

  const removeNode = (id) => {
    const nodes = { ...def.nodes }
    delete nodes[id]
    // clear edges pointing at it
    Object.keys(nodes).forEach(k => {
      const n = { ...nodes[k] }
      if (n.onSuccess === id) n.onSuccess = ''
      if (n.onFailure === id) n.onFailure = ''
      nodes[k] = n
    })
    const patch = { nodes }
    if (def.start === id) patch.start = Object.keys(nodes)[0] || ''
    setDef({ ...def, ...patch })
    if (selected === id) setSelected(null)
  }

  const save = async () => {
    setBusy(true)
    const res = await action('save', { def })
    setBusy(false)
    if (res.ok) { flash('Draft saved.'); onSaved() }
    else flash(res.data?.error || 'Could not save.', 'err')
  }

  const publish = async () => {
    setBusy(true)
    const res = await action('publish', { def })
    setBusy(false)
    if (res.ok) { flash('Published! Players can start it now.'); onSaved() }
    else flash(res.data?.error || 'Could not publish.', 'err')
  }

  const sel = selected && def.nodes[selected]

  return (
    <div className="ed">
      <div className="ed-topbar">
        <button className="bld-link" onClick={onBackToLibrary}>← Library</button>
        <input className="ed-title" value={def.title} onChange={e => update({ title: e.target.value })} placeholder="Mission title" />
        <input className="ed-code" value={def.code}
          title="The id players use to start it (letters, numbers, underscores)"
          onChange={e => update({ code: e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, '_').slice(0, 60) })}
          placeholder="mission_id" />
        <div className="ed-top-actions">
          <button className="bld-btn ghost" onClick={() => setShowSettings(s => !s)}>Settings</button>
          <button className="bld-btn" disabled={busy} onClick={save}>Save Draft</button>
          <button className="bld-btn primary" disabled={busy} onClick={publish}>Publish</button>
        </div>
      </div>

      {showSettings && <Settings schemas={schemas} def={def} update={update} />}

      <div className="ed-body">
        <Palette schemas={schemas} onAdd={addNode} />

        <div className="ed-canvas">
          {nodeIds.length === 0 && (
            <div className="ed-empty">Add your first step from the left. The first step you add becomes the mission's start.</div>
          )}
          {nodeIds.map(id => {
            const node = def.nodes[id]
            const s = schemaFor[node.type]
            return (
              <div key={id} className={`ed-node${selected === id ? ' sel' : ''}${def.start === id ? ' start' : ''}`} onClick={() => setSelected(id)}>
                <div className="ed-node-head">
                  <span className="ed-node-type">{s ? s.label : node.type}</span>
                  {def.start === id && <span className="ed-badge">START</span>}
                  <button className="ed-node-x" onClick={(e) => { e.stopPropagation(); removeNode(id) }}>×</button>
                </div>
                {!(s && s.terminal) && (
                  <input className="ed-node-label" placeholder="Objective text shown to the player (optional)"
                    value={node.label || ''} onClick={e => e.stopPropagation()}
                    onChange={e => updateNode(id, { label: e.target.value })} />
                )}
                {s && s.terminal ? (
                  <div className="ed-terminal-note">This ends the mission. Nothing runs after it.</div>
                ) : (
                  <div className="ed-edges">
                    <label>on success →
                      <select value={node.onSuccess || ''} onClick={e => e.stopPropagation()} onChange={e => updateNode(id, { onSuccess: e.target.value })}>
                        <option value="">— finish (completed) —</option>
                        {nodeIds.filter(x => x !== id).map(x => <option key={x} value={x}>{def.nodes[x].label || (schemaFor[def.nodes[x].type]?.label) || x}</option>)}
                      </select>
                    </label>
                    <label>on failure →
                      <select value={node.onFailure || ''} onClick={e => e.stopPropagation()} onChange={e => updateNode(id, { onFailure: e.target.value })}>
                        <option value="">— finish (failed) —</option>
                        {nodeIds.filter(x => x !== id).map(x => <option key={x} value={x}>{def.nodes[x].label || (schemaFor[def.nodes[x].type]?.label) || x}</option>)}
                      </select>
                    </label>
                  </div>
                )}
                {def.start !== id && (
                  <button className="ed-setstart" onClick={(e) => { e.stopPropagation(); update({ start: id }) }}>set as start</button>
                )}
              </div>
            )
          })}
        </div>

        <div className="ed-inspector">
          {!sel && <div className="ed-inspector-empty">Select a step to edit its details.</div>}
          {sel && schemaFor[sel.type] && (
            <>
              <div className="ed-inspector-head">{schemaFor[sel.type].label}</div>
              <div className="ed-inspector-summary">{schemaFor[sel.type].summary}</div>
              <Inspector
                schema={schemaFor[sel.type]}
                config={sel.config || {}}
                onConfig={(c) => updateNode(selected, { config: c })}
              />
            </>
          )}
        </div>
      </div>
    </div>
  )
}

const isEmpty = (v) => v == null || v === '' || (Array.isArray(v) && v.length === 0)

function Settings({ schemas, def, update }) {
  // Writes the RUNTIME shape directly: CSV → array, empties pruned (a bare
  // {schedule:{}} or {access:{jobs:[]}} would fail validation), and a parent
  // object removed once its last leaf is cleared.
  const setMeta = (key, raw) => {
    const keys = key.split('.')
    const next = { ...def }
    const value = isEmpty(raw) ? undefined : raw
    if (keys.length === 1) {
      if (value === undefined) delete next[keys[0]]; else next[keys[0]] = value
    } else {
      const obj = { ...(next[keys[0]] || {}) }
      if (value === undefined) delete obj[keys[1]]; else obj[keys[1]] = value
      if (Object.keys(obj).length === 0) delete next[keys[0]]; else next[keys[0]] = obj
    }
    update(next)
  }
  const get = (key) => key.split('.').reduce((o, k) => (o == null ? undefined : o[k]), def)

  return (
    <div className="ed-settings">
      <div className="ed-settings-title">Mission Settings — who can play it, and when</div>
      <div className="ed-settings-grid">
        {schemas.missionMeta.map(f => {
          const cur = get(f.key)
          return (
            <label className="ins-field" key={f.key}>
              <span className="ins-label">{f.label}</span>
              {f.widget === 'select' ? (
                <select className="ins-input" value={cur ?? f.default ?? ''} onChange={e => setMeta(f.key, e.target.value)}>
                  {f.options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
              ) : f.widget === 'number' ? (
                <input className="ins-input num" type="number" value={cur ?? ''} onChange={e => setMeta(f.key, e.target.value === '' ? '' : Number(e.target.value))} />
              ) : f.widget === 'csv' ? (
                <input className="ins-input" value={Array.isArray(cur) ? cur.join(', ') : ''}
                  onChange={e => setMeta(f.key, e.target.value.split(',').map(s => s.trim()).filter(Boolean))} />
              ) : (
                <input className="ins-input" value={cur ?? ''} onChange={e => setMeta(f.key, e.target.value)} />
              )}
            </label>
          )
        })}
      </div>
      <div className="ed-settings-note">Blank fields mean “no restriction.” Jobs and requires accept comma-separated lists.</div>
    </div>
  )
}

// Sovereign Storyworks — schema-driven property inspector
// Phase 5 | Features: A1 (no-code forms), A5 (in-world capture). Renders a
// node's editable config from its schema — every task type configures itself
// through the same generic widgets; no per-task UI. This is B1's payoff.

import { capture } from './nui.js'
import { getPath, setPath, delPath } from './paths.js'

function showField(field, config) {
  const cond = field.showIf
  if (!cond) return true
  const cur = getPath(config, cond.field)
  if (cond.equals !== undefined) return cur === cond.equals
  if (cond.notEquals !== undefined) return cur !== cond.notEquals
  return true
}

function Coords({ value, onCapture, onClear, optional }) {
  const has = value && value.x != null
  return (
    <div className="ins-coords">
      {has ? (
        <span className="ins-coords-val">
          {Number(value.x).toFixed(1)}, {Number(value.y).toFixed(1)}, {Number(value.z).toFixed(1)}
          {value.heading != null && <em> · {Number(value.heading).toFixed(0)}°</em>}
        </span>
      ) : (
        <span className="ins-coords-empty">not set</span>
      )}
      <button className="ins-capture" onClick={onCapture}>◎ Use my position</button>
      {has && optional && <button className="ins-clear" onClick={onClear}>clear</button>}
    </div>
  )
}

function CoordsList({ list, onChange }) {
  const add = async () => { const p = await capture(); onChange([...(list || []), p]) }
  const remove = (i) => onChange(list.filter((_, x) => x !== i))
  return (
    <div className="ins-coordslist">
      {(list || []).map((c, i) => (
        <div className="ins-cl-row" key={i}>
          <span className="n">{i + 1}.</span>
          <span className="v">{Number(c.x).toFixed(1)}, {Number(c.y).toFixed(1)}, {Number(c.z).toFixed(1)}</span>
          <button className="ins-clear" onClick={() => remove(i)}>remove</button>
        </div>
      ))}
      <button className="ins-capture" onClick={add}>◎ Add my position as a checkpoint</button>
      {(list || []).length < 2 && <div className="ins-hint">Add at least 2.</div>}
    </div>
  )
}

function Items({ list, onChange }) {
  const add = () => onChange([...(list || []), { item: '', amount: 1 }])
  const set = (i, k, v) => onChange(list.map((it, x) => x === i ? { ...it, [k]: v } : it))
  const remove = (i) => onChange(list.filter((_, x) => x !== i))
  return (
    <div className="ins-items">
      {(list || []).map((it, i) => (
        <div className="ins-item-row" key={i}>
          <input className="ins-input" placeholder="item name" value={it.item} onChange={e => set(i, 'item', e.target.value)} />
          <input className="ins-input num" type="number" min="1" value={it.amount} onChange={e => set(i, 'amount', Number(e.target.value))} />
          <button className="ins-clear" onClick={() => remove(i)}>×</button>
        </div>
      ))}
      <button className="ins-add" onClick={add}>+ add item</button>
    </div>
  )
}

function Lines({ list, onChange }) {
  const add = () => onChange([...(list || []), { speaker: '', text: '' }])
  const set = (i, k, v) => onChange(list.map((ln, x) => x === i ? { ...ln, [k]: v } : ln))
  const remove = (i) => onChange(list.filter((_, x) => x !== i))
  return (
    <div className="ins-lines">
      {(list || []).map((ln, i) => (
        <div className="ins-line-row" key={i}>
          <input className="ins-input speaker" placeholder="speaker" value={ln.speaker || ''} onChange={e => set(i, 'speaker', e.target.value)} />
          <input className="ins-input" placeholder="what they say" value={ln.text || ''} onChange={e => set(i, 'text', e.target.value)} />
          <input className="ins-input voice" placeholder="voice.ogg (optional)" value={ln.voice || ''} onChange={e => set(i, 'voice', e.target.value)} />
          <button className="ins-clear" onClick={() => remove(i)}>×</button>
        </div>
      ))}
      <button className="ins-add" onClick={add}>+ add line</button>
    </div>
  )
}

function Choice({ value, onChange }) {
  const v = value || {}
  const set = (k, val) => onChange({ ...v, [k]: val })
  const on = v.question != null || v.optionA != null
  if (!on) return <button className="ins-add" onClick={() => onChange({ question: '', optionA: '', optionB: '' })}>+ add a response choice</button>
  return (
    <div className="ins-choice">
      <input className="ins-input" placeholder="question" value={v.question || ''} onChange={e => set('question', e.target.value)} />
      <input className="ins-input" placeholder="option A → success path" value={v.optionA || ''} onChange={e => set('optionA', e.target.value)} />
      <input className="ins-input" placeholder="option B → failure path" value={v.optionB || ''} onChange={e => set('optionB', e.target.value)} />
      <button className="ins-clear" onClick={() => onChange(undefined)}>remove choice</button>
    </div>
  )
}

export default function Inspector({ schema, config, onConfig }) {
  const setField = (key, value) => onConfig(setPath(config, key, value))

  const captureInto = async (key) => {
    const p = await capture()
    if (key === '@root') onConfig({ ...config, ...p })
    else onConfig(setPath(config, key, p))
  }

  const clearField = (key) => onConfig(delPath(config, key))

  return (
    <div className="ins">
      {schema.fields.map((field) => {
        if (!showField(field, config)) return null
        if (field.widget === 'const') return null
        const cur = getPath(config, field.key)

        return (
          <label className="ins-field" key={field.key}>
            <span className="ins-label">{field.label}{field.optional && <em> (optional)</em>}</span>

            {field.widget === 'text' && (
              <input className="ins-input" value={cur ?? ''} onChange={e => setField(field.key, e.target.value)} placeholder={field.default != null ? String(field.default) : ''} />
            )}
            {field.widget === 'textarea' && (
              <textarea className="ins-input area" value={cur ?? ''} onChange={e => setField(field.key, e.target.value)} rows={2} />
            )}
            {field.widget === 'number' && (
              <input className="ins-input num" type="number" value={cur ?? field.default ?? 0}
                min={field.min} max={field.max}
                onChange={e => setField(field.key, e.target.value === '' ? '' : Number(e.target.value))} />
            )}
            {field.widget === 'bool' && (
              <input type="checkbox" className="ins-check" checked={!!cur} onChange={e => setField(field.key, e.target.checked)} />
            )}
            {field.widget === 'select' && (
              <select className="ins-input" value={cur ?? field.default ?? ''} onChange={e => {
                let c = setPath(config, field.key, e.target.value)
                if (field.clears) field.clears.forEach(p => { c = delPath(c, p) }) // wipe stale other-mode keys
                onConfig(c)
              }}>
                {field.options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            )}
            {field.widget === 'coords' && (
              <Coords value={field.key === '@root' ? config : cur} optional={field.optional}
                onCapture={() => captureInto(field.key)}
                onClear={() => {
                  if (field.key === '@root') { const c = { ...config }; delete c.x; delete c.y; delete c.z; delete c.heading; onConfig(c) }
                  else clearField(field.key)
                }} />
            )}
            {field.widget === 'coordsList' && (
              <CoordsList list={cur} onChange={v => setField(field.key, v)} />
            )}
            {field.widget === 'items' && (
              <Items list={cur} onChange={v => setField(field.key, v)} />
            )}
            {field.widget === 'lines' && (
              <Lines list={cur} onChange={v => setField(field.key, v)} />
            )}
            {field.widget === 'choice' && (
              <Choice value={cur} onChange={v => v === undefined ? onConfig(delPath(config, field.key)) : setField(field.key, v)} />
            )}

            {field.help && <span className="ins-help">{field.help}</span>}
          </label>
        )
      })}
    </div>
  )
}

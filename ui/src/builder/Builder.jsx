// Sovereign Storyworks — builder shell
// Phase 5 | Features: A1, A2, A4, A7 — ledger window to the approved dashboard
// mockup: masthead, Registry/Craft/Office nav, dashboard, library, and the
// mission editor. One screen the whole no-code workflow lives in.

import { useEffect, useState, useCallback } from 'react'
import { action, closeBuilder } from './nui.js'
import Dashboard from './Dashboard.jsx'
import Library from './Library.jsx'
import Editor from './Editor.jsx'
import './builder.css'

const NAV = [
  { group: 'Registry', items: [
    { id: 'dashboard', glyph: '◆', label: 'Dashboard' },
    { id: 'library', glyph: '▤', label: 'Mission Library' },
    { id: 'new', glyph: '✚', label: 'New Mission' },
  ] },
  { group: 'Office', items: [
    { id: 'close', glyph: '✕', label: 'Close', close: true },
  ] },
]

let draftSeq = 0
function newDraft() {
  draftSeq += 1
  const code = 'draft_' + Date.now().toString(36) + '_' + draftSeq
  return {
    schema: 1,
    code,
    title: 'Untitled Mission',
    start: '',
    nodes: {},
  }
}

export default function Builder({ onClose }) {
  const [view, setView] = useState('dashboard')
  const [schemas, setSchemas] = useState(null)
  const [missions, setMissions] = useState([])
  const [editing, setEditing] = useState(null) // mission def being edited
  const [toast, setToast] = useState(null)

  const flash = useCallback((text, kind) => {
    setToast({ text, kind: kind || 'ok', id: Date.now() })
    setTimeout(() => setToast(t => (t && Date.now() - t.id >= 2500 ? null : t)), 2600)
  }, [])

  useEffect(() => {
    action('bootstrap').then(res => {
      if (res.ok) {
        setSchemas(res.data.schemas)
        setMissions(res.data.missions || [])
      } else {
        flash(res.data?.error || 'Could not load the builder.', 'err')
      }
    })
  }, [flash])

  const refresh = useCallback(async () => {
    const res = await action('list')
    if (res.ok) setMissions(res.data.missions || [])
  }, [])

  const openNew = useCallback(() => {
    setEditing(newDraft())
    setView('editor')
  }, [])

  const openMission = useCallback(async (code) => {
    const res = await action('load', { code })
    if (res.ok && res.data.def) {
      setEditing(res.data.def)
      setView('editor')
    } else {
      flash(res.data?.error || 'Could not open that mission.', 'err')
    }
  }, [flash])

  const duplicateMission = useCallback(async (code) => {
    const res = await action('load', { code })
    if (res.ok && res.data.def) {
      const copy = JSON.parse(JSON.stringify(res.data.def))
      copy.code = 'draft_' + Date.now().toString(36)
      copy.title = copy.title + ' (copy)'
      setEditing(copy)
      setView('editor')
      flash('Copied — save it to keep the copy.')
    }
  }, [flash])

  const archiveMission = useCallback(async (code) => {
    const res = await action('archive', { code })
    if (res.ok) { setMissions(res.data.missions || []); flash('Archived.') }
  }, [flash])

  const doClose = useCallback(() => { closeBuilder(); onClose() }, [onClose])

  // Esc closes — caught here because with NUI focus the game's control check
  // never fires (owner round 1). Ignore Esc while typing in a field.
  useEffect(() => {
    const onKey = (e) => {
      if (e.key !== 'Escape') return
      const t = e.target
      if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.tagName === 'SELECT')) { t.blur(); return }
      doClose()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [doClose])

  const onNav = (item) => {
    if (item.close) return doClose()
    if (item.id === 'new') return openNew()
    setView(item.id)
  }

  return (
    <div className="bld-root">
      <div className="bld-window">
        <span className="bld-corner tl" /><span className="bld-corner tr" />
        <span className="bld-corner bl" /><span className="bld-corner br" />

        <header className="bld-masthead">
          <div className="est">Sovereign County · Office of Records</div>
          <h1>Sovereign <span className="amp">Storyworks</span></h1>
          <div className="flourish" />
        </header>

        <div className="bld-frame">
          <nav className="bld-nav">
            {NAV.map(sec => (
              <div key={sec.group}>
                <div className="bld-nav-label">{sec.group}</div>
                {sec.items.map(item => (
                  <button
                    key={item.id}
                    className={`bld-nav-item${view === item.id ? ' active' : ''}${item.close ? ' close' : ''}`}
                    onClick={() => onNav(item)}
                  >
                    <span className="glyph">{item.close ? '✕' : item.glyph}</span> {item.label}
                  </button>
                ))}
              </div>
            ))}
            <div className="bld-nav-spacer" />
            <div className="bld-nav-hint">Esc closes the builder</div>
          </nav>

          <main className="bld-main">
            {!schemas && <div className="bld-loading">Opening the county records…</div>}
            {schemas && view === 'dashboard' && (
              <Dashboard missions={missions} onOpen={openMission} onNew={openNew} />
            )}
            {schemas && view === 'library' && (
              <Library missions={missions} onOpen={openMission} onNew={openNew}
                onDuplicate={duplicateMission} onArchive={archiveMission} />
            )}
            {schemas && view === 'editor' && editing && (
              <Editor
                schemas={schemas}
                def={editing}
                setDef={setEditing}
                flash={flash}
                onSaved={refresh}
                onBackToLibrary={() => { setView('library'); refresh() }}
              />
            )}
          </main>
        </div>

        {toast && <div className={`bld-toast ${toast.kind}`}>{toast.text}</div>}
      </div>
    </div>
  )
}

// Sovereign Storyworks — mission library
// Phase 5 | Features: A4 — drafts, published, archived; open / duplicate / archive.

import { useState } from 'react'

function fmtWhen(epoch) {
  if (!epoch) return '—'
  return new Date(epoch * 1000).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
}

export default function Library({ missions, onOpen, onNew, onDuplicate, onArchive }) {
  const [filter, setFilter] = useState('all')
  const shown = missions.filter(m => filter === 'all' || m.status === filter)

  return (
    <div className="bld-view">
      <h2 className="bld-section">
        Mission Library <span className="aside">every tale on the books</span>
        <button className="bld-btn primary small" onClick={onNew}>✚ New</button>
      </h2>

      <div className="bld-filters">
        {['all', 'published', 'draft', 'archived'].map(f => (
          <button key={f} className={`bld-chip${filter === f ? ' on' : ''}`} onClick={() => setFilter(f)}>
            {f === 'all' ? 'All' : f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        ))}
      </div>

      {shown.length === 0 && <div className="bld-empty">Nothing here yet.</div>}
      {shown.length > 0 && (
        <div className="bld-tablewrap">
          <table className="bld-table">
            <thead>
              <tr><th>Mission</th><th>Status</th><th>Steps</th><th>Amended</th><th className="right">Actions</th></tr>
            </thead>
            <tbody>
              {shown.map(m => (
                <tr key={m.code}>
                  <td className="name">{m.title}<small>{m.code}</small></td>
                  <td><span className={`bld-status ${m.status}`}>{m.status}</span></td>
                  <td className="num">{m.nodes}</td>
                  <td>{fmtWhen(m.updated)}</td>
                  <td className="right actions">
                    <button className="bld-link" onClick={() => onOpen(m.code)}>Open</button>
                    <button className="bld-link" onClick={() => onDuplicate(m.code)}>Duplicate</button>
                    {m.status !== 'archived' && (
                      <button className="bld-link danger" onClick={() => onArchive(m.code)}>Archive</button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

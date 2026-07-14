// Sovereign Storyworks — builder dashboard
// Phase 5 | Features: A2 — stat tiles + recent missions to the approved mockup.

function StatTile({ n, cap, note, red }) {
  return (
    <div className={`bld-tile${red ? ' red' : ''}`}>
      <div className="num">{n}</div>
      <div className="cap">{cap}</div>
      {note && <div className="note">{note}</div>}
    </div>
  )
}

function fmtWhen(epoch) {
  if (!epoch) return '—'
  const d = new Date(epoch * 1000)
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
}

export default function Dashboard({ missions, onOpen, onNew }) {
  const published = missions.filter(m => m.status === 'published')
  const drafts = missions.filter(m => m.status === 'draft')
  const archived = missions.filter(m => m.status === 'archived')
  const recent = missions.slice(0, 8)

  return (
    <div className="bld-view">
      <h2 className="bld-section">County Ledger <span className="aside">the missions of Sovereign County</span></h2>

      <div className="bld-tiles">
        <StatTile n={published.length} cap="Published" note="live on the server" />
        <StatTile n={drafts.length} cap="Drafts" note="unfinished business" />
        <StatTile n={archived.length} cap="Archived" note="set aside" />
        <StatTile n={missions.length} cap="Total" note="in the records" red />
      </div>

      <div className="bld-actionsrow">
        <button className="bld-btn primary" onClick={onNew}>✚ &nbsp;Draft a New Mission</button>
      </div>

      <h2 className="bld-section">Recent <span className="aside">last amended first</span></h2>
      {recent.length === 0 && (
        <div className="bld-empty">
          No missions yet. Press <b>Draft a New Mission</b> to write the county's first legend.
        </div>
      )}
      {recent.length > 0 && (
        <div className="bld-tablewrap">
          <table className="bld-table">
            <thead>
              <tr><th>Mission</th><th>Status</th><th>Steps</th><th>Amended</th><th></th></tr>
            </thead>
            <tbody>
              {recent.map(m => (
                <tr key={m.code}>
                  <td className="name">{m.title}<small>{m.code}</small></td>
                  <td><span className={`bld-status ${m.status}`}>{m.status}</span></td>
                  <td className="num">{m.nodes}</td>
                  <td>{fmtWhen(m.updated)}</td>
                  <td><button className="bld-link" onClick={() => onOpen(m.code)}>Open</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

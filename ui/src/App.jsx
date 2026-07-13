// Sovereign Storyworks — K1 objective tracker (runtime HUD)
// Phase 2 | Features: K1 — minimal branded HUD: current mission, current
// objective, live distance (display only; client computes distance for its
// own eyes, the server still judges arrival). Hidden when no mission runs.
// Presentation is server-config only (ConfigRuntime.Tracker), ruling #9 spirit.

import { useEffect, useState } from 'react'

const DEFAULTS = { anchor: 'bottom-left', scale: 1.0 }

export default function App() {
  const [config, setConfig] = useState(DEFAULTS)
  const [objective, setObjective] = useState(null) // { title, label, hasTarget }
  const [meters, setMeters] = useState(null)

  useEffect(() => {
    const onMessage = (event) => {
      const data = event.data
      if (!data || typeof data.type !== 'string') return
      if (data.type === 'k1:config') setConfig(c => ({ ...c, ...data.config }))
      if (data.type === 'k1:objective') {
        setObjective({ title: data.title, label: data.label, hasTarget: !!data.hasTarget })
        setMeters(null)
      }
      if (data.type === 'k1:distance') setMeters(data.meters)
      if (data.type === 'k1:clear') { setObjective(null); setMeters(null) }
    }
    window.addEventListener('message', onMessage)
    return () => window.removeEventListener('message', onMessage)
  }, [])

  if (!objective) return null

  return (
    <div className="k1-root" style={{ '--k1-scale': config.scale }}>
      <div className={`k1-tracker ${config.anchor}`}>
        <div className="k1-title">{objective.title}</div>
        <div className="k1-row">
          <div className="k1-label">{objective.label}</div>
          {objective.hasTarget && meters != null && (
            <div className="k1-distance">{Math.round(meters)}<span>m</span></div>
          )}
        </div>
      </div>
    </div>
  )
}

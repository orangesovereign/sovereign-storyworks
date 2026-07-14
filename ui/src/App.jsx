// Sovereign Storyworks — NUI root
// Phase 5 | The one React app hosts BOTH surfaces: the always-on runtime
// tracker (K1, passive overlay) and the focus-taking builder (A1–A5), toggled
// by messages from client/builder.lua. They never fight — the tracker is a
// pointer-none overlay; the builder mounts above it only when opened.

import { useEffect, useState } from 'react'
import Tracker from './Tracker.jsx'
import Builder from './builder/Builder.jsx'

export default function App() {
  const [builderOpen, setBuilderOpen] = useState(false)

  useEffect(() => {
    const onMessage = (event) => {
      const data = event.data
      if (!data || typeof data.type !== 'string') return
      if (data.type === 'builder:open') setBuilderOpen(true)
      if (data.type === 'builder:close') setBuilderOpen(false)
    }
    window.addEventListener('message', onMessage)
    return () => window.removeEventListener('message', onMessage)
  }, [])

  return (
    <>
      <Tracker />
      {builderOpen && <Builder onClose={() => setBuilderOpen(false)} />}
    </>
  )
}

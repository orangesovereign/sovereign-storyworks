// Sovereign Storyworks — branded custom dropdown
// Phase 5 round 1 fix. Native <select> popups corrupt the CEF/NUI compositor
// on close (rainbow GPU-memory static over freshly-revealed content — owner
// image, ART III). This renders its own list so the engine never opens a
// native popup window. Also matches the house style (sovereign_menus does the
// same and never had the artifact).
//
// The list is position:fixed, measured from the button, so it escapes the
// inspector/canvas overflow clipping (no transformed ancestors exist, so fixed
// is viewport-relative). We close on any scroll so it can't detach.

import { useEffect, useLayoutEffect, useRef, useState } from 'react'

export default function Dropdown({ value, options, onChange, className = '', placeholder = 'Select…' }) {
  const [open, setOpen] = useState(false)
  const [active, setActive] = useState(0)
  const [pos, setPos] = useState(null)
  const rootRef = useRef(null)
  const btnRef = useRef(null)

  const sel = options.find(o => o.value === value)
  const label = sel ? sel.label : placeholder

  const place = () => {
    const r = btnRef.current && btnRef.current.getBoundingClientRect()
    if (r) setPos({ top: r.bottom + 2, left: r.left, width: r.width })
  }

  useLayoutEffect(() => { if (open) place() }, [open])

  useEffect(() => {
    if (!open) return
    const onDoc = (e) => { if (rootRef.current && !rootRef.current.contains(e.target)) setOpen(false) }
    const onScroll = () => setOpen(false)
    document.addEventListener('mousedown', onDoc)
    window.addEventListener('scroll', onScroll, true)
    window.addEventListener('resize', onScroll)
    return () => { document.removeEventListener('mousedown', onDoc); window.removeEventListener('scroll', onScroll, true); window.removeEventListener('resize', onScroll) }
  }, [open])

  const openList = () => { setActive(Math.max(0, options.findIndex(o => o.value === value))); setOpen(true) }
  const choose = (o) => { onChange(o.value); setOpen(false) }

  const onKey = (e) => {
    if (e.key === 'Escape' && open) { e.stopPropagation(); e.preventDefault(); setOpen(false); return } // don't bubble to the builder's Esc-to-close
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault()
      if (!open) openList(); else choose(options[active])
    } else if (e.key === 'ArrowDown') {
      e.preventDefault(); if (!open) openList(); else setActive(a => Math.min(options.length - 1, a + 1))
    } else if (e.key === 'ArrowUp') {
      e.preventDefault(); setActive(a => Math.max(0, a - 1))
    }
  }

  return (
    <div className={`dd ${open ? 'open' : ''} ${className}`} ref={rootRef} onClick={e => e.stopPropagation()}>
      <button type="button" ref={btnRef} className="dd-btn" onClick={() => open ? setOpen(false) : openList()} onKeyDown={onKey}>
        <span className="dd-val">{label}</span>
        <span className="dd-caret">▾</span>
      </button>
      {open && pos && (
        <div className="dd-list" role="listbox" style={{ position: 'fixed', top: pos.top, left: pos.left, minWidth: pos.width }}>
          {options.map((o, i) => (
            <div key={o.value} role="option" aria-selected={o.value === value}
              className={`dd-opt ${o.value === value ? 'sel' : ''} ${i === active ? 'active' : ''}`}
              onMouseEnter={() => setActive(i)} onClick={() => choose(o)}>
              {o.label}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

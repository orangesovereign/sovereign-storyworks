// Sovereign Storyworks — builder NUI bridge
// Phase 5 | Every builder data action goes through the client 'builder' callback
// (token request/reply to the server); capture + close are local client callbacks.

function parent() {
  return (typeof window.GetParentResourceName === 'function' && window.GetParentResourceName()) || 'sovereign_storyworks'
}

async function post(name, body) {
  try {
    const res = await fetch(`https://${parent()}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body || {}),
    })
    return await res.json()
  } catch {
    return { ok: false, data: { error: 'The wire went dead — is the resource running?' } }
  }
}

// server-backed builder action → { ok, data }
export function action(name, payload) {
  return post('builder', { action: name, payload })
}

// in-world coordinate capture (A5) → { x, y, z, heading }
export function capture() {
  return post('capture', {})
}

export function closeBuilder() {
  return post('builder:close', {})
}

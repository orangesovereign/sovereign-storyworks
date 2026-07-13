// Sovereign Storyworks — runtime HUD build config
// Phase 2 | Features: K4 (K1 joins this app) — relative base so RedM NUI
// resolves bundled assets; everything self-contained, no CDN (standing rule).
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  base: './',
  plugins: [react()],
  build: {
    outDir: 'dist',
    assetsInlineLimit: 0,
  },
})

# Phase 5 Exit-Gate — The No-Code Builder (plain-text mirror)

**Living checklist (tick there):** https://claude.ai/code/artifact/4458b6c7-6449-4a0b-b597-3d88fe3ee2d3
**Ledger rev. 3** — restyled to the approved Sovereign County dashboard design (filigree ledger window, `--sc-*` palette, Cinzel/Fell type, stat tiles, telegram dispatch slip for the gate). Folds the round-1 fix retests into the articles (Esc close, terminal end node, no-static dropdowns, unset-edge publish) and adds the round-1b **UI-scaling** checks to ART. I. 18 checks; same `sw-phase5-gate` state key (earlier ticks persist).
**Build under test:** sovereign_storyworks v0.5.0-beta (builder ships in the same bundle as the HUD; no new deps)
**Gate (roadmap):** the owner personally builds and publishes a multi-task mission start-to-finish **without touching a file or command** — the A1 acceptance test (ART. V).

## Open it

As a character whose ACE group has `storyworks.builder` (in server.cfg from install): `/storyworks`. Esc or the ✕ Close nav item closes it.

## What shipped (features)

- **A2 shell** to the approved dashboard mockup: masthead, Registry/Craft/Office nav, dashboard stat tiles + recent table.
- **A4 library**: drafts/published/archived with filters; open, duplicate, archive.
- **A1/A3/B1 canvas**: node cards with success/failure edge dropdowns + start selector; every task/logic type builds its own form from one schema catalog (no per-task UI).
- **A5 in-world capture**: "◎ Use my position" fills coordinates (and route checkpoints) with no typing.
- **A7**: ACE-gated open + every builder callback ACE-checked and rate-limited.
- **J1 (draft layer)**: drafts persisted; a draft is saved before every publish so a failed publish never loses work.

## Architecture notes

- The ui/ app hosts BOTH surfaces: the always-on runtime tracker (pointer-none overlay) and the focus-taking builder (mounts above only when opened).
- Builder ↔ server is a token request/reply over net events; the client NUI callback resolves once the server replies. In-world capture is resolved locally.
- Runtime hardening this phase: `timeLimitSeconds` guarded `> 0` across all 10 timed tasks (Lua treats 0 as truthy — a seeded "0 = none" would have timed out instantly).

## Verification already done (in-browser, mocked NUI)

Built end to end and confirmed the emitted mission def is valid: New Mission → add goto + end → capture coords → wire success edge → set title → Publish produced `{schema:1, code, title, start:n1, nodes:{goto→end}}` with captured x/y/z/heading. Shell/nav/dashboard/library/canvas/inspector/capture/edges all render and function.

## Articles (full "Expect" lines in the ledger)

- **ART. I** — open (ACE-gated), Esc/close.
- **ART. II** — library filters, open, duplicate, archive.
- **ART. III** — palette by category; schema-driven forms per step type; mode dropdowns show/hide fields.
- **ART. IV** — in-world capture; success/failure edge wiring; set-as-start.
- **ART. V (THE GATE)** — build a goto→reward→end mission, Publish, then `/swstart <code>` and play it. No file, no code.
- **ART. VI** — validation speaks plainly; Save Draft works on incomplete missions.

## Test log

### Round 1 — 2026-07-13 (owner)

Findings + fixes (shipped same day):
- **ART I: Esc didn't close.** With NUI focus the game control check never fires. → Esc now caught in the NUI (JS keydown); ignores Esc while typing in a field.
- **ART III / END MISSION: "node n3 onFailure points to missing node".** Empty edges (`''`) were read as a node id pointing at a missing node. → Validate and NodeFinished now treat `''` as "finish here". Also: **end nodes are terminal** — no edge dropdowns, a "this ends the mission" note (end shouldn't require another step).
- **Font too small (recurring high-res issue).** → *First attempt (superseded, see round 1b):* `:root` font-size `clamp(15px, 1.85vh, 34px)` + **font-sizes only** converted px→rem. This was wrong — see below.
- **ART III "visual errors after closing the dropdown".** Owner image (received round 1b): rainbow GPU-memory static painted over the coords field the instant a native `<select>` closed and `showIf` revealed new content. Root cause is CEF's compositor mishandling the partial repaint when it tears down a native popup — not our CSS. → **Removed the trigger entirely:** new `Dropdown.jsx` (branded, self-rendered list, no native popup; keyboard-accessible; `position:fixed` so it escapes overflow clipping; closes on scroll/outside-click; Esc closes only the dropdown). All four native selects swapped. Matches sovereign_menus (custom menus, never had the artifact).

### Round 1b — 2026-07-14 (owner, with images)

- **UI scaling botched (my error).** Owner images: the round-1 font fix scaled the **type** with the screen but left every width, grid column, and padding in fixed `px` — so text ballooned out of static boxes: clipping mid-word, cramped columns, horizontal scrollbars. Owner: *"I said scale beautifully with the resolution not jumble it all into the small box."*
  → **Reworked so the whole UI is one proportional system:** every dimension (fonts, column tracks, padding, gaps, borders) is `rem` off a single viewport-anchored root — `font-size: calc(clamp(11px, 1.45vh, 26px) * var(--bld-scale, 1))` — calibrated to match the original px proportions at 1080p and scale up from there. Font-sizes de-inflated (dropped the earlier ×1.22) so type and layout share the `/16` baseline. Added `.ed-canvas { min-width: 0 }` so a long label can't force horizontal scroll.
  → **`--bld-scale` is the single knob** to nudge the whole UI if it reads large/small on the owner's display — no blind deploy loop.
  → Verified in-browser at 1920×1080 **and** 2560×1440: root 15.7px → 20.9px, nav 186px → 248px, node text 11.7px → 15.7px (fonts *and* layout scaling together), zero horizontal overflow at either size. Lesson recorded in memory so menus/notify get this right first time.

### Round 2 — (awaiting: owner retest on the dev server)

Retest focus: Esc close · end nodes terminal (no edge dropdowns) · publish an all-defaults mission with unset edges (no "missing node" error) · **dropdowns open/switch/close with no rainbow static** (ART III) · **the UI sits in proportion on your monitor** — nothing clipped, no bottom scrollbar (round-1b rework; `--bld-scale` tunes it).

Non-builder runtime asks raised during Phase 5 testing (already shipped, verify in play):
- **Physical crate pickup** — use the **Physical carry** step (not Collect/deliver, which is inventory-only and has no world pickup). Crate spawns at the pick-up point, hold [G] to shoulder, hold [G] at the drop-off to set down.
- **Disconnect grace** — close the game mid-mission and DON'T return: after `ConfigRuntime.DisconnectGraceSeconds` (120s) the mission fails and cleans up (props/NPCs gone, DB marked failed). Returning inside the 2 min resumes normally. A server restart is exempt (that's the 48h `InstanceExpiryHours` sweep, not this).

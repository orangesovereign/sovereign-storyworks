# Phase 5 Exit-Gate — The No-Code Builder (plain-text mirror)

**Living checklist (tick there):** https://claude.ai/code/artifact/4458b6c7-6449-4a0b-b597-3d88fe3ee2d3
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

### Round 1 — (awaiting)

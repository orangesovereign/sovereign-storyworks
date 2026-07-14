# Phase 4 Exit-Gate — Story Logic, Progression & Scheduling (plain-text mirror)

**Living checklist (tick there):** https://claude.ai/code/artifact/9aac8973-2b0a-44fe-94d2-0c7fa2022e3a
**Build under test:** sovereign_storyworks v0.4.0-phase4 (migration v3 adds `sovereign_story_progress`)
**Gate (roadmap):** a hand-authored three-chapter story with rewards, job gate, and a daily side mission passes a scripted checklist including reset-boundary tests.

## What shipped (features)

- **Logic nodes** (instant-resolving tasks): `setvar` (set/add/sub/toggle/append), `condition` (branch on var/job/grade/money/gold/xp/time-of-day), `chance` (server-rolled %). — C3, C5
- **require / reward** nodes: VORP-backed resource gates and grants (money/gold/xp/items, optional consume). — B4, C4
- **Progression**: per-character completion history + persisted story variables (`sovereign_story_progress`), resumed on next start; only COMPLETED runs record. — C1, C2
- **Availability gate** at start: job/grade access (D2), unlock prerequisites (C1), repeatability once/per_cycle/unlimited (D3), daily/weekly/monthly reset cycles at a configurable reset hour/week start, real-world server time (D1).

## Fixtures (7, seeded on boot)

`phase4_ch1/ch2/ch3` (unlock-gated arc, rewards, money-require toll, repeat once) · `phase4_daily` (daily reset, per_cycle) · `phase4_vars` (variable persistence → condition branch) · `phase4_luck` (chance branch) · `phase4_gated` (job access).

## Articles (full "Expect" lines in the ledger)

- **ART. I** — migration v3 applies once; 7 new missions seeded.
- **ART. II** — rewards actually credit money/gold/xp; chance ~50/50.
- **ART. III** — ch2 locked until ch1 done; toll requires $10; repeat-once refuses replays.
- **ART. IV** — daily blocks a same-day retry; reset-boundary test (DB nudge or config resetHour) makes it available again.
- **ART. V** — `visits` variable persists across runs AND restart, flipping the condition branch; failed runs never record.
- **ART. VI** — job gate denies non-lawmen, allows after granting the job.

## Test log

### Round 1 — 2026-07-13 (owner)

**"All tests pass."** One observation: no map blips during the Phase 4 missions — **confirmed INTENDED, not a defect.** The Phase 4 fixtures use departure-mode goto ("get N meters away, any direction" — no fixed point by the Phase 1 direction rule; guided by distance-callout tips) or pure logic nodes (luck/vars — no location at all). Fixed-location objectives still blip as in Phases 2–3 (carry/escort/combat/`phase4_ch3` hold-action all have real targets). Nothing to fix. Every Phase 4 exit-gate condition met.

### GATE RULING — 2026-07-13

**PASSED. Owner: "GO."** Tagged `v0.4-alpha`. The runtime is feature-complete for V1. Next: Phase 5 — Builder NUI I (Shell, Library & Canvas) — the no-code editor.

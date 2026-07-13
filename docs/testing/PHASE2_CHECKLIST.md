# Phase 2 Exit-Gate — Task Vocabulary I (plain-text mirror)

**Living checklist (tick there):** https://claude.ai/code/artifact/410f7bb1-172b-4cd7-85cc-501ae7de437b
**Builds under test:** sovereign_storyworks v0.2.0-phase2 · sovereign_notify v1.1.0
**Gate (roadmap):** every task type solo and chained · dialogue with choices and voice · tracker/blips correctness · full physical-cargo run with no orphaned props · zero stock overlays anywhere (ruling #9).

## Deploy

Both resources, in order: `oxmysql` → vorp stack → `ensure sovereign_notify` → `ensure sovereign_storyworks`.
Five seeded missions after boot: `phase1_test`, `phase1_test_fail`, `phase2_errand`, `phase2_freight`, `phase2_delivery`.
Phase 2 fixtures run anywhere on the map (targets are placed east/north of wherever you start — follow the blips).

## Articles (summary — full "Expect" lines live in the ledger)

- **ART. I Deploy & Boot** — clean boot, five missions seeded, Phase 1 courier regression (now with tracker/blips/Sovereign messages).
- **ART. II The Clerk's Errand** — talk (NPC, paced subtitles, optional `test_voice.ogg`), branching choice (G/E — E genuinely fails the mission), search (pause on exit), hold-action (early release no-op; out-of-position hold rejected), wait, 3-checkpoint route.
- **ART. III The Freight Job** — B5 carry (anims, chest ride, sprint/jump blocked), B6 load 3 onto the wagon bed (visible slots), unload 2 at the depot, and the no-orphans article: cancel mid-carry wipes everything; disconnect mid-carry resumes with the crate back at its take point.
- **ART. IV The Grocer's Due** — collect 2 apples (passive inventory watch), deliver with a deliberate short-hand attempt first (edit item name in `data/phase2_delivery.json` if needed).
- **ART. V Presentation** — ZERO stock notifications all session; tracker behavior; owner ruling requested on the new subtitle design (not in the approved K4 mockup).
- **ART. VI Persistence** — disconnect during the errand's wait; resume correctness.

## Test log

### Round 1 — (awaiting)

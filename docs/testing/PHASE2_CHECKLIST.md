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

### Round 1 — 2026-07-13 (owner)

Regression + ART II/III/IV/V run. Findings and fixes (all shipped same day; ledger revision 2):

- **Sizing/resolution:** fixed-px NUI text read too small on the high-res display. → Both HUDs now scale with screen height (`clamp(..2.15vh..)`), everything bold (Baskerville Bold added), subtitle line enlarged. sovereign_notify v1.2.0.
- **Positions:** bottom-left tracker fought the minimap; notify stack was top-right. → New `mid-left`/`mid-right` anchors; defaults per owner: tracker mid-left, notify stack mid-right.
- **BUG — prompts lingered after use** (mission-accept choice, delivery prompt): `SWInteractions.Clear` skipped the client clear when the record was already consumed. → Clear is now unconditional + the completing client gets an immediate clear.
- **BUG — freight unload had no depot mark / couldn't complete:** both cargo nodes shared `state.cargo`, so the unload leg saw the load leg's count (3 ≥ 2) and self-completed invisibly. → Engine now gives every node a private `nodeState` bucket; route/cargo migrated. (Generic fix — any future mission with two same-type nodes needed this.)
- **Dialogue too fast to read:** fixed 3.5s per line. → Lines now time themselves by word count (config: base 1.8s + 0.42s/word, floor 3.5s, ceiling 12s).
- **Owner verdicts:** notification system "great" pending sizing; subtitle design approved in substance (size was the complaint).
- **IDEA logged:** sovereign_menus — county-wide branded menu standalone with mouse select (feature list §2 candidate, pending go-ahead; suggested as a post-gate side quest).

### Round 2 — (awaiting: ART II/III/IV retests + ART V sizing re-rule)

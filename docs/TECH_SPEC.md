# Sovereign Storyworks — Tech Spec & Verification Ledger

**Version: 0.1 (PLANNING DRAFT)**

> Rule: only ✅ items may be used in code. 🔎 items must be verified (repo grep or dev-server spike) before any feature depending on them is coded. ⚠️ items are accepted constraints.

## 1. VORP Core surface (✅ verified during Medical Suite; re-confirm exact signatures at Phase 0)

- ✅ Character object exposes job, grade, money/gold/XP mutation methods (`vorp_core/server/class/character.lua` — `addCurrency`/`removeCurrency`/`addXp`/`setJob` family confirmed present 2026-07-12).
- ✅ Core user/character accessor exports (pattern known from Medical Suite TECH_SPEC).
- ✅ vorp_inventory-v2 is the target inventory (standing owner ruling from the Medical Suite): item add/remove/count via its exports.
- 🔎 Exact V1 export signatures to be extracted verbatim from the cloned repos at Phase 0 (they drift between VORP versions — extract, don't recall).

## 2. Asset data sources (✅ confirmed present 2026-07-12, `_reference\rdr3_discoveries`)

| Catalog | Source folder |
|---|---|
| Peds | `peds/`, `peds_customization/` |
| Objects/props | `objects/` |
| Vehicles/wagons | `vehicles/` |
| Animations | `animations/ingameanims`, `megadictanims`, `kit_emotes_list` |
| Scenarios | `animations/scenarios` |
| Sound | `audio/soundsets`, `frontend_soundsets`, `music_events`, `audio_banks` |
| Particle effects | `graphics/ptfx` |
| Screen effects | `graphics/animpostfx` |
| Weather types | `weather/` |
| Map zones/districts | `zones/` |
| Weapons | `weapons/` |

Data is read as reference data for building our curated catalogs. Individual entries still get spot-verified in-game as catalogs are curated (dumps contain some non-functional entries — known reality).

## 3. Engine patterns

- ✅ Scripted cutscenes: CAM natives (create/point/interp), ped task natives, anim dict loading — standard proven RedM machinima pattern.
- ✅ Custom voice audio: NUI `<audio>` playback of `.ogg` bundled in the resource. Game engine cannot stream arbitrary user audio files.
- ⚠️ Rockstar prerecorded story cutscenes (cutfiles): not reliably exposed in RedM — out of scope (feature list C-F3).
- 🔎 Native ambient ped speech (voice barks) — natives exist; usable line/voice names per ped model need a dev-server spike (C-E3).
- 🔎 NPC outfit/appearance control depth — preset variation vs full component control (C-E5).

## 4. Open spikes (Phase 0 checklist)

| ID | Spike | Blocks |
|---|---|---|
| S1 | Extract exact vorp_core/vorp_inventory export signatures from cloned repos | all VORP integration |
| S2 | Ambient speech native + line names in-game test | C-E3 only |
| S3 | Ped outfit natives test | C-E5 only |
| S4 | PTFX + animpostfx spot test (spawn a few from the dumps) | C-F2 catalog curation |
| S5 | Soundset/music event spot test | C-F2 catalog curation |

## Changelog

- **v0.1 (2026-07-12)** — Initial ledger: VORP surface, asset data inventory, engine patterns, Phase 0 spikes.

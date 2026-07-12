# Sovereign Storyworks — Master Feature List

**Version: 1.0 (LOCKED — owner ruling "Robust V1, no cuts", 2026-07-12)**
**Project phase: Planning — feature list locked; Coding Plan drafted, awaiting owner sign-off**

> Rule: if a behavior isn't in the Approved section, it is NOT approved and will not be coded. New ideas → propose to the owner in plain text → explicit approval → doc update → THEN implement. Changes are versioned in the changelog.

**Legend** — ✅ buildable (verified pattern/data) · 🔎 **spike-conditional**: approved contingent on its Phase 0 spike passing; if the spike fails, the feature auto-defers to V2 and the owner is notified.

## Standing owner rulings (2026-07-12)

1. **Blank-page design.** The prior RC6 prototype is ignored entirely; V1 is designed from scratch.
2. **Hard VORP dependency.** Requires vorp_core; integrates via its exports/events directly. No framework-neutral adapter layer.
3. **Solo V1, party-ready core.** V1 ships solo mission instances; the runtime is architected around a participants list from day one so V2 posse missions extend it without a rewrite. Networked party combat NPCs are V2.
4. **"Society" = job + grade gating only.** No society-treasury integration in V1.
5. **Player journal is in V1.**
6. **Dashboard mockup APPROVED** — `docs/mockups/dashboard_mockup_v1_APPROVED.html` is the visual baseline for all Storyworks NUI.
7. **Robust V1 — no cuts.** The entire candidate list (v0.5) is approved for V1, including the full 13-task roster with escort and defend-area.

---

## 1. Approved features — V1 Release Candidate (40 features)

### A. Builder & Editor

| ID | Feature | Verdict |
|---|---|---|
| A1 | Full no-code visual builder — every task, condition, and value is a form field, dropdown, or in-world capture. Acceptance test: a non-technical staff member builds a working mission unassisted. | ✅ |
| A2 | React + Vite NUI, strict Sovereign County branding per BRANDING.md and the approved dashboard mockup baseline. | ✅ |
| A3 | Node-graph mission canvas — tasks as connected blocks with success/failure branch paths. | ✅ |
| A4 | Mission library — drafts, published, duplicate, archive (oxmysql-backed). | ✅ |
| A5 | In-world capture buttons ("use my current position/heading/camera") throughout every location field. | ✅ |
| A6 | Live draft preview — creator test-runs the unpublished mission privately via the normal runtime in preview mode. | ✅ |
| A7 | Builder access via ACE permissions (`storyworks.builder`, `storyworks.admin`) + optional VORP job gate. | ✅ |

### B. Modular Task System

| ID | Feature | Verdict |
|---|---|---|
| B1 | Modular task engine: each task type is a self-contained runtime module with a declared config schema; the builder renders schemas generically so new task types never require NUI rework. | ✅ |
| B2 | Full 13-task V1 roster: go to location, multi-checkpoint route, talk to NPC, collect/deliver item, search area, eliminate targets, escort NPC, defend area, timed wait, hold-action, player choice, play cutscene, end mission. | ✅ |
| B3 | Per-task failure outcomes: fail branch, retry, mission fail. | ✅ |
| B4 | Task-level rewards and requirements attachable to any node. | ✅ |

### C. Story Logic & Progression

| ID | Feature | Verdict |
|---|---|---|
| C1 | Stories: multi-mission arcs with ordered chapters; chapter unlocks gate on prior completions. | ✅ |
| C2 | Per-character persistent variables, completion history, resume after disconnect (keyed to VORP character ID). | ✅ |
| C3 | Conditions & branching: variables, job/grade, money, gold, XP, items, time of day. | ✅ |
| C4 | Rewards: money, gold, XP, items; requirements optionally consumed. | ✅ |
| C5 | Chance/random branch nodes (server-rolled). | ✅ |

### D. Scheduling, Availability & Access

| ID | Feature | Verdict |
|---|---|---|
| D1 | Time-based missions: daily/weekly/monthly availability + reset cycles; configurable reset hour and week start; time-of-day windows. | ✅ |
| D2 | Job/grade mission access: restrict visibility and start by VORP job(s) + grade range. | ✅ |
| D3 | Repeatability rules: once-ever, once per reset cycle, unlimited. | ✅ |

### E. NPCs, Dialogue & Voice

| ID | Feature | Verdict |
|---|---|---|
| E1 | Branching NPC dialogue: multi-line conversations, per-line speaker, player response choices. | ✅ |
| E2 | Creator-supplied voice files (`.ogg` bundled in resource) played via NUI audio with dialogue lines. | ✅ |
| E3 | Native RDR2 ped speech lines (game voice barks) as alternative to custom files. | 🔎 spike S2 |
| E4 | NPC Maker: model picker, name, behavior (standing/scenario/animation), in-world preview. | ✅ |
| E5 | NPC outfit/appearance variation. | 🔎 spike S3 |

### F. Cutscene Director

| ID | Feature | Verdict |
|---|---|---|
| F1 | Scripted cutscene system: cast roster, timeline of shots, captured cameras, actor animations/movement, dialogue overlays, fades, skip control, full cleanup. | ✅ |
| F2 | Scene dressing: props, weather override, time-of-day override, screen effects (animpostfx), particle effects (ptfx), music stings/soundsets. | ✅ |

*Engine boundary (recorded, not a scope cut): Rockstar's prerecorded story cinematics (cutfiles) are not reliably exposed by RedM and are excluded. Storyworks cutscenes are scripted scenes — the creator's cameras, actors, and NPCs.*

### G. Asset Catalogs

| ID | Feature | Verdict |
|---|---|---|
| G1 | Searchable in-builder catalogs: peds, objects/props, vehicles/wagons, animations, scenarios, soundsets/music, particle effects, screen effects. Server-side paginated search, friendly names, categories, tags. | ✅ |
| G2 | In-world asset preview (spawn ped/prop, audition animation/sound). | ✅ |
| G3 | Server-custom catalog additions via config JSON. | ✅ |

### H. Random Encounters

| ID | Feature | Verdict |
|---|---|---|
| H1 | Encounter director: missions tagged "encounter" + spawn rules (zones or map-wide, chance, min player distance, cooldown, max concurrent); server rolls and offers, client spawns on proximity, guaranteed cleanup. | ✅ |
| H2 | Encounter zones captured in-world; named-district targeting via zone data. | ✅ |

### I. Integration & External Scripts

| ID | Feature | Verdict |
|---|---|---|
| I1 | Integration surface: exports/events (start mission, query progress, completion events) + external action registry — another resource registers a named action that appears as a no-code task block in the builder. | ✅ |
| I2 | Discord webhook logging: mission published, completed, rewards granted. | ✅ |

### J. Portability

| ID | Feature | Verdict |
|---|---|---|
| J1 | Import/export missions and stories as versioned JSON; import as new draft, never overwriting; full server-side validation/sanitization of imported content (untrusted input). | ✅ |

### K. Player Experience

| ID | Feature | Verdict |
|---|---|---|
| K1 | On-screen objective tracker (current task, progress, distance) — minimal branded HUD. | ✅ |
| K2 | Map blips/waypoints for active objectives, cleaned up on task/mission end. | ✅ |
| K3 | Player mission journal — browse available/active/completed missions and reset timers; start eligible missions (owner-endorsed for V1, ruling #5). | ✅ |

### L. Ops & Safety Rails

| ID | Feature | Verdict |
|---|---|---|
| L1 | Fully configurable systems: split config files for limits, timers, permissions, encounter density, reset hours, webhook URLs. Zero magic numbers in code. | ✅ |
| L2 | Server-side validation + rate limiting on every builder/runtime callback. | ✅ |
| L3 | Locale system for all player-facing text (`locales/en.lua`, `T(key)`). | ✅ |

---

## 2. Candidate features

*Empty — list locked at v1.0. New proposals go here pending owner approval.*

## 3. Rejected / deferred (V2 and beyond)

- **Party/posse missions with networked combat NPCs** — V2 (ruling #3; V1 core is architected participants-first to receive it).
- **Society treasury integration** (rewards from/into job funds) — V2 candidate (ruling #4).
- **Rockstar prerecorded cinematics** — engine boundary, excluded outright (see F block note).

---

## Changelog

- **v1.0 (2026-07-12)** — LIST LOCKED. Owner ruling #7 "Robust V1, no cuts": all 40 candidates approved with permanent IDs; E3/E5 spike-conditional; F3 recorded as engine boundary; deferred section populated.
- **v0.5 (2026-07-12)** — Dashboard mockup approved (ruling #6); GitHub repository connected.
- **v0.4 (2026-07-12)** — Rulings: solo V1/party-ready core, society = job+grade only, journal in V1.
- **v0.3 (2026-07-12)** — Owner's 15-point list decomposed into categories with buildability verdicts; asset data + VORP API verified.
- **v0.2 (2026-07-12)** — Rulings: blank-page design, hard VORP dependency.
- **v0.1 (2026-07-12)** — Initial planning skeleton.

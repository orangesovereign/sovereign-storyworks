# Sovereign Storyworks — Coding Plan & Roadmap

**Version: 0.1 (DRAFT — awaiting owner sign-off; coding does not begin until this document is approved)**
**Scope: Master Feature List v1.0 (40 approved features, rulings #1–7)**

## How this plan works (plain language)

The build is split into eleven phases. Each phase ends with an **exit gate**: a testing checklist the owner (or a helper) runs on the dev server, plus a pasted-console review. **The next phase never starts until the gate passes.** Every phase delivers its checklist in `docs/testing/` written for a non-developer. Claude cannot run a RedM server, so the loop is always: Claude writes → owner deploys → owner pastes server console + F8 output → Claude fixes.

**Definition of done, every phase:** locales ✓ · config-driven (no magic numbers) ✓ · server-validated + rate-limited ✓ · clean migrations on fresh AND existing DBs ✓ · RedM-native-only verified ✓ · testing checklist delivered ✓ · exit gate passed by owner ✓.

**Build order logic:** runtime before builder. Phases 1–4 build the mission engine and prove it with hand-authored test missions; the builder NUI (Phases 5–7) then gets built against a *stable* task vocabulary, so its forms never need reworking mid-project. The visible-progress tradeoff is called out honestly: the owner sees console-driven demos before pretty screens.

---

## Phase 0 — Foundations & Spikes *(tag: none)*

**Features prepared:** L1, L2, L3 scaffolding; TECH_SPEC spikes S1–S5.

- Resource skeleton: `fxmanifest.lua` (lua54, RedM prerelease acknowledgment line), folder structure doc, split config files, `locales/en.lua`, DB migration runner, tagged logging.
- S1: extract exact vorp_core / vorp_inventory-v2 export signatures from the cloned reference repos into TECH_SPEC (verbatim).
- Owner dev-server spikes: S2 native ped speech, S3 outfit natives, S4 ptfx/animpostfx spot test, S5 soundset/music spot test. Results recorded; E3/E5 confirmed or auto-deferred per the feature list rule.
- **Exit gate:** resource boots clean on the dev server, tables migrate on a fresh DB, all five spike results recorded in TECH_SPEC.

## Phase 1 — Mission Runtime Core *(tag: v0.1-alpha)*

**Features:** B1 (engine), B3, parts of C2 (persistence/resume), L2.

- Server-authoritative mission-instance engine, **architected around a participants list from day one** (ruling #3) even though V1 fills it with one player.
- Task-module contract (schema declaration, start/tick/complete/fail/cleanup lifecycle).
- First two task modules to prove the loop: *go to location*, *end mission*. Success/failure edges.
- Persistence: instance state survives disconnect/reconnect and resource restart. Admin test commands (`/swstart`, `/swcancel`).
- **Exit gate:** a hand-authored JSON test mission runs end-to-end on the dev server, survives a reconnect mid-mission, and cleans up on cancel.

## Phase 2 — Task Vocabulary I: Movement & Interaction *(tag: v0.2-alpha)*

**Features:** B2 (7 of 13), B4, E1, E2, K1, K2.

- Tasks: multi-checkpoint route, talk to NPC, collect/deliver item, search area, timed wait, hold-action, player choice.
- Branching dialogue runtime (E1) with NUI voice audio (E2). Objective tracker HUD (K1) and blips (K2) — both to the approved visual baseline.
- **Exit gate:** owner-run checklist covering each task type solo and chained, dialogue with choices and voice file, tracker/blips correctness.

## Phase 3 — Task Vocabulary II: Combat & NPC Operations *(tag: v0.3-alpha)*

**Features:** B2 (remaining combat tasks), E4 core, E5 (if spike passed).

- Mission-NPC lifecycle manager (spawn, behavior, guaranteed cleanup on every exit path — the single most bug-prone area, isolated deliberately).
- Tasks: eliminate targets (aggressive + non-aggressive hunting), escort NPC (separation, mortal/protected), defend area (timed, waves).
- **Exit gate:** combat checklist including the ugly paths — dying mid-escort, disconnecting mid-defend, cancelling mid-fight — with zero orphaned NPCs.

## Phase 4 — Story Logic, Progression & Scheduling *(tag: v0.4-alpha)*

**Features:** C1–C5, D1–D3, B4 completion.

- Variables, conditions, chance nodes; requirements/rewards through VORP (money, gold, XP, items — S1 signatures).
- Stories/chapters with unlock gating (C1); completion history (C2); daily/weekly/monthly cycles with configurable resets (D1); job/grade gating (D2); repeatability (D3).
- **Exit gate:** a hand-authored three-chapter story with rewards, job gate, and a daily side mission passes a scripted checklist including reset-boundary tests.

## Phase 5 — Builder NUI I: Shell, Library & Canvas *(tag: v0.5-beta)*

**Features:** A1–A5, A7, J1 (draft persistence layer).

- React/Vite app to the approved mockup baseline: masthead, nav (Registry/Craft/Office), dashboard with live stats and dispatches.
- Mission library (A4), node-graph canvas (A3), schema-driven task property forms (A1/B1 payoff), in-world capture (A5), publish/validate flow, ACE-gated access (A7).
- **Exit gate:** the owner personally builds and publishes a multi-task mission start-to-finish **without touching a file or command** — the A1 acceptance test.

## Phase 6 — Builder NUI II: Catalogs, NPC Maker & Dialogue Builder *(tag: v0.6-beta)*

**Features:** G1–G3, E4 UI, E1 builder UI, E3 (if spike passed).

- Curated searchable catalogs (peds, props, vehicles, animations, scenarios, sound, ptfx, animpostfx) with server-side pagination, favorites, in-world preview (G2), custom catalog JSON (G3).
- NPC Maker UI; visual dialogue builder with branching.
- **Exit gate:** owner builds an NPC conversation mission with catalog-picked assets and previews; catalog search stays responsive with full datasets.

## Phase 7 — Cutscene Director *(tag: v0.7-beta)*

**Features:** F1, F2, B2 cutscene task.

- Timeline editor (cast, shots, captured cameras, animations, movement, dialogue, fades) and playback runtime with skip + total cleanup; scene dressing (props, weather, time, ptfx, animpostfx, sound).
- **Exit gate:** owner authors a three-shot scene with dressing and plays it inside a mission; skip and cleanup verified.

## Phase 8 — Player Journal & Live Preview *(tag: v0.8-beta)*

**Features:** K3, A6.

- Player journal NUI (available/active/completed/locked, reset timers, start/replay). Builder live-preview mode (A6) wired through the finished runtime.
- **Exit gate:** journal checklist across a mixed catalog of missions; preview runs a draft privately without touching real progression.

## Phase 9 — Encounters, Integration & Portability *(tag: v0.9-beta)*

**Features:** H1, H2, I1, I2, J1 completion.

- Encounter director (spawn rules, zones, density guardrails, cleanup); external action registry + exports/events (I1); webhooks (I2); import/export with full sanitization (J1).
- **Exit gate:** encounters spawn/resolve/expire correctly under the density limits; a second resource successfully registers an action and starts a mission via export; an exported mission imports clean on a fresh DB.

## Phase 10 — Hardening & Release *(tag: v1.0-rc, then v1.0)*

- Full L2 audit (every callback validated + rate-limited), load/perf pass, locale completeness sweep, migration test on fresh + existing DBs, README + owner's guide, final testing checklist covering all 40 features.
- **Exit gate:** the complete V1 acceptance checklist passes on the dev server; owner declares v1.0.

---

## Risk register

| # | Risk | Mitigation |
|---|---|---|
| R1 | Escort/defend NPC edge cases (the classic RedM tarpit) | Isolated in Phase 3 behind the NPC lifecycle manager; ugly-path exit gate |
| R2 | Spike failures kill E3/E5 | Auto-defer rule already in the feature list; nothing else depends on them |
| R3 | Catalog curation volume (thousands of raw entries) | Ship curated starter sets per category + G3 custom JSON; curation is data work, spread across Phases 0–6 |
| R4 | Encounter density hurting server perf | Config guardrails (max concurrent, min distance, cooldowns) are L1 features, not afterthoughts; load pass in Phase 10 |
| R5 | Import as attack vector | J1 sanitization specified from day one; treated as untrusted input, gate-tested in Phase 9 |
| R6 | Task schema churn forcing NUI rework | Runtime-first build order; schemas frozen at the end of Phase 4 — additions after that need owner approval |
| R7 | Long stretch without visible UI (Phases 1–4) | Named tradeoff; console demos + owner checklists keep progress tangible; mockup already sets the visual target |

## Changelog

- **v0.1 (2026-07-12)** — Initial draft against Master Feature List v1.0. Awaiting owner sign-off.

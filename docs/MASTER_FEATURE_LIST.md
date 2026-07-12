# Sovereign Storyworks — Master Feature List

**Version: 0.5 (PLANNING DRAFT — features below are not yet approved; see standing rulings for what is)**
**Project phase: Planning / Design / Feature Brainstorm**

> Rule (carried over from the Medical Suite): a feature is only APPROVED when the owner (Wilbur) explicitly approves it in plain text. Approved features get an ID and move to the Approved section. If a behavior isn't in the Approved section, it is NOT approved and will not be coded.

**Buildability legend** — every candidate carries a verdict:
- ✅ **Buildable** — proven pattern in RedM/VORP; supporting data or API verified in the reference repos.
- 🔎 **Spike needed** — buildable in principle; a specific native/API must be verified on the dev server before the feature is locked.
- ⚠️ **Constraint** — buildable only in a reduced form; the limitation is stated and the owner must accept it.

## Standing owner rulings (2026-07-12)

1. **Blank-page design.** The prior RC6 prototype is ignored entirely; V1 is designed from scratch.
2. **Hard VORP dependency.** Requires vorp_core; integrates via its exports/events directly. No framework-neutral adapter layer.
3. **Solo V1, party-ready core.** V1 ships solo mission instances (with synced cutscene audiences as a candidate), but the runtime is architected around a participants list from day one so V2 posse missions extend it without a rewrite. Networked party combat NPCs are V2.
4. **"Society" = job + grade gating only.** Mission visibility/start restricted by VORP job(s) and grade range; no society-treasury integration in V1.
5. **Player journal is in V1** (C-K3 endorsed) — players browse available/active/completed missions and reset timers, and start eligible ones from a branded NUI.
6. **Dashboard mockup APPROVED** (July 12, 2026) — `docs/mockups/dashboard_mockup_v1_APPROVED.html` is the visual baseline for all Storyworks NUI (ledger window, filigree, Registry/Craft/Office nav, stat tiles, reset strip, mission ledger, telegram dispatches).

---

## 1. Approved features (V1 Release Candidate)

*None yet — awaiting brainstorm rulings.*

---

## 2. Candidate features (brainstorm parking lot — NOT approved)

Candidates carry temporary `C-x.y` numbers for discussion only; real feature IDs are assigned at approval. Items marked **(owner)** come from the owner's initial list (2026-07-12); items marked **(proposed)** are Claude's supporting proposals — infrastructure the owner's features imply, surfaced for explicit approval rather than smuggled in.

### A. Builder & Editor — the creator's NUI

| # | Candidate | Verdict | Notes |
|---|---|---|---|
| C-A1 | Full no-code visual builder — nobody writes a line of code to make a mission **(owner)** | ✅ | Governing design principle. Every task, condition, and value is a form field, dropdown, or in-world capture. Acceptance test: a non-technical staff member builds a working mission unassisted. |
| C-A2 | React + Vite NUI, strict Sovereign County branding **(owner)** | ✅ | Same pipeline as sovereign_mdt: source in `ui/src/`, committed `ui/dist/` bundle, zero CDN, bundled fonts. |
| C-A3 | Node-graph mission canvas — tasks as connected blocks with branch paths **(proposed)** | ✅ | The natural surface for C-B1 modular tasks. Pure frontend work. |
| C-A4 | Mission library — drafts, published, duplicate, archive **(proposed)** | ✅ | oxmysql-backed, `sovereign_` tables. |
| C-A5 | In-world capture: "use my current position/heading/camera" buttons throughout **(proposed)** | ✅ | Standard NUI-callback → client native reads. Removes all coordinate typing — load-bearing for C-A1. |
| C-A6 | Live draft preview — creator test-runs the unpublished mission privately **(proposed)** | ✅ | Runs the normal runtime flagged as preview. |
| C-A7 | Builder access via ACE permission + optional VORP job gate **(proposed)** | ✅ | `storyworks.builder` / `storyworks.admin`. |

### B. Modular Task System — the building blocks

| # | Candidate | Verdict | Notes |
|---|---|---|---|
| C-B1 | Robust modular task system: chain/branch any task types to compose nearly any mission **(owner)** | ✅ | The architectural core. Each task type = one self-contained runtime module with a declared config schema; the builder renders schemas generically, so new task types never require NUI rework. |
| C-B2 | Starter task set: go to location, multi-checkpoint route, talk to NPC, collect/deliver item, search area, eliminate targets, escort NPC, defend area, timed wait, hold-action, player choice, play cutscene, end mission **(proposed)** | ✅ | Each individually proven in RedM. Exact V1 roster is an owner call — this is the menu. |
| C-B3 | Per-task failure outcomes (fail branch, retry, mission fail) **(proposed)** | ✅ | Graph edges: success path / failure path. |
| C-B4 | Task-level rewards and requirements (see C-C block) attached to any node **(proposed)** | ✅ | |

### C. Story Logic & Progression

| # | Candidate | Verdict | Notes |
|---|---|---|---|
| C-C1 | Advanced, complete story system — multi-mission arcs with chapters **(owner)** | ✅ | Missions group into stories; stories order by chapter; chapter unlocks gate on prior completions. |
| C-C2 | Story & progression support: per-character persistent variables, completion history, resume after disconnect **(owner)** | ✅ | Server-side state in oxmysql keyed to VORP character ID (not player ID — respects multi-character). |
| C-C3 | Conditions & branching: compare variables, check job/grade, money, gold, XP, items, time of day **(proposed)** | ✅ | Job/grade/money/gold/XP confirmed on VORP's character class; items via vorp_inventory exports. |
| C-C4 | Rewards: money, gold, XP, items; requirements optionally consumed **(proposed)** | ✅ | Same verified API surface. |
| C-C5 | Chance/random branch nodes **(proposed)** | ✅ | Server-rolled. |

### D. Scheduling, Availability & Access

| # | Candidate | Verdict | Notes |
|---|---|---|---|
| C-D1 | Time-based missions: daily / weekly / monthly availability and reset cycles **(owner)** | ✅ | Server clock is authority; per-character cooldown rows; configurable reset hour and week start. Also covers "only available 6pm–6am game time" style windows if wanted. |
| C-D2 | Job/Society mission access: restrict who can see/start a mission by VORP job + grade range **(owner)** | ✅ | Job + grade live on the character object. **Open question for owner:** does "society" mean anything beyond job-gating (e.g. society funds paying rewards)? |
| C-D3 | Repeatability rules: once-ever, once per reset cycle, unlimited **(proposed)** | ✅ | |

### E. NPCs, Dialogue & Voice

| # | Candidate | Verdict | Notes |
|---|---|---|---|
| C-E1 | Dynamic NPC dialogue: multi-line branching conversations, per-line speaker, player response choices **(owner)** | ✅ | NPC spawning, freezing, scenario idle — all standard RedM natives. Dialogue UI in NUI. |
| C-E2 | Voice audio support: creator-supplied voice files play with dialogue lines **(owner)** | ✅ | Via NUI audio playback (`.ogg` bundled in the resource) — the proven RedM pattern, since the game engine cannot stream arbitrary user files natively. |
| C-E3 | Native RDR2 ped speech lines (game's own voice barks) as an alternative to custom files **(proposed)** | 🔎 | RDR3 ambient-speech natives exist; usable line names per ped need a dev-server spike before this is promised. |
| C-E4 | NPC Maker: model picker, name, behavior (standing/scenario/animation), in-world preview **(proposed)** | ✅ | Ped model list in rdr3_discoveries/peds. |
| C-E5 | NPC outfit/appearance variation | 🔎 | Random preset variation via native outfit natives is likely; full custom clothing needs a spike against peds_customization data. Flagged now so it doesn't become a silent promise. |

### F. Cutscene Director

| # | Candidate | Verdict | Notes |
|---|---|---|---|
| C-F1 | Advanced story cutscene system: cast, timeline of shots, captured cameras, actor animations/movement, dialogue overlays, fades **(owner)** | ✅ | Scripted-camera cutscenes (machinima style) are fully supported: CAM natives, ped tasking, anim dicts from rdr3_discoveries. |
| C-F2 | Scene dressing: props, weather override, time-of-day override, screen effects (animpostfx), particle effects (ptfx), music stings/soundsets **(proposed)** | ✅ | All six categories have verified data dumps in rdr3_discoveries; natives are standard. Individual catalog entries still get spot-verified as catalogs are curated. |
| C-F3 | Playing Rockstar's own prerecorded story cutscenes | ⚠️ | Not reliably exposed in RedM — **excluded from scope.** Our cutscenes are scripted scenes built from cameras + actors, which is what every RedM cutscene tool does. Owner must accept this boundary. |

### G. Asset Catalogs — "hundreds of game assets"

| # | Candidate | Verdict | Notes |
|---|---|---|---|
| C-G1 | Searchable in-builder catalogs: peds, objects/props, vehicles/wagons, animations, scenarios, soundsets/music, particle effects, screen effects **(owner)** | ✅ | Source data confirmed present in rdr3_discoveries (read as data, not copied code). Work is curation: friendly names, categories, tags, server-side paginated search. |
| C-G2 | In-world asset preview (spawn the ped/prop in front of the creator, audition the animation/sound) **(proposed)** | ✅ | |
| C-G3 | Server-custom catalog additions via config JSON **(proposed)** | ✅ | Lets the owner add streamed custom assets without code. |

### H. Random Encounters

| # | Candidate | Verdict | Notes |
|---|---|---|---|
| C-H1 | Random encounter missions dynamically spawning across the map, fully configurable **(owner)** | ✅ | Design: encounters are normal built missions tagged "encounter" + spawn rules (zones or anywhere, chance, min player distance, cooldown, max concurrent). Server rolls and offers; client spawns on proximity. Needs careful cleanup + density guardrails, standard engineering. |
| C-H2 | Encounter zones drawn/captured in-world **(proposed)** | ✅ | Zone data also available in rdr3_discoveries for named-district targeting. |

### I. Integration & External Scripts

| # | Candidate | Verdict | Notes |
|---|---|---|---|
| C-I1 | Integration support for external scripts **(owner)** | ✅ | Two directions: exports/events others call (start mission, query progress, completion events) + an **external action registry** — another resource registers a named action and it appears as a no-code task block in the builder. |
| C-I2 | Discord webhook logging (mission published, completed, rewards granted) **(proposed)** | ✅ | Same pattern as Medical Suite webhooks. |

### J. Portability

| # | Candidate | Verdict | Notes |
|---|---|---|---|
| C-J1 | Import/export missions and stories as portable files — share with other creators/servers **(owner)** | ✅ | JSON export with schema version; import as new draft, never overwriting; **server-side validation/sanitization of every imported field** (imports are untrusted input). |

### K. Player Experience

| # | Candidate | Verdict | Notes |
|---|---|---|---|
| C-K1 | On-screen objective tracker (current task, progress, distance) **(proposed)** | ✅ | Minimal branded HUD element. |
| C-K2 | Map blips/waypoints for active objectives **(proposed)** | ✅ | |
| C-K3 | Player mission journal — browse available/active/completed missions, start eligible ones **(proposed)** | ✅ | Natural home for C-D1 daily/weekly visibility. Owner call on V1 vs later. |

### L. Ops & Safety rails

| # | Candidate | Verdict | Notes |
|---|---|---|---|
| C-L1 | Fully configurable systems **(owner)** | ✅ | Split config files: limits, timers, permissions, encounter density, reset hours, webhook URLs. Zero magic numbers in code (standing rule). |
| C-L2 | Server-side validation + rate limiting on every builder/runtime callback **(proposed)** | ✅ | Standing rule made explicit as a feature so it's planned, not hoped for. |
| C-L3 | Locale system for all player-facing text **(proposed)** | ✅ | Standing rule. |

---

## 3. Explicitly rejected / deferred

- **C-F3 scope boundary:** playback of Rockstar's prerecorded story cutscenes — excluded (engine limitation), pending owner acknowledgment.

---

## Open rulings requested from owner

1. **C-B2 starter task roster** — which task types make the V1 cut.
2. **C-F3 boundary acknowledgment** — confirm acceptance that cutscenes are scripted scenes (cameras + actors), not Rockstar's prerecorded story cutscenes.
3. **Full-list approval pass** — every remaining candidate needs an approve/cut/defer ruling before the Coding Plan is authored.

## Changelog

- **v0.5 (2026-07-12)** — Dashboard mockup approved by owner (standing ruling #6); GitHub repository connected (orangesovereign/sovereign-storyworks).
- **v0.4 (2026-07-12)** — Owner rulings recorded: solo V1 with party-ready core (party play V2), society = job+grade gating only, player journal endorsed for V1. Open rulings narrowed to task roster, cutscene boundary, and the full approval pass.
- **v0.3 (2026-07-12)** — Owner's 15-point initial list decomposed into 12 categories with buildability verdicts; asset data and VORP API surface verified against reference repos; supporting proposals added for explicit approval; open rulings listed.
- **v0.2 (2026-07-12)** — Owner rulings: blank-page design, hard VORP dependency, multiplayer tabled.
- **v0.1 (2026-07-12)** — Initial planning skeleton.

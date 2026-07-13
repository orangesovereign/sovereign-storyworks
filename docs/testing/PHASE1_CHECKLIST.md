# Phase 1 Testing Checklist — Mission Runtime Core

> **The live checklist is the interactive Exit-Gate Ledger:**
> **https://claude.ai/code/artifact/7d752125-622f-43f6-a0ef-5b81cfeb877e**
> This file is the plain-text mirror kept in the repo for the permanent record.

**Written for:** anyone — no developer knowledge needed.
**What you need:** the dev server with the Phase 1 build deployed, admin rights, ~20 minutes.
**What to send back:** server console from boot, chat/notification observations, PASS/FAIL/WEIRD per line.

## 1. Boot & seeding

| # | Check | Expect |
|---|---|---|
| B1 | Server console at startup | `booting (Phase 1 — Mission Runtime Core)` → `vorp_core connected.` → `applying migration 2 (phase1_runtime_core)... migration 2 applied.` → `database ready.` → `seeded mission from data/test_mission.json` (and `_fail.json`) → `2 published mission(s) loaded.` → `runtime ready — task types: end, goto` → `boot complete.` |
| B2 | MySQL: tables `sovereign_missions` (2 rows), `sovereign_mission_instances`, `sovereign_instance_participants` exist | |
| B3 | `restart sovereign_storyworks` | migration 2 NOT re-applied; missions re-seed without duplicating rows (still 2) |

## 2. The happy path

| # | Check | Expect |
|---|---|---|
| H1 | In game (admin): `/swmissions` | lists `phase1_test — The Courier's First Ride` and `phase1_test_fail — The Impossible Deadline` |
| H2 | `/swstart phase1_test` | "Mission started" notification + objective text: head to the point ~60m ahead of where you stood |
| H3 | Walk ~60m in the direction you were FACING at start | "You have arrived." → new objective: return to where you began |
| H4 | Walk back | "You have arrived." → mission-complete notification with the courier closing line |
| H5 | MySQL: the instance row | status `completed`, `finished_at` set |

## 3. The failure edge (B3)

| # | Check | Expect |
|---|---|---|
| F1 | `/swstart phase1_test_fail`, then just stand there ~15s | "Too slow — the moment has passed." → mission FAILED notification with the tongue-in-cheek closing line |
| F2 | MySQL: that instance row | status `failed` |

## 4. Cancel & guards

| # | Check | Expect |
|---|---|---|
| C1 | `/swstart phase1_test`, then `/swcancel` | "Mission cancelled." notification; instance row status `cancelled` |
| C2 | `/swstart phase1_test` twice | second attempt: "You already have an active mission" (then `/swcancel` to clean up) |
| C3 | `/swstart nonsense` | "No published mission carries that code." |
| C4 | As NON-admin: `/swstart phase1_test` | permission denial, nothing starts |

## 5. Persistence — the heart of the gate

| # | Check | Expect |
|---|---|---|
| P1 | `/swstart phase1_test`, complete leg 1 (arrive at the 60m point), then DISCONNECT. Server console | `instance N parked (char X disconnected)` |
| P2 | Reconnect, pick the same character | "Mission resumed" notification + the LEG 2 objective (return to start) — not leg 1 again |
| P3 | Walk to the original start point | mission completes normally |
| P4 | `/swstart phase1_test`, complete leg 1, then `restart sovereign_storyworks` (or full server restart) | console: `1 active instance(s) restored, awaiting their players.` |
| P5 | Rejoin (or reselect character) after that restart | "Mission resumed" on leg 2; completing it works |
| P6 | While on a mission, have the ONLY participant disconnect, then look at MySQL | instance stays `active`, `current_node` and `state` populated — nothing lost |

## 6. Sign-off

Exit gate: the hand-authored mission runs end-to-end (§2), the failure edge fires (§3), cancel cleans up (§4), and the mission survives BOTH a reconnect and a resource restart mid-mission (§5). Owner rules the gate → tag `v0.1-alpha` → Phase 2 (Task Vocabulary I).

---

## Test log

### Round 1 — 2026-07-12 (owner)

- **ART II items 3–4:** "You have arrived" never fired — walked forever. Root cause: the leg-1 target derived its direction from SERVER-side heading (unreliable — recorded as a ⚠️ rule in TECH_SPEC), compounded by there being no map marker until Phase 2, making a blind 4m circle unhittable. **Fix (rev 2):** the courier route is now direction-free — leg 1 completes at ≥60m from start in ANY direction; both legs get ~8s distance callouts (`goto_progress_*`); return radius widened to 6m with a vertical allowance. Heading-based "relative forward" targets removed from the goto task entirely.
- **ART V:** blocked by the above; retest in round 2.
- Ticked without notes (= confirmed): ART I boot/tables/reseed, ART II items 1–2 (/swmissions, mission start + objective), ART III failure edge, ART IV cancel & guards.

### Round 2 — 2026-07-12 (owner)

- **ART II items 2–4:** mission COMPLETED end-to-end (engine + direction-free route work), but: 8s callouts too sparse (owner: make it 2s); "You have arrived" and the leg-2 "turn back" objective never displayed — only the ledger told the tester what to do. Diagnosis: VORP's objective/bottom-tip channel never rendered; the right-tip channel (the callouts) worked throughout; same-moment messages on one channel swallow each other.
- **Fixes (rev 3):** callouts every 2s (config); ALL runtime messages moved to the right-tip channel; objectives prefixed "NEW OBJECTIVE —" and announced ~1.5s after the completion tip (config delay); channel finding recorded in TECH_SPEC. Stock channels retire entirely when K4 ships (ruling #9).
- Note: the mission-complete full screen the owner saw (and dislikes) is exactly what K4 replaces in Phase 2.

### Round 3 — 2026-07-12 (owner)

- **ART II rev-3 retest: "Worked as expected."** 2s callouts, arrival tip, NEW OBJECTIVE announcement, completion — the courier route is fully green.
- Owner reaffirmed (with feeling): the stock notification system goes **in its entirety** — ruling #9 wording strengthened; K4 replaces every channel, right-tips included.

### Remaining for the gate: ART V (persistence — disconnect/reconnect + resource restart), then the owner's ruling.

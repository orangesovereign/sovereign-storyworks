# Phase 0 Testing Checklist — Foundations & Spikes

**Written for:** anyone — no developer knowledge needed.
**What you need:** the dev server with `oxmysql` and `vorp_core` running, admin rights, and 15 minutes.
**What to send back to Claude:** the full server console output from resource start, plus your F8 console lines for each spike, plus a PASS/FAIL/WEIRD note per item below.

## 1. Install

1. Copy the `sovereign_storyworks` folder into the server's `resources` directory.
2. Add to `server.cfg` (after `ensure oxmysql` and `ensure vorp_core`):
   ```cfg
   ensure sovereign_storyworks
   add_ace group.admin storyworks.admin allow
   add_ace group.admin storyworks.builder allow
   ```
3. Restart the server (or `refresh` + `ensure sovereign_storyworks`).

## 2. Boot & database gate

| # | Check | Expect | Result |
|---|---|---|---|
| B1 | Server console at startup | `[sovereign_storyworks] Sovereign Storyworks 0.0.1-phase0 booting...` then `vorp_core connected.` | |
| B2 | Migration lines | `applying migration 1 (phase0_foundations)... migration 1 applied. database ready.` | |
| B3 | `boot complete` line appears, **no red ERROR lines** | | |
| B4 | In your MySQL tool: tables `sovereign_storyworks_migrations` and `sovereign_storyworks_kv` exist | | |
| B5 | Restart the resource (`restart sovereign_storyworks`) | boots again **without** re-applying migration 1 | |

## 3. Spikes (in-game, as admin)

Type each command in chat. Watch the F8 console (`F8`) for `[sovereign_storyworks] [spike]` lines — those lines tell you exactly what to look for. Run `/swspike cleanup` between tests.

| # | Command | What should happen | Result |
|---|---|---|---|
| S0 | `/swspike ped` | A townsfolk ped appears ~2.5m ahead, fully visible (not invisible/frozen in T-pose) | |
| S2 | `/swspike speech` | The ped **audibly speaks** a voice line | |
| S3 | `/swspike outfit` | The ped's body/clothing visibly changes | |
| S4 | `/swspike ptfx` | A smoke cloud effect appears on the ped | |
| S4b | `/swspike postfx` | The whole screen gets a visual effect for ~5 seconds, then clears | |
| S5 | `/swspike sound` | You **hear an alarm bell** ringing just ahead of you | |
| S6a | `/swspike carriable` | A wooden crate appears; walking to it shows a **pick-up prompt**; you can carry it, drop it, and try stowing it on your horse | |
| S6b | While carrying the crate: `/swspike place` | Your character physically **sets the crate down** ahead with an animation | |
| S6c | `/swspike attach` | A crate sticks to your torso (no animation — expected); F8 says PASSES or FAILED | |
| SC | `/swspike cleanup` | Every spike ped/crate/effect disappears | |
| SP | As a NON-admin player: `/swspike ped` | "You do not have permission to do that." and nothing spawns | |
| SR | Spam `/swspike ped` 13+ times fast (as admin) | "Slow down" message kicks in | |

## 4. What the results decide

- **S2 fails** → feature E3 (game voice barks) auto-defers to V2. Custom voice files (E2) are unaffected.
- **S3 fails** → feature E5 (NPC outfits) auto-defers to V2.
- **S4/S4b/S5 fail** → those catalog categories get trimmed; core cutscenes unaffected.
- **S6a+S6b pass** → physical carry (B5/B6) uses the game's native carry system. **S6a fails but S6c passes** → B5/B6 use the attach fallback. Both failing would be genuinely surprising — paste everything.

## 5. Sign-off

Phase 0 exit gate passes when: B1–B5 all pass, every spike has a recorded result (pass OR fail — fails are information, not blockers), and the results are written into TECH_SPEC. Then Phase 1 (Mission Runtime Core) begins.

---
*Log (owner fills in):*

- Date tested:
- Tested by:
- Server build:
- Notes:

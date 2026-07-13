# Sovereign Storyworks — Tech Spec & Verification Ledger

**Version: 0.1 (PLANNING DRAFT)**

> Rule: only ✅ items may be used in code. 🔎 items must be verified (repo grep or dev-server spike) before any feature depending on them is coded. ⚠️ items are accepted constraints.

## 1. VORP Core surface — S1 COMPLETE (extracted verbatim from reference repos, 2026-07-12)

### vorp_core (`exports.vorp_core:GetCore()` → CoreFunctions, `server/apicontroller.lua`)

- ✅ `Core.getUser(source)` → user or nil; character via `user.getUsedCharacter`.
- ✅ `Core.getUserByCharId(charid)` → user or nil (our persistence is keyed by charIdentifier; this maps back to a live player).
- ✅ Character fields: `identifier`, `charIdentifier`, `group`, `job`, `jobgrade`, `joblabel`, `firstname`, `lastname`, `money`, `gold`, `rol`, `xp`, `isdead`, `source`, `multiJobs`.
- ✅ Character methods (`server/class/character.lua`): `character.addCurrency(currency, quantity)` / `character.removeCurrency(currency, quantity)` — currency: 0=money, 1=gold, 2=rol; `character.addXp(quantity)`; `character.setJob(newjob)`; `character.Job(value)`, `character.Jobgrade(value)`, `character.Group(value)` (getter/setter style).
- ⚠️ **`character.removeXp(quantity)` is BUGGY in vorp_core** (assigns `self.Xp` instead of `self.xp`, `character.lua:401-405`) — never use it; XP deduction goes through `addXp(-quantity)`.
- ✅ Notifications: `Core.NotifyTip/NotifyLeft/NotifyRightTip/NotifyObjective/NotifyTop/NotifyAvanced/...(source, ...)` — full annotated list at `apicontroller.lua:1-34`.
- ✅ Callbacks: `Core.Register(name, callback)`, `Core.TriggerAwait(name, source, ...)`.
- ✅ Webhook: `Core.AddWebhook(title, webhook, description, color, name, logo?, footerlogo?, avatar?)`.
- ✅ Job change events to listen on: `vorp:playerJobChange(source, newJob, oldJob)`, `vorp:playerJobGradeChange(source, newGrade, oldGrade)`.
- Legacy `vorp:addMoney`-style events (`old_api.lua`) exist but are deprecated — **not used**.

### vorp_inventory-v2 (direct exports, `server/services/inventoryApiService.lua`)

- ✅ `exports.vorp_inventory:addItem(source, name, amount, metadata, cb, allow, degradation, percentage)`
- ✅ `exports.vorp_inventory:subItem(source, name, amount, metadata, cb, allow, percentage)`
- ✅ `exports.vorp_inventory:getItemCount(source, cb, itemName, metadata, percentage)`
- ✅ `exports.vorp_inventory:canCarryItem(source, itemName, amount, cb)` (+ `canCarryItems` for weight-amount checks)
- ✅ `exports.vorp_inventory:registerUsableItem(name, cb, resource)` / `unRegisterUsableItem(name)`
- ✅ `exports.vorp_inventory:getItemByName(...)`, `getItemDB(...)` for item existence validation at mission-publish time.

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
- ✅ **Native ambient ped speech WORKS (S2 PASSED, owner round 1, 2026-07-12)** — `PLAY_AMBIENT_SPEECH1` 0x8E04FEDD28D42462 via DataView struct (audio_banks README pattern); E3 confirmed for V1. Voice line catalogs sourced from `audio/audio_banks`.
- ✅ **Soundsets WORK (S5 PASSED, round 1)** — load 0xD9130842D7226045, `PLAY_SOUND_FROM_POSITION` 0xCCE219C922737BFA, release 0x531A78D6BF27014B.
- ✅ **Looped ptfx + animpostfx WORK (S4 PASSED, round 1)** — the ptfx_assets_looped / animpostfx native sets as coded in the spike harness.
- ✅ **NPC outfit control WORKS (S3 PASSED, owner round 2, 2026-07-12)** — numbered-outfit native `0x77FF8D35EEC6BBC4(ped, outfit_num, 0)` + `_UPDATE_PED_VARIATION`; outfit counts per model come from `peds/peds_list.lua`. E5 confirmed for V1. (The metaped-hash route stays off the menu.)
- ⚠️ **Native carriable route FULLY CLOSED (final — owner rounds 1–2, 2026-07-12):** carrying flags on arbitrary props (`p_crate01x`) arm no prompt, and script-spawned STOCK models (hay bales, sacks, moonshine bottles) don't prompt either. Carriable inputs/events exist in the dumps but the capability is engine-internal. No "native carry" catalog subset — B5/B6 is attach-route only, everywhere.
- ✅ **B5/B6 PRIMARY ROUTE = ATTACH** (owner spike round 1: `AttachEntityToEntity` named native resolves and works in-game — crate attached, wrong bone since fixed). Carry = attach to `SKEL_Spine3` (bone_id 14413; bone INDEX per skeleton: mp_male 134, mp_female 218 — resolve by player model) + carry animation (Phase 2) + movement restriction; put-down = detach + `PlaceObjectOnGroundProperly`; wagon load = attach to vehicle at configured offsets. `GET_PED_CARRIED_ENTITY`/`TASK_PLACE_CARRIED_ENTITY_AT_COORD` remain usable only for game-recognized carriables.
- ✅ Ground-snap for spawned entities: `GetGroundZAndNormalFor_3dCoord(x,y,z)` (named native; vorp_core coreactions.lua:191, vorp_utils peds.lua:33) + place-on-ground native 0x9587913B9E772D29 (vorp_utils peds.lua:104). Added after round 1 (entities spawned airborne).
- ✅ Ped outfit change: numbered-outfit native `0x77FF8D35EEC6BBC4(ped, outfit_num, 0)` (peds_list.lua header; outfit counts per model in the list — valtownfolk_01: 36). The metaped-outfit-hash approach (0x1902C4CFCC5BE57C with the README example hash) did NOT change this model in round 1 — E5 verdict awaits the round-2 retest with the numbered native.

## 4. Open spikes (Phase 0 checklist)

| ID | Spike | Blocks |
|---|---|---|
| S1 | ✅ DONE — signatures extracted verbatim into §1 | all VORP integration |
| S2 | ✅ PASSED round 1 — E3 confirmed for V1 | E3 |
| S3 | ✅ PASSED round 2 — numbered-outfit native cycles outfits; E5 confirmed for V1 | E5 |
| S4 | ✅ PASSED round 1 (ptfx + animpostfx) | F2 catalog curation |
| S5 | ✅ PASSED round 1 (soundsets) | F2 catalog curation |
| S6 | ✅ RULED FINAL rounds 1–2 — attach route only; native carriable closed even for stock models (audition ran: no prompts) | B5/B6 |

## Changelog

- **v0.4 (2026-07-12)** — Owner spike round 2: S3 PASSED (E5 confirmed via numbered-outfit native); S6 final — stock models don't prompt either, attach route only; ground-snap and chest attach confirmed (ticked, no notes). All six spikes resolved — every Phase 0 exit-gate condition met, gate awaiting owner ruling.
- **v0.3 (2026-07-12)** — Owner spike round 1 recorded: S6 native carriable route closed for arbitrary props → attach is B5/B6 primary (verified working); ground-snap + place-on-ground pattern added (airborne spawn fix); outfit spike switched to numbered-outfit native after metaped hash no-op; SKEL_Spine3 bone indexes documented. S2/S5 (speech/sound) results pending owner confirmation.
- **v0.2 (2026-07-12)** — Native carriable system verified (carrying flags, GET_PED_CARRIED_ENTITY, TASK_PLACE_CARRIED_ENTITY_AT_COORD, transport config flags); attach fallback documented; spike S6 added for B5/B6 route selection.
- **v0.1 (2026-07-12)** — Initial ledger: VORP surface, asset data inventory, engine patterns, Phase 0 spikes.

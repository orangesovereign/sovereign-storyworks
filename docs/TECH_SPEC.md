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
- 🔎 Native ambient ped speech (voice barks) — natives exist; usable line/voice names per ped model need a dev-server spike (E3).
- 🔎 NPC outfit/appearance control depth — preset variation vs full component control (E5).
- ✅ **Native carriable system exists** (confirmed 2026-07-12, `AI/CARRYING_FLAGS` + community natives): carrying flags incl. `CAN_BE_CARRIED_ON_FOOT` (2), `CAN_BE_CARRIED_ON_MOUNT` (3), `CAN_BE_DROPPED` (4), `CAN_BE_PLACED_ON_MOUNT` (14), `IS_INSTANT_PICKUP` (21), `CLEAN_UP_WHEN_NOT_CARRIED` (27); `GET_PED_CARRIED_ENTITY(ped)`; `TASK_PLACE_CARRIED_ENTITY_AT_COORD(ped, carried, x, y, z, ukn, flag)`; transport config flags (`SET_TRANSPORT_CONFIG_FLAG` 0xBA8818212633500A) for mount/vehicle interaction control. Supports B5/B6.
- ✅ Fallback for B5/B6: attach-to-bone + carry animation loop, detach + ground placement, attach to vehicle at offsets — the standard proven RedM carry-script pattern; guarantees B5/B6 ship even if the native carriable route disappoints.

## 4. Open spikes (Phase 0 checklist)

| ID | Spike | Blocks |
|---|---|---|
| S1 | Extract exact vorp_core/vorp_inventory export signatures from cloned repos | all VORP integration |
| S2 | Ambient speech native + line names in-game test | C-E3 only |
| S3 | Ped outfit natives test | C-E5 only |
| S4 | PTFX + animpostfx spot test (spawn a few from the dumps) | C-F2 catalog curation |
| S5 | Soundset/music event spot test | C-F2 catalog curation |
| S6 | Carriable route selection: make an arbitrary spawned prop carriable via carrying flags (pick up / put down / place / stow on mount), attach test on a wagon — decides B5/B6 primary route (native vs attach fallback); feature ships either way | B5/B6 implementation route only |

## Changelog

- **v0.2 (2026-07-12)** — Native carriable system verified (carrying flags, GET_PED_CARRIED_ENTITY, TASK_PLACE_CARRIED_ENTITY_AT_COORD, transport config flags); attach fallback documented; spike S6 added for B5/B6 route selection.
- **v0.1 (2026-07-12)** — Initial ledger: VORP surface, asset data inventory, engine patterns, Phase 0 spikes.

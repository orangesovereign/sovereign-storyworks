# Phase 3 Exit-Gate — Combat & NPC Operations (plain-text mirror)

**Living checklist (tick there):** https://claude.ai/code/artifact/7118756b-f977-41ec-9159-1f2863e24039
**Build under test:** sovereign_storyworks v0.3.0-phase3 (sovereign_notify unchanged since v1.2.1)
**Gate (roadmap):** combat checklist incl. the ugly paths — dying mid-escort, disconnecting mid-defend, cancelling mid-fight — with ZERO orphaned NPCs.

## Deploy

FTP `sovereign_storyworks`; restart. Six seeded missions now (adds `phase3_skirmish`). Bring a horse and a gun. Fixtures run anywhere on the map (targets placed east/north of your start).

## Architecture note (why the trust posture)

V1 = solo instances, so mission/combat NPCs are **client-local**: the client spawns them, detects death/arrival/separation, and reports; the server owns authoritative counts, timers, and the complete/fail decision (validated per-participant, rate-limited — same posture as the interaction layer). The **mission-NPC lifecycle manager** guarantees cleanup on every exit path. V2 party missions revisit with networked NPCs (ruling #3).

## Spike S7 (open)

Escort **locomotion** uses `TaskFollowNavMeshToCoord`, a movement native not present in our local reference repos — flagged. Combat/relationship/weapon natives ARE verified (vorp_utils). If the escort spawns but won't walk, that's S7 (fallback: `TaskGoStraightToCoord` / follow-player); death/separation/cleanup are unaffected.

## Articles (summary — full "Expect" lines live in the ledger)

- **ART. I** — boot clean, six missions seeded.
- **ART. II Eliminate** — 3 hostile gunmen on the ground, blips, fight, "Targets down: N of 3", clears and advances.
- **ART. III Defend** — hold 45s, 3 waves; UGLY: leave the boundary → fail + all attackers wiped.
- **ART. IV Escort** — S7 walk watch; UGLY: kill the witness → fail; stray too far → fail; both clean up.
- **ART. V Zero orphans** — UGLY: cancel mid-fight, disconnect mid-defend, restart-with-enemies-alive — each leaves NO orphaned NPCs.
- **ART. VI** — full chain completion; ruling #9 holds under combat.

## Test log

### Round 1 — 2026-07-13 (owner)

Findings + fixes (shipped same day; ledger revision 2):
- **ART II/III — enemies were bullet-sponges.** Default enemy health 200 → **120** (~normal person; killable in a shot or two, config-tunable in `ConfigRuntime.Combat.defaultEnemyHealth`).
- **ART IV — no blip on the escort NPC.** The guessed ally blip hash didn't render. → Both enemy and ally blips now use verified NAMED styles (`BLIP_STYLE_ENEMY` / `BLIP_STYLE_FRIENDLY`, joaat'd client-side). The escort now wears a friendly (blue) blip that follows them, alongside the destination objective blip.
- Not yet reported (retest in round 2): the ugly-path zero-orphan lines (cancel/disconnect/restart), escort S7 walk, full chain.

### Round 2 — 2026-07-13 (owner)

**"I completed it all. There wasn't any errors other than what I noted before."** Round-1 fixes confirmed (enemy health, escort blip). By completing the full chain: **spike S7 PASSED** (the escort walked to its destination — `TaskFollowNavMeshToCoord` works, no fallback needed), and the ugly-path zero-orphan lines (cancel/disconnect/restart) all held. Every Phase 3 exit-gate condition met — **gate awaits the owner's ruling.**

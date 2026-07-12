# CLAUDE.md — Sovereign Storyworks

All-in-one mission, quest, job, campaign, NPC, dialogue, and cutscene builder + runtime for **RedM / VORP Core**. Built for the Sovereign County RP server; owner (Wilbur) has final authority on all design decisions.

## Project status

**Current phase: PLANNING — Master Feature List LOCKED at v1.0 (2026-07-12, 40 features); Coding Plan v0.1 drafted, AWAITING OWNER SIGN-OFF.** No coding until the plan is approved.

Standing owner rulings (2026-07-12, full text in MASTER_FEATURE_LIST): #1 blank-page design (RC6 zip ignored entirely, never reference it); #2 hard VORP dependency (no adapter layer); #3 solo V1 on a party-ready participants-list core (posse missions V2); #4 society = job+grade gating only; #5 player journal in V1; #6 dashboard mockup approved as NUI baseline; #7 robust V1, no cuts (all 40 candidates approved; E3/E5 spike-conditional).

## Source of truth — read before any task

Everything in `/docs`, in precedence order:

1. **MASTER_FEATURE_LIST.md** — approved features by ID. If a behavior isn't in the Approved section, it is NOT approved. Candidate/parking-lot entries mean nothing until approved.
2. **CODING_PLAN_AND_ROADMAP.md** — phases, exit gates, definition of done (to be authored during planning).
3. **TECH_SPEC.md** — verified natives/APIs (to be authored; only ✅ items are usable, 🔎 must be verified first).
4. **BRANDING.md** — Sovereign County design system. All NUI work uses its tokens verbatim, plus the approved ornate baseline (Cinzel masthead, paper grain, filigree, telegram document language).
5. **docs/mockups/dashboard_mockup_v1_APPROVED.html** — owner-approved dashboard mockup (July 12, 2026): the visual baseline for all Storyworks NUI. Ledger window, filigree corners, Registry/Craft/Office nav grouping, stat tiles, reset strip, mission ledger table with kind chips, telegram dispatch slips. Its visual language is adopted wholesale; its nav items still map only onto features that get approved in the Master Feature List.

GitHub repository: https://github.com/orangesovereign/sovereign-storyworks (remote `origin`).

## Hard rules (carried over from the Sovereign Medical Suite — proven conventions)

- **RedM-native Lua only.** Never FiveM-only natives, GTA V hashes, or FiveM patterns. Verify natives against femga/rdr3_discoveries or the RDR3 native DB before first use; unverifiable → stop and flag.
- **VORP Core is the framework.** Consume VORP exports/events; never write to VORP tables directly. Reference repos live in `..\_reference\` (vorp_core, vorp_inventory-v2, vorp_utils, vorp_menu, vorp_banking, rdr3_discoveries) — read-only, learn the API surface, never copy code wholesale (GPL hygiene).
- **Server-authoritative everything.** Story state, progression, rewards, permissions live server-side. Every NUI callback and net event validated server-side and rate-limited. No client-trusted writes.
- **Everything configurable.** No magic numbers/coords/prices/timers/item names in code — split config files per the structure doc.
- **All player-facing strings through locales** (`locales/en.lua`, `T(key)` pattern).
- **Feature IDs everywhere** — file headers, commits, plans.
- **Scope control (owner's rule):** never add or "improve" beyond the Master Feature List. New ideas → propose in plain text → owner approval → update docs → THEN implement.
- **Phase discipline:** never start a phase before the previous exit gate passes. If execution diverges from plan, STOP and surface it.

## Environment & testing reality

- Claude cannot run a RedM server. Loop: write → owner deploys to dev server → owner pastes server console + F8 output → fix. Guard nils, wrap DB calls, tagged prints (`[sovereign_storyworks]`).
- Database: MySQL via **oxmysql**. Tables prefixed `sovereign_`, migrations clean on fresh AND existing DBs.
- At the end of each coding phase: create/maintain a testing checklist + log in `/docs/testing/` so the owner or a helper can test without context.
- Communication style: plain language first, tech talk alongside.

## Conventions

- Lua 5.4 (`lua54 'yes'`), two-space indent, locals over globals, one module per file.
- NUI: **React + Vite** (same as sovereign_mdt). Claude runs every build and commits the built bundle (`ui/src/` source, `ui/dist/` shipped, only dist in fxmanifest). NO CDN at runtime — all deps, fonts (Cinzel, Libre Baskerville, IM Fell English), and textures bundled.
- fxmanifest must include the mandatory RedM prerelease acknowledgment line.

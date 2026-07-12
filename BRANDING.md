# Sovereign County RP — Branding & Theming Cheat Sheet

> Owner-supplied design system. This document is the visual authority for all Sovereign Medical Suite UI. The `--sc-*` variables below are copied verbatim into `sovereign_mdt/ui/css/sc-theme.css` in Phase 6.

## Brand Mood

**Core feeling:** Dark cinematic Western. Serious, grounded, dramatic, adult, political, lawless-but-organized.

**Visual language:** Victorian frontier government, rail-town wealth, old county records, wanted posters, mahogany offices, oil lamps, red-stained dusk, black iron, aged paper, worn leather, brass, and dried blood red.

**Avoid:** Bright orange sunsets everywhere, cartoon cowboy fonts, excessive skulls, fake sheriff stars on everything, cheap crowns, generic saloon signs, neon UI, pure white panels, clean modern blue buttons.

## Primary Color Palette

| Use | Name | HEX | Notes |
|---|---|---|---|
| Main Background | Sovereign Black | `#050505` | Deepest UI background, loading screens, menu shells |
| Soft Background | Charcoal Smoke | `#0A0A0A` | Slight lift from black, panels and modals |
| Panel Dark | Gunmetal Ash | `#141210` | Script menus, inventory boxes, roleplay UI |
| Border Dark | Burnt Umber | `#29140A` | Frames, outlines, divider shadows |
| Primary Red | County Blood Red | `#6A1B11` | Main accent, headers, active states |
| Deep Red | Oxblood | `#441D0A` | Dark red shadows, hover states |
| Rust Red | Iron Rust | `#7F4117` | Secondary accents, distressed trim |
| Sunset Copper | Copper Ember | `#9E4A0F` | Small highlights only, not main branding |
| Aged Gold | Tarnished Brass | `#86572C` | Premium accents, icons, trim |
| Paper Cream | Aged Parchment | `#CEA978` | Text on dark backgrounds, document UI |
| Bone White | Weathered Ivory | `#E0D2B5` | Main readable text, logo lettering |
| Muted Gray | Dust Gray | `#5D5144` | Secondary text, disabled buttons |

## UI Color Roles

**Backgrounds** — `--bg-main: #050505; --bg-panel: #0A0A0A; --bg-card: #141210; --bg-raised: #1B1612; --bg-muted: #21170F;`
Main overlay `#050505` at 85–95% opacity · menu panel `#0A0A0A` · card `#141210` · hovered card `#1B1612`. Keep it dark. We are not opening a frozen yogurt shop.

**Reds** — `--red-primary: #6A1B11; --red-deep: #441D0A; --red-rust: #7F4117; --red-hover: #8A2A18; --red-muted: #4A1811;`
For: active buttons, job labels, alerts, danger actions, selected tabs, progress bars, small divider flourishes. Do not use red as a full-screen background — red should feel like a seal stamp, blood on a ledger, or paint on old wood, not a Hot Topic homepage.

**Gold / Brass / Cream** — `--brass: #86572C; --brass-light: #A77A45; --parchment: #CEA978; --ivory: #E0D2B5; --faded-ink: #9B8A73;`
For: borders, thin decorative lines, logo text, important labels, currency, seals, premium buttons, icons. Use brass sparingly — it should whisper "old money," not scream "mobile casino."

## Text

`--text-primary: #E0D2B5; --text-secondary: #CEA978; --text-muted: #9B8A73; --text-disabled: #5D5144; --text-danger: #8A2A18; --text-success: #7B8A5A;`

| Element | Color | Weight | Style |
|---|---|---|---|
| Main title | `#E0D2B5` | 700–900 | Large serif, slightly distressed |
| Section header | `#CEA978` | 600–800 | Serif or condensed serif |
| Body text | `#D6C6A7` | 400–500 | Clean readable serif/sans |
| Metadata | `#9B8A73` | 400 | Small caps if possible |
| Warning text | `#8A2A18` | 700 | Use with restraint |
| Disabled text | `#5D5144` | 400 | Low contrast intentionally |

## Fonts

**Display** (titles, job names, seals, department headers): Western slab serif / vintage condensed / letterpress / Victorian signage. Good examples: Playfair Display, **Cinzel**, Rye, Ewert, Cormorant Garamond, **IM Fell English**, **Libre Baskerville**.
**UI/Body** (menus, descriptions, tooltips): **Libre Baskerville**, Lora, Merriweather, Crimson Text, Source Serif Pro.
**Avoid:** comic western fonts, wavy saloon fonts, sci-fi fonts (Orbitron), anything that looks like a BBQ food truck logo.

> Suite decision (approved): Cinzel = display, Libre Baskerville = body, IM Fell English = handwritten/italic accents. All bundled locally (OFL), no CDN.

## Buttons

Primary: `background:#6A1B11; color:#E0D2B5; border:1px solid #86572C;` hover `background:#8A2A18; border-color:#A77A45;`
Secondary: `background:#141210; color:#CEA978; border:1px solid #441D0A;` hover `background:#21170F; border-color:#86572C;`
Danger: `background:#441D0A; color:#E0D2B5; border:1px solid #6A1B11;` — for destructive/disciplinary actions.

## Borders, Frames & Dividers

`border: 1px solid #442617; box-shadow: 0 0 18px rgba(0,0,0,0.75);`
Decorative line: `height:1px; background:linear-gradient(90deg,transparent,#441D0A,#86572C,#441D0A,transparent);`
Panel frame: `border:1px solid #29140A; outline:1px solid rgba(134,87,44,0.35);`
Ornament sparingly: a little says "county office," too much says "saloon bathroom wallpaper."

## Medical UI (the suite's home section)

Main background `#0A0A0A` · uniform white elements `#D8CBB3` · medical red `#7A1F16` · labels `#CEA978` · patient severe `#6A1B11` · patient stable `#7B8A5A`. Feel: frontier field hospital / nurse registry.

## Practical CSS Variables (plug-and-play)

```css
:root {
  --sc-black: #050505;   --sc-charcoal: #0A0A0A; --sc-gunmetal: #141210;
  --sc-raised: #1B1612;  --sc-umber: #29140A;
  --sc-red: #6A1B11;     --sc-red-dark: #441D0A; --sc-red-hover: #8A2A18; --sc-rust: #7F4117;
  --sc-brass: #86572C;   --sc-brass-light: #A77A45;
  --sc-parchment: #CEA978; --sc-ivory: #E0D2B5;
  --sc-muted: #9B8A73;   --sc-disabled: #5D5144;
  --sc-success: #7B8A5A; --sc-warning: #B07A2A;  --sc-danger: #8A2A18;
}
```

Example panel: `background:linear-gradient(180deg,#0A0A0A,#141210); color:#E0D2B5; border:1px solid #29140A; outline:1px solid rgba(134,87,44,0.3); box-shadow:0 18px 40px rgba(0,0,0,0.75);`
Example header: `color:#CEA978; font-family:"Cinzel","Georgia",serif; text-transform:uppercase; letter-spacing:0.12em; border-bottom:1px solid #441D0A;`

## Final Brand Rule

Sovereign County should look like an old American county with secrets, not a generic Western theme. Everything should feel like it belongs in: a mayor's office, a courthouse ledger, a stable at dusk, a saloon after a bad decision, a jail intake room, **a medical tent after gunfire**, or a railroad office where somebody rich is lying through his teeth. That's the lane — stay in it.

## Approved suite-specific extensions (July 7, 2026)

From the approved mockup baseline: engraved Cinzel masthead with brass filigree corners; paper-grain texture + lamplight vignette on all surfaces; flourish divider rules; **telegram document language** (incoming calls, prescriptions, and lab reports as cream slips with the wax SC seal against the dark ledger); **anatomical plate** wound display (period medical-illustration figure, numbered zone markers, ink-fill severity bars).

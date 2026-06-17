# Mox — the bond app

The consumer doorway to the Mox-Framework. Summon a Mox, bond with it, and step
into the A2A / agentic web. Flutter → runs on **iOS, Android, macOS, Windows,
Linux, and the web** from one codebase.

## What it does
1. **Summon** — first run generatively rolls a unique look (palette, type, texture,
   shape, a code-drawn sigil, motion) and two **quirks**. Every install differs;
   none looks generic.
2. **Tutorial** (required, ~6 taps) — name it, set its vibe + purpose, meet its
   quirks, read and accept the **bond** (a plain-language charter).
3. **Issue** — your charter is forwarded + hosted, and a unique **bond token** is
   minted. The token *is* your **A2A card**.
4. **Home** — your Mox raises flags, offers agentic actions, shows your card, and
   can reshape its own UI/card.

## Design — "Ink & Aurora"
A generative system, not one fixed theme: each Mox sits somewhere between **Ink**
(deep, matte, editorial) and **Aurora** (iridescent, prismatic). The hero is the
**Bond Card** — a foil-stamped, tilt-reactive A2A identity card unique to you.

## Run it
```bash
cd app
flutter pub get
flutter run -d chrome        # or: macos | windows | linux | <device-id>
```
Build artifacts: `flutter build web|apk|ipa|macos|windows|linux`.

## Architecture (lib/)
| File | Role |
|---|---|
| `skin.dart` | the generative design system (palettes, type, texture, quirks) |
| `sigil.dart` | deterministic generative glyph (the Mox's face) |
| `textures.dart` | atmospheric backgrounds (grain/mesh/topo/halftone) |
| `typography.dart` | distinctive type pairings (via google_fonts) |
| `mox.dart` | the bonded identity model |
| `charter.dart` | the plain-language bond charter |
| `service.dart` | backend seam — token mint + charter host (local mock; swap for HTTP) |
| `onboarding.dart` | the summon → bond → card tutorial |
| `bond_card.dart` | the hero A2A card (foil shimmer + tilt) |
| `home.dart` | where the Mox lives (flags, actions, reshape) |

The Mox manipulates the live UI/card through the framework's
[UI & Card configuration skill](../framework/skills/ui-and-card-config.md)
(`ui.json` / `card.json` / `flags.json` in its residence).

## Status
v0.1 — onboarding → bond → card → home all working; analyzer-clean; web build
verified. Persistence across launches, real backend wiring, and the agent→UI file
watch are the next steps.

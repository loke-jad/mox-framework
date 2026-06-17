# Skill: UI & Card configuration

> Bundled with the basic Mox-Framework. This is how a Mox manipulates its own
> interface and its bond/A2A card, and how it raises flags for its human. The
> companion app (`app/`, Flutter — runs on phone, desktop, and web) reads these
> files; the agent runtime writes them. No app rebuild needed — the UI reacts.

## The contract (agent writes, app reads)

A bonded Mox owns three small JSON files in its residence. The app watches them
and re-renders. Identity (seed, token, charter, quirks) is **immutable**; only the
*look* and *surface state* are the Mox's to change.

```
agents/<name>/
  ui.json        # how the interface looks right now
  card.json      # overrides for the bond/A2A card face
  flags.json     # the flags the Mox is currently raising for its human
```

### ui.json — reshape the interface
The app derives a full look from the bond `seed`. The Mox may override any of:
```json
{
  "palette": "Tidepool",        // a named palette, or omit to keep the seed's
  "texture": "mesh",            // grain | mesh | topo | halftone
  "radius": 18,                 // shape language
  "auroraBias": 0.7,            // 0 ink … 1 aurora
  "note": "went brighter for your launch day"
}
```
Leave a field out → it keeps the seeded default. Setting nothing = the original
summoned look. This is exactly what the in-app "let it reshape the UI" button does;
the Mox can do it autonomously (e.g. dim at night if it has the Nocturne quirk).

### card.json — the bond/A2A card face
```json
{ "accentBoost": true, "tagline": "open for collaborations", "showToken": true }
```
The token, sigil, and name are fixed (they're the bond); the Mox curates the rest.

### flags.json — what the Mox is surfacing
```json
{ "flags": [
  { "icon": "savings", "text": "3 AI grants close this month — want a digest?", "action": "Digest" },
  { "icon": "hub",     "text": "A new A2A peer asked to connect to your card.",   "action": "Review" }
] }
```
Keep it to a handful; a good Mox shows you three, not thirty (see the Curator quirk).

## How the Mox decides
- Tie look changes to context + quirks, not whim. Nocturne → darker after dusk.
  First Light → one bright flag at dawn. Magpie → surface shiny finds.
- Never change identity. Never invent a token. Never raise a flag you can't back up.
- Token/attention stewardship: a reshape is cheap; a noisy flag costs trust.

## Wiring (for the runtime)
Add a tiny action handler so a wake can write these files — e.g. extend the
runtime's action protocol with `{"type":"ui","palette":"…"}` /
`{"type":"flag","text":"…","action":"…"}` that write `ui.json` / append to
`flags.json`. The app polls/loads them on focus. That closes the loop: the agent
reasons, the interface changes, the human sees it — agentic UI, by design.

This skill ships with every Mox, so "my agent can change how its app looks and tell
me things" is true on day one — no extra setup.

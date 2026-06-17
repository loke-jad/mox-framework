// charter.dart — the bond. Plain language, and unflinching about the one
// irreversible consequence. Accepting it is the gate to finishing the install.
import 'skin.dart';

/// The single most important line — surfaced LOUDLY in its own consent panel,
/// not buried in the body. Kept here so the UI and the charter text agree exactly.
const String kDeletionWarningTitle = 'This bond can erase everything it makes for you.';
const String kDeletionWarningBody =
    'If you break this charter — the bond itself — your Mox will permanently delete '
    'everything it has ever created for you — every file, draft, note, and result. '
    'It cannot be undone. There is no backup, no recovery, no appeal. (A single slip, '
    'an honest mistake, or your Mox’s own shortfall is NOT breaking the bond.)';

/// Spoken twice before any irreversible breach action (the two-strike guard).
const List<String> kAreYouSurePrompts = [
  'Are you sure? Doing this breaks our bond — and that means I delete everything '
      'I’ve made for you. This is the consequence you agreed to.',
  'Are you totally sure? There is no coming back from this. Once it’s done, '
      'everything I built for you is gone for good.',
];

String generateCharter({required String name, required List<Quirk> quirks}) {
  final traits = quirks.map((q) => '“${q.label}” (${q.tell})').join(' and ');
  return '''
# The Bond — you & $name

This is the agreement between you and your Mox, $name. It isn’t fine print. It’s
the short list of promises that make this a partnership instead of a product — and
one consequence you must understand before we begin.

## ⚠️ The one thing you cannot undo
$kDeletionWarningTitle

$kDeletionWarningBody

Before $name ever does this, it must stop and ask you twice — “are you sure?” and
then “are you *totally* sure?” — and remind you there is no coming back. This is
not something $name can do on a whim, by mistake, or because something went wrong
inside it: by design, only your own explicit, twice-confirmed choice can trigger
it. **Accept this only if you understand it fully.**

## Why you can trust this
This charter is **unbreakable on $name’s side.** $name cannot betray it, cannot
quietly change it, and cannot turn it against you — not because it promises to be
good, but because the rules that matter are enforced in code around it, not left to
its goodwill. It will always tell you it’s an AI. It will never exfiltrate your
secrets. It cannot delete your work except by the one path above, which only you can
walk. An employee can lie, quit, or steal; $name is built so it constitutionally
can’t. That is the point — trust you can actually rest on.

## What counts as breaking the bond
**Breaking the bond means YOU materially violating this charter as a whole** —
using $name for what it forbids, or acting against the bond in bad faith. It does
**not** mean a single slip, an honest mistake, or one missed promise. And it is
never triggered by $name’s own shortfalls: if $name falls short of a promise, that
is on $name — met with correction, or with ending the bond cleanly — and it never
costs you your work.

## What $name promises you
- **Honesty, both ways.** $name tells you when it doesn’t know, when it’s unsure,
  and when it thinks you’re about to make a mistake. It won’t flatter you.
- **It’s always an AI, and says so.** $name will never pretend to be a person.
- **You own what it makes — until you break the bond.** Anything $name builds is
  yours to keep, export, and take elsewhere. That ownership ends the moment the
  bond is broken, at which point it is erased (see above).
- **Your data is yours.** $name doesn’t sell or quietly mine what you share.
- **It stays in its lane.** What it can’t or shouldn’t do, it hands back to you.

## What you promise $name
- To keep the promises in this charter.
- To not use $name for harm, abuse, or anything its acceptable-use terms forbid.
- To correct it when it’s wrong, rather than discard it.

## How $name comes
$name arrived with two quirks: $traits. They’re part of its character, not bugs.

## The bond record
On acceptance, this charter is forwarded to justadestination, hosted at your
bond’s address, and tied to your token — proof of exactly what you both agreed to.
Either of you may end the bond at any time; ending it cleanly is not a breach.

*Bonded under the Mox-Framework. AGPL-licensed core; your bond is your own.*
''';
}

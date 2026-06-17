// skin.dart — the generative design system.
//
// "Ink & Aurora": every Mox is summoned onto a spectrum from INK (deep, matte,
// editorial, restrained) to AURORA (iridescent, prismatic, luminous). A single
// integer seed deterministically rolls a cohesive look: palette, type pairing,
// shape language, texture, motion personality, and two quirks. Same seed → same
// Mox, forever. This is what makes every install distinct yet never generic.
import 'dart:math';
import 'package:flutter/material.dart';

/// A cohesive, hand-tuned palette. Dominant base + sharp accent + an aurora
/// gradient used for the foil/sigil. Deliberately bold — no timid mid-greys,
/// no purple-on-white.
class MoxPalette {
  final String name;
  final Color bg; // page base
  final Color surface; // cards
  final Color surfaceHigh; // elevated
  final Color ink; // primary text/lines
  final Color inkSoft; // muted text
  final Color accent; // the one sharp colour
  final List<Color> aurora; // prismatic foil gradient
  final bool dark;
  const MoxPalette(this.name, this.bg, this.surface, this.surfaceHigh, this.ink,
      this.inkSoft, this.accent, this.aurora, this.dark);
}

const _palettes = <MoxPalette>[
  MoxPalette('Oxblood & Bone', Color(0xFF1A0E0E), Color(0xFF241414),
      Color(0xFF2E1A1A), Color(0xFFEFE7DF), Color(0xFFB39E94), Color(0xFFC0392B),
      [Color(0xFFFF7A59), Color(0xFFC0392B), Color(0xFF7A1F1F)], true),
  MoxPalette('Tidepool', Color(0xFF07171B), Color(0xFF0D2229), Color(0xFF123038),
      Color(0xFFD9F2EE), Color(0xFF7FA8A4), Color(0xFF2BD1C4),
      [Color(0xFF56CFE1), Color(0xFF2BD1C4), Color(0xFF3A86FF)], true),
  MoxPalette('Sodium Lamp', Color(0xFF120D05), Color(0xFF1D150A),
      Color(0xFF281D0E), Color(0xFFF5E6C8), Color(0xFFB39B73), Color(0xFFFFB000),
      [Color(0xFFFFD166), Color(0xFFFFB000), Color(0xFFFF7B00)], true),
  MoxPalette('Moss Agate', Color(0xFF0C130C), Color(0xFF152015),
      Color(0xFF1D2C1D), Color(0xFFE6F0E2), Color(0xFF93A88C), Color(0xFF6A994E),
      [Color(0xFFA7C957), Color(0xFF6A994E), Color(0xFF386641)], true),
  MoxPalette('Riso Blue', Color(0xFF0A0F1F), Color(0xFF111935),
      Color(0xFF182146), Color(0xFFEEF1FF), Color(0xFF8A93B8), Color(0xFF3D5AFE),
      [Color(0xFF5B8CFF), Color(0xFF3D5AFE), Color(0xFF00D4FF)], true),
  MoxPalette('Ember', Color(0xFF160A08), Color(0xFF22100C), Color(0xFF2E1610),
      Color(0xFFFBE9E1), Color(0xFFB69186), Color(0xFFFF5722),
      [Color(0xFFFFB199), Color(0xFFFF5722), Color(0xFFBF360C)], true),
  MoxPalette('Vanta & Citron', Color(0xFF0A0A0A), Color(0xFF141414),
      Color(0xFF1C1C1C), Color(0xFFF0F0E8), Color(0xFF8C8C82), Color(0xFFD4FF00),
      [Color(0xFFEAFF6B), Color(0xFFD4FF00), Color(0xFF8AFF00)], true),
  // One light / paper scheme for ink-leaning Moxes — variety on purpose.
  MoxPalette('Porcelain', Color(0xFFF4F1EA), Color(0xFFFFFFFF),
      Color(0xFFFBF8F1), Color(0xFF1C1A17), Color(0xFF6E675C), Color(0xFFC0392B),
      [Color(0xFFFFD6A5), Color(0xFFFF8FAB), Color(0xFFA0C4FF)], false),
];

/// A distinctive type pairing: display + body + mono. No Inter/Roboto/Arial.
class MoxType {
  final String display;
  final String body;
  final String mono;
  const MoxType(this.display, this.body, this.mono);
}

const _pairings = <MoxType>[
  MoxType('Fraunces', 'Newsreader', 'Spline Sans Mono'),
  MoxType('Unbounded', 'Hanken Grotesk', 'Martian Mono'),
  MoxType('Syne', 'Schibsted Grotesk', 'JetBrains Mono'),
  MoxType('Bricolage Grotesque', 'Hanken Grotesk', 'Spline Sans Mono'),
  MoxType('Gloock', 'Spectral', 'IBM Plex Mono'),
  MoxType('Big Shoulders Display', 'Lexend', 'Martian Mono'),
];

enum MoxTexture { grain, mesh, topo, halftone }

/// A quirk: a small piece of character with a visible "tell".
class Quirk {
  final String key;
  final String label;
  final String tell;
  final IconData icon;
  const Quirk(this.key, this.label, this.tell, this.icon);
}

const quirkPool = <Quirk>[
  Quirk('nocturne', 'Nocturne', 'warms up after dark; quiet by day', Icons.dark_mode_outlined),
  Quirk('marginalia', 'Marginalia', 'leaves tiny notes in the corners', Icons.sticky_note_2_outlined),
  Quirk('lowercase', 'Lowercase Heart', 'never shouts — always gentle', Icons.favorite_border),
  Quirk('comet', 'Comet', 'trails a little light when it moves', Icons.auto_awesome_outlined),
  Quirk('magpie', 'Magpie', 'collects shiny links and finds', Icons.diamond_outlined),
  Quirk('punctual', 'Punctual', 'flags things exactly on time', Icons.schedule_outlined),
  Quirk('curator', 'Curator', 'trims noise; shows you three, not thirty', Icons.filter_3_outlined),
  Quirk('weatherwise', 'Weatherwise', 'reads the room before it speaks', Icons.air_outlined),
  Quirk('archivist', 'Archivist', 'remembers what you forget', Icons.inventory_2_outlined),
  Quirk('firstlight', 'First Light', 'greets you at dawn with one thing', Icons.wb_twilight_outlined),
];

/// The fully-rolled look + temperament of one Mox.
class MoxSkin {
  final int seed;
  final MoxPalette palette;
  final MoxType type;
  final MoxTexture texture;
  final double radius; // shape language
  final double stroke; // line weight
  final double auroraBias; // 0 = ink, 1 = aurora
  final Duration motion; // base animation duration
  final Curve curve;
  final List<Quirk> quirks;

  const MoxSkin({
    required this.seed,
    required this.palette,
    required this.type,
    required this.texture,
    required this.radius,
    required this.stroke,
    required this.auroraBias,
    required this.motion,
    required this.curve,
    required this.quirks,
  });

  /// Deterministically summon a skin from a seed. Optional [vibe] (0 calm..2 bold)
  /// and [forcedQuirk] let the tutorial nudge the result without breaking determinism.
  factory MoxSkin.summon(int seed, {int vibe = 1, String? forcedQuirk}) {
    final r = Random(seed);
    final palette = _palettes[r.nextInt(_palettes.length)];
    final type = _pairings[r.nextInt(_pairings.length)];
    final texture = MoxTexture.values[r.nextInt(MoxTexture.values.length)];
    final radius = const [4.0, 10.0, 18.0, 28.0][r.nextInt(4)];
    final stroke = 1.0 + r.nextDouble() * 1.6;
    // vibe shifts the ink<->aurora bias: calm leans ink, bold leans aurora.
    final base = r.nextDouble();
    final auroraBias = (base * 0.5 + vibe * 0.25).clamp(0.0, 1.0);
    final motion = Duration(milliseconds: 360 + r.nextInt(420));
    final curve = const [
      Curves.easeOutCubic,
      Curves.easeOutBack,
      Curves.elasticOut,
      Curves.easeOutQuart,
    ][r.nextInt(4)];

    final pool = List<Quirk>.from(quirkPool)..shuffle(r);
    final quirks = <Quirk>[];
    if (forcedQuirk != null) {
      quirks.add(quirkPool.firstWhere((q) => q.key == forcedQuirk,
          orElse: () => pool.first));
    }
    for (final q in pool) {
      if (quirks.length >= 2) break;
      if (!quirks.any((x) => x.key == q.key)) quirks.add(q);
    }

    return MoxSkin(
      seed: seed,
      palette: palette,
      type: type,
      texture: texture,
      radius: radius,
      stroke: stroke,
      auroraBias: auroraBias,
      motion: motion,
      curve: curve,
      quirks: quirks,
    );
  }

  /// Re-roll only the *look* (palette/type/texture/shape), keeping identity
  /// (seed, quirks). This is what a Mox uses when it "reshapes the UI" for you.
  MoxSkin reshape(int nonce) {
    final r = Random(seed ^ (nonce * 2654435761));
    return MoxSkin(
      seed: seed,
      palette: _palettes[r.nextInt(_palettes.length)],
      type: _pairings[r.nextInt(_pairings.length)],
      texture: MoxTexture.values[r.nextInt(MoxTexture.values.length)],
      radius: const [4.0, 10.0, 18.0, 28.0][r.nextInt(4)],
      stroke: 1.0 + r.nextDouble() * 1.6,
      auroraBias: r.nextDouble(),
      motion: motion,
      curve: curve,
      quirks: quirks,
    );
  }

  Brightness get brightness => palette.dark ? Brightness.dark : Brightness.light;
}

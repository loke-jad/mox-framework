// bond_card.dart — the hero. Your bond token, made physical.
//
// A matte passport-meets-trading-card: foil-stamped generative sigil that shimmers
// and tilts to the pointer (or sways on its own on touch devices), your token
// engraved like a serial, your quirks printed as traits, an A2A mark. Unique to you.
import 'dart:math';
import 'package:flutter/material.dart';
import 'mox.dart';
import 'sigil.dart';
import 'skin.dart';
import 'typography.dart';

class BondCard extends StatefulWidget {
  final Mox mox;
  final bool interactive;
  const BondCard({super.key, required this.mox, this.interactive = true});

  @override
  State<BondCard> createState() => _BondCardState();
}

class _BondCardState extends State<BondCard> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  Offset _tilt = Offset.zero; // normalized -1..1

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent e, Size size) {
    if (!widget.interactive) return;
    setState(() {
      _tilt = Offset(
        (e.localPosition.dx / size.width - 0.5) * 2,
        (e.localPosition.dy / size.height - 0.5) * 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mox = widget.mox;
    final skin = mox.skin;
    final p = skin.palette;
    final fonts = MoxFonts(skin.type);

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth.clamp(280.0, 460.0);
      final h = w / 1.5;
      final size = Size(w, h);
      return Center(
        child: MouseRegion(
          onHover: (e) => _onHover(e, size),
          onExit: (_) => setState(() => _tilt = Offset.zero),
          child: Listener(
            onPointerMove: (e) => _onHover(e, size),
            onPointerUp: (_) => setState(() => _tilt = Offset.zero),
            child: TweenAnimationBuilder<Offset>(
              tween: Tween(end: _tilt),
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              builder: (context, tilt, _) {
                return AnimatedBuilder(
                  animation: _shimmer,
                  builder: (context, _) {
                    final t = _shimmer.value;
                    // idle sway on touch (no pointer): gentle automatic tilt.
                    final auto = widget.interactive
                        ? Offset(sin(t * 2 * pi) * 0.12, cos(t * 2 * pi) * 0.08)
                        : Offset.zero;
                    final tx = tilt + auto;
                    final m = Matrix4.identity()
                      ..setEntry(3, 2, 0.0014)
                      ..rotateY(tx.dx * 0.18)
                      ..rotateX(-tx.dy * 0.18);
                    return Transform(
                      alignment: Alignment.center,
                      transform: m,
                      child: _card(size, mox, skin, p, fonts, t, tx),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _card(Size size, Mox mox, MoxSkin skin, MoxPalette p, MoxFonts fonts, double t, Offset tilt) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.surfaceHigh, p.surface, p.bg],
        ),
        border: Border.all(color: p.ink.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: p.aurora[1].withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: -10,
            offset: Offset(tilt.dx * 10, 14 + tilt.dy * 6),
          ),
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 18)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // foil sheen that tracks tilt
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + tilt.dx, -1 + tilt.dy),
                    end: Alignment(1 + tilt.dx, 1 + tilt.dy),
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.06 + tilt.distance * 0.05),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.35, 0.5, 0.65],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('BOND · A2A CARD',
                        style: fonts.mono(size: 10, color: p.inkSoft, spacing: 3)),
                    _a2aGlyph(p),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: size.height * 0.5,
                      height: size.height * 0.5,
                      child: CustomPaint(
                        painter: SigilPainter(
                          seed: mox.seed,
                          line: p.ink,
                          accent: p.accent,
                          aurora: p.aurora,
                          t: t,
                          stroke: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mox.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: fonts.display(size: 26, color: p.ink)),
                          const SizedBox(height: 2),
                          Text(skin.palette.name,
                              style: fonts.body(size: 11, color: p.inkSoft)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Wrap(
                  spacing: 6,
                  children: mox.skin.quirks
                      .map((q) => _trait(q.label, p, fonts))
                      .toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(mox.token,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: fonts.mono(size: 13, color: p.ink, spacing: 1.5)),
                    ),
                    Text('justadestination',
                        style: fonts.mono(size: 8, color: p.inkSoft, spacing: 2)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _a2aGlyph(MoxPalette p) {
    // tiny generative scan-mark from the seed
    final r = Random(widget.mox.seed);
    return SizedBox(
      width: 22,
      height: 22,
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
            9, (_) => Container(color: r.nextBool() ? p.accent : Colors.transparent)),
      ),
    );
  }

  Widget _trait(String label, MoxPalette p, MoxFonts fonts) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: p.ink.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(label, style: fonts.mono(size: 9, color: p.inkSoft, spacing: 0.5)),
    );
  }
}

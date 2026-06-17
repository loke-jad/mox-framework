// sigil.dart — a unique generative glyph drawn from the bond seed.
//
// Deterministic: same seed → same sigil, forever. It's the Mox's face — foil-
// stamped on the bond card, watermarked in the app. Built from a mirrored set of
// nodes on a radial grid, connected by arcs and struts, with a few accent dots.
import 'dart:math';
import 'package:flutter/material.dart';

class SigilPainter extends CustomPainter {
  final int seed;
  final Color line;
  final Color accent;
  final List<Color> aurora;
  final double t; // 0..1 animation phase (foil shimmer / subtle rotation)
  final double stroke;

  SigilPainter({
    required this.seed,
    required this.line,
    required this.accent,
    required this.aurora,
    this.t = 0,
    this.stroke = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(seed);
    final c = size.center(Offset.zero);
    final radius = size.shortestSide * 0.42;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(sin(t * 2 * pi) * 0.04); // breathe

    final rays = 5 + r.nextInt(4); // 5..8 fold symmetry
    final ringPts = <Offset>[];
    for (var i = 0; i < rays; i++) {
      final a = (i / rays) * 2 * pi - pi / 2;
      final rr = radius * (0.55 + r.nextDouble() * 0.45);
      ringPts.add(Offset(cos(a) * rr, sin(a) * rr));
    }

    // Aurora foil gradient for the strokes.
    final shader = SweepGradient(
      colors: [...aurora, aurora.first],
      transform: GradientRotation(t * 2 * pi),
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = line.withValues(alpha: 0.5);

    final foilPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 1.4
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    // Outer ring.
    canvas.drawCircle(Offset.zero, radius, framePaint);

    // Struts from centre + chords between ring points.
    for (var i = 0; i < ringPts.length; i++) {
      final p = ringPts[i];
      if (r.nextBool()) canvas.drawLine(Offset.zero, p, foilPaint);
      final q = ringPts[(i + 1 + r.nextInt(ringPts.length - 1)) % ringPts.length];
      // arc-ish chord via quadratic
      final path = Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo(0, 0, q.dx, q.dy);
      canvas.drawPath(path, framePaint);
    }

    // Accent nodes.
    final dot = Paint()..color = accent;
    for (final p in ringPts) {
      if (r.nextDouble() > 0.4) canvas.drawCircle(p, stroke * 1.6, dot);
    }
    // Core.
    canvas.drawCircle(Offset.zero, radius * 0.10, Paint()..color = accent);
    canvas.drawCircle(Offset.zero, radius * 0.10, framePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SigilPainter old) =>
      old.seed != seed || old.t != t || old.line != line || old.accent != accent;
}

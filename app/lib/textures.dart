// textures.dart — atmospheric backgrounds. Each Mox gets one, by skin.texture.
import 'dart:math';
import 'package:flutter/material.dart';
import 'skin.dart';

class MoxBackground extends StatelessWidget {
  final MoxSkin skin;
  final double t;
  final Widget child;
  const MoxBackground({super.key, required this.skin, required this.child, this.t = 0});

  @override
  Widget build(BuildContext context) {
    final p = skin.palette;
    return Container(
      color: p.bg,
      child: CustomPaint(
        painter: _TexturePainter(skin, t),
        child: child,
      ),
    );
  }
}

class _TexturePainter extends CustomPainter {
  final MoxSkin skin;
  final double t;
  _TexturePainter(this.skin, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = skin.palette;
    final bias = skin.auroraBias;
    final rect = Offset.zero & size;

    // Aurora wash — stronger the more aurora-leaning the Mox is.
    final glow = Paint()
      ..shader = RadialGradient(
        center: Alignment(sin(t * 2 * pi) * 0.4, -0.7 + cos(t * 2 * pi) * 0.2),
        radius: 1.1,
        colors: [
          p.aurora[1].withValues(alpha: 0.18 + bias * 0.22),
          p.aurora[2].withValues(alpha: 0.05 + bias * 0.10),
          p.bg.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, glow);

    switch (skin.texture) {
      case MoxTexture.grain:
        _grain(canvas, size, p);
        break;
      case MoxTexture.mesh:
        _mesh(canvas, size, p);
        break;
      case MoxTexture.topo:
        _topo(canvas, size, p);
        break;
      case MoxTexture.halftone:
        _halftone(canvas, size, p);
        break;
    }
  }

  void _grain(Canvas canvas, Size size, MoxPalette p) {
    final r = Random(skin.seed);
    final dot = Paint()..color = p.ink.withValues(alpha: p.dark ? 0.05 : 0.06);
    final n = (size.width * size.height / 1600).clamp(200, 2600).toInt();
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(
          Offset(r.nextDouble() * size.width, r.nextDouble() * size.height),
          r.nextDouble() * 0.9 + 0.2, dot);
    }
  }

  void _mesh(Canvas canvas, Size size, MoxPalette p) {
    final r = Random(skin.seed);
    for (var i = 0; i < 4; i++) {
      final col = p.aurora[i % p.aurora.length];
      final center = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height);
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          col.withValues(alpha: 0.16),
          col.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: center, radius: size.shortestSide * 0.5));
      canvas.drawCircle(center, size.shortestSide * 0.5, paint);
    }
  }

  void _topo(Canvas canvas, Size size, MoxPalette p) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = p.ink.withValues(alpha: p.dark ? 0.06 : 0.08);
    final center = Offset(size.width * 0.7, size.height * 0.3);
    for (var i = 1; i < 22; i++) {
      final rad = i * size.shortestSide * 0.06 + sin(t * 2 * pi + i) * 4;
      canvas.drawCircle(center, rad, paint);
    }
  }

  void _halftone(Canvas canvas, Size size, MoxPalette p) {
    final paint = Paint()..color = p.accent.withValues(alpha: 0.07);
    const gap = 22.0;
    for (var y = 0.0; y < size.height; y += gap) {
      for (var x = 0.0; x < size.width; x += gap) {
        final d = (Offset(x, y) - Offset(size.width, 0)).distance / size.width;
        final radius = (1.6 * (1 - d)).clamp(0.0, 1.8);
        if (radius > 0.1) canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TexturePainter old) =>
      old.skin.seed != skin.seed || old.t != t || old.skin.texture != skin.texture;
}

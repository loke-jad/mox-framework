// typography.dart — resolves a MoxType pairing into real TextStyles.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'skin.dart';

class MoxFonts {
  final MoxType type;
  const MoxFonts(this.type);

  TextStyle _safe(String family,
      {double? size, FontWeight? weight, Color? color, double? spacing, double? height}) {
    try {
      return GoogleFonts.getFont(family,
          fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing, height: height);
    } catch (_) {
      // Never crash on a missing font — fall back to a neutral system style.
      return TextStyle(
          fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing, height: height);
    }
  }

  TextStyle display({double size = 40, FontWeight weight = FontWeight.w600, Color? color, double spacing = -0.5}) =>
      _safe(type.display, size: size, weight: weight, color: color, spacing: spacing, height: 1.02);

  TextStyle body({double size = 16, FontWeight weight = FontWeight.w400, Color? color, double height = 1.5}) =>
      _safe(type.body, size: size, weight: weight, color: color, height: height);

  TextStyle mono({double size = 13, FontWeight weight = FontWeight.w500, Color? color, double spacing = 1.5}) =>
      _safe(type.mono, size: size, weight: weight, color: color, spacing: spacing);
}

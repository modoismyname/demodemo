import 'package:flutter/material.dart';

import 'services/fonts.dart';

const brandGreen = Color(0xFF1F7A4D);
const teamColors = [Color(0xFF2563EB), Color(0xFFDC2626), Color(0xFFD97706)];
const benchColor = Color(0xFF6B7280);
const warnColor = Color(0xFFB26A00);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandGreen,
    brightness: brightness,
    primary: brightness == Brightness.light ? brandGreen : const Color(0xFF4CC38A),
  );
  return ThemeData(
    colorScheme: scheme,
    fontFamily: appFont,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: brightness == Brightness.light ? brandGreen : scheme.surface,
      foregroundColor: Colors.white,
    ),
  );
}

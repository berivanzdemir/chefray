import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7FBF9),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF17C878),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF0D3230),
        onSurfaceVariant: Color(0xFF6F8A88),
      ),
      dividerColor: const Color(0xFFE8EFEC),
      splashFactory: InkSparkle.splashFactory,
      fontFamily: 'SF Pro Display',
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0F1715),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF24D98B),
        surface: Color(0xFF17211F),
        onSurface: Color(0xFFF3FFFA),
        onSurfaceVariant: Color(0xFFA9C7BF),
      ),
      dividerColor: const Color(0xFF263633),
      splashFactory: InkSparkle.splashFactory,
      fontFamily: 'SF Pro Display',
    );
  }
}

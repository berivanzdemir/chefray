import 'package:flutter/material.dart';

/// ChefRay Design System Colors
/// Locked to the brand identity — do not modify without design approval.
class AppColors {
  AppColors._();

  // ── Primary ──────────────────────────────────────────────
  static const Color primary = Color(0xFF17C878);
  static const Color primaryDark = Color(0xFF0DBD6D);
  static const Color primaryLight = Color(0xFF25E58A);
  static const Color primaryGlow = Color(0x3317C878); // 20% opacity glow

  // ── Text ─────────────────────────────────────────────────
  static const Color textDark = Color(0xFF0D3230);
  static const Color textMedium = Color(0xFF4A6B6B);
  static const Color textLight = Color(0xFF6F8A88); // secondary text
  static const Color textHint = Color(0xFFB0C9C9);

  // ── Background ───────────────────────────────────────────
  static const Color background = Color(0xFFF7FBF9);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundMint = Color(0xFFF0FBF6);
  static const Color backgroundCard = Color(0xFFFFFFFF);

  // ── Surface / Cards ──────────────────────────────────────
  static const Color cardShadow = Color(0x0D000000); // extremely subtle shadow
  static const Color cardBorder = Color(0x0D17C878); // very subtle green border
  static const Color divider = Color(0xFFE8EFEC);

  // ── Macros ───────────────────────────────────────────────
  static const Color protein = Color(0xFF17C878);
  static const Color carbs = Color(0xFFFFA726);
  static const Color fat = Color(0xFFFF6B6B);

  // ── Status ───────────────────────────────────────────────
  static const Color success = Color(0xFF17C878);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF2EA8F2); // water blue

  // ── Navigation ───────────────────────────────────────────
  static const Color navActive = Color(0xFF17C878);
  static const Color navInactive = Color(0xFFB0C9C9);

  // ── Gradients ────────────────────────────────────────────
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7FBF9), Color(0xFFF0FBF6), Color(0xFFE4F5EC)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF25E58A), Color(0xFF0DBD6D)],
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x0017C878), Color(0x1A17C878)],
  );
}

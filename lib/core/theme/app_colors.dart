import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary ──────────────────────────────────────────
  static const Color primaryLight = Color(0xFF1A6BCC);
  static const Color primaryDark  = Color(0xFF0F4A99);
  static const Color primaryBright = Color(0xFF4D9EFF); // dark mode primary

  // ── Secondary ────────────────────────────────────────
  static const Color secondaryLight  = Color(0xFF00A896);
  static const Color secondaryDark   = Color(0xFF00C4B0);
  static const Color secondarySoft   = Color(0xFFE6F7F5);

  // ── Backgrounds ──────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark  = Color(0xFF0D1117);

  // ── Surfaces ─────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark  = Color(0xFF161B22);

  // ── Chat Bubbles ─────────────────────────────────────
  static const Color userBubbleLight = Color(0xFFE8F1FD);
  static const Color userBubbleDark  = Color(0xFF1C3557);
  static const Color aiBubbleLight   = Color(0xFFF1F3F4);
  static const Color aiBubbleDark    = Color(0xFF1E2329);

  // ── Text ─────────────────────────────────────────────
  static const Color textPrimaryLight   = Color(0xFF1A1F36);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark    = Color(0xFFE6EDF3);
  static const Color textSecondaryDark  = Color(0xFF8B949E);

  // ── Utility ──────────────────────────────────────────
  static const Color error       = Color(0xFFE53E3E);
  static const Color dividerLight = Color(0xFFE5E7EB);
  static const Color dividerDark  = Color(0xFF21262D);
  static const Color white        = Color(0xFFFFFFFF);
  static const Color black        = Color(0xFF000000);

  // ── Gradient ─────────────────────────────────────────
  static const LinearGradient splashGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A6BCC), Color(0xFF00A896)],
  );

  static const LinearGradient splashGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F4A99), Color(0xFF007A6E)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1A6BCC), Color(0xFF00A896)],
  );
}
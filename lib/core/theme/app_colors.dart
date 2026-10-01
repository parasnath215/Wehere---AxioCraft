import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents
  static const Color primary = Color(0xFF5E4BEE);
  static const Color primaryLight = Color(0xFF8B7CF8);
  static const Color primaryDark = Color(0xFF4534C7);
  static const Color primarySoft = Color(0xFFF0EEFF);
  static const Color primaryBorder = Color(0xFFDDD6FE);

  // Background & Surfaces
  static const Color background = Color(0xFFF8F8FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF3F3FA);
  static const Color cardBorder = Color(0xFFECEBF7);

  // Text Colors
  static const Color textPrimary = Color(0xFF191632);
  static const Color textSecondary = Color(0xFF6B6984);
  static const Color textMuted = Color(0xFF9E9DB5);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status & Semantic Colors
  static const Color onlineGreen = Color(0xFF22C55E);
  static const Color greenSoft = Color(0xFFE7F9EE);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color orangeSoft = Color(0xFFFFF3E0);
  static const Color sosRed = Color(0xFFEF4444);
  static const Color sosRedGlow = Color(0xFFFF5252);
  static const Color redSoft = Color(0xFFFDE8E8);
  static const Color blueAccent = Color(0xFF3B82F6);
  static const Color blueSoft = Color(0xFFEFF6FF);
  static const Color starPink = Color(0xFFFF4081);
  static const Color starPinkSoft = Color(0xFFFCE4EC);

  // Dark Celebration Theme (Match Screen)
  static const Color darkBg = Color(0xFF0F0D24);
  static const Color darkCard = Color(0xFF1B163B);
  static const Color darkCardHighlight = Color(0xFF251E52);
  static const Color neonPurpleGlow = Color(0xFFA855F7);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6D54FF), Color(0xFF533FEB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFFF1EFFF), Color(0xFFE9E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient matchCelebrationGradient = LinearGradient(
    colors: [Color(0xFF0F0D24), Color(0xFF1F174A), Color(0xFF0F0D24)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sosGlowGradient = LinearGradient(
    colors: [Color(0xFFFF536B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primarySoft = Color(0xFFEEEDFB);
  static const Color primaryBorder = Color(0xFFDDD6FE);

  // Background & Surfaces
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF3F4FA);
  static const Color cardBorder = Color(0xFFEFF1F7);

  // Text Colors
  static const Color textPrimary = Color(0xFF141838);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Deep Navy Breathing Card
  static const Color deepNavyCard = Color(0xFF1B2252);
  static const Color deepNavyGlow = Color(0xFF283375);

  // Streak tracker
  static const Color streakFilled = Color(0xFF4338CA);
  static const Color streakEmpty = Color(0xFFECEEF5);

  // Mood Tracker Colors
  static const Color moodGreatBg = Color(0xFFEBE8FC);
  static const Color moodGreat = Color(0xFF5B41E1);
  static const Color moodGoodBg = Color(0xFFE8F1FC);
  static const Color moodGood = Color(0xFF3B82F6);
  static const Color moodOkayBg = Color(0xFFFCE8F0);
  static const Color moodOkay = Color(0xFFD94680);
  static const Color moodLowBg = Color(0xFFE0F4FB);
  static const Color moodLow = Color(0xFF0284C7);
  static const Color moodStrugglingBg = Color(0xFFE2F4F2);
  static const Color moodStruggling = Color(0xFF0D9488);

  // Action Items Colors
  static const Color actionPinkBg = Color(0xFFFDE8F1);
  static const Color actionPink = Color(0xFFBE185D);
  static const Color actionPurpleBg = Color(0xFFEEEDFC);
  static const Color actionPurple = Color(0xFF4338CA);
  static const Color actionBlueBg = Color(0xFFE0F2FE);
  static const Color actionBlue = Color(0xFF0284C7);

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
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
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

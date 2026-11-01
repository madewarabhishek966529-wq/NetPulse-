import 'package:flutter/material.dart';

class AppColors {
  // Dark futuristic palette
  static const Color darkBg = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF101726);
  static const Color darkCard = Color(0xFF161F33);
  static const Color darkCardHover = Color(0xFF1E2B45);
  static const Color darkBorder = Color(0xFF22304E);
  static const Color darkDivider = Color(0xFF1B243B);

  // Accents
  static const Color electricBlue = Color(0xFF00E5FF);
  static const Color cyberCyan = Color(0xFF00F0FF);
  static const Color vibrantBlue = Color(0xFF0066FF);
  static const Color neonPurple = Color(0xFF7C4DFF);
  static const Color deepPurple = Color(0xFF651FFF);
  static const Color emeraldGreen = Color(0xFF00E676);
  static const Color amberWarning = Color(0xFFFFB300);
  static const Color coralRed = Color(0xFFFF5252);

  // Text Dark Mode
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Light futuristic palette
  static const Color lightBg = Color(0xFFF4F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF0F4FA);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDivider = Color(0xFFEDF2F7);

  // Text Light Mode
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [electricBlue, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlassGradientDark = LinearGradient(
    colors: [Color(0x2200E5FF), Color(0x057C4DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient speedChartGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}


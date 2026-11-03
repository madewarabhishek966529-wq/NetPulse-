import 'package:flutter/material.dart';

/// NetPulse Theme Color System
/// Precision crafted to match the luxury Obsidian Violet & Soft Lavender palette:
///
///   Swatch 1: #17151C (Obsidian Black canvas)
///   Swatch 2: #292531 (Deep Plum Slate card surface)
///   Swatch 3: #45404F (Medium Slate Violet border & hover)
///   Swatch 4: #716879 (Muted Mauve Slate inactive & hints)
///   Swatch 5: #AAA2B3 (Lavender Ash secondary metadata)
///   Swatch 6: #E2DDE7 (Pearl Lavender crisp foreground text)
class AppColors {
  // Master Reference Palette
  static const Color swatch1Obsidian = Color(0xFF17151C);
  static const Color swatch2SlateViolet = Color(0xFF292531);
  static const Color swatch3MediumSlate = Color(0xFF45404F);
  static const Color swatch4MutedMauve = Color(0xFF716879);
  static const Color swatch5LavenderAsh = Color(0xFFAAA2B3);
  static const Color swatch6LavenderPearl = Color(0xFFE2DDE7);

  // Dark Theme Structural Layers
  static const Color darkBg = swatch1Obsidian;             // #17151C
  static const Color darkSurface = Color(0xFF1E1A25);      // Deep elevation
  static const Color darkCard = swatch2SlateViolet;        // #292531
  static const Color darkCardHover = Color(0xFF383242);    // Refined hover elevation
  static const Color darkBorder = swatch3MediumSlate;      // #45404F
  static const Color darkDivider = Color(0xFF352F3E);     // Subtle separator

  // Radiant Luxury Accents & Glow Highlights
  static const Color electricBlue = Color(0xFFC4A1FF);     // Luminescent Lavender Accent
  static const Color cyberCyan = swatch6LavenderPearl;     // #E2DDE7 Pearl White
  static const Color vibrantBlue = Color(0xFFA582F7);      // Radiant Amethyst
  static const Color neonPurple = Color(0xFF9065E0);       // Deep Purple Glow
  static const Color deepPurple = Color(0xFF7044BA);       // Rich Royal Violet
  static const Color emeraldGreen = Color(0xFF34D399);     // Soft Mint / Success
  static const Color amberWarning = Color(0xFFFBBF24);     // Warm Amber / Queued
  static const Color coralRed = Color(0xFFF87171);         // Soft Rose / Error

  // Text Dark Mode
  static const Color textPrimaryDark = swatch6LavenderPearl;  // #E2DDE7
  static const Color textSecondaryDark = swatch5LavenderAsh;  // #AAA2B3
  static const Color textMutedDark = swatch4MutedMauve;       // #716879

  // Light Theme Structural Layers (Harmonized Inverse)
  static const Color lightBg = Color(0xFFF7F5FA);             // Soft tinted lavender-white
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFEDE8F2);
  static const Color lightBorder = Color(0xFFDCD5E4);
  static const Color lightDivider = Color(0xFFECE6F2);

  // Text Light Mode
  static const Color textPrimaryLight = swatch1Obsidian;     // #17151C
  static const Color textSecondaryLight = swatch3MediumSlate;// #45404F
  static const Color textMutedLight = swatch4MutedMauve;     // #716879

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [swatch6LavenderPearl, electricBlue, vibrantBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [swatch6LavenderPearl, electricBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlassGradientDark = LinearGradient(
    colors: [Color(0x22C4A1FF), Color(0x0645404F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient speedChartGradient = LinearGradient(
    colors: [electricBlue, swatch3MediumSlate],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

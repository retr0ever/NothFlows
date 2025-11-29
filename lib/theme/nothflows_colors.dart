import 'package:flutter/material.dart';

/// NothFlows color system - Nothing OS inspired palette
class NothFlowsColors {
  NothFlowsColors._();

  // === CORE BRAND COLORS ===
  static const Color nothingRed = Color(0xFFD71921);
  static const Color nothingWhite = Color(0xFFFFFFFF);
  static const Color nothingBlack = Color(0xFF000000);

  // === SURFACE COLORS ===
  static const Color surfaceDark = Color(0xFF0D0D0D);
  static const Color surfaceDarkAlt = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color surfaceLightAlt = Color(0xFFFFFFFF);

  // === BORDER COLORS ===
  static const Color borderDark = Color(0xFF2A2A2A);
  static const Color borderDarkFocus = Color(0xFF3D3D3D);
  static const Color borderLight = Color(0xFFE0E0E0);

  // === TEXT COLORS (Dark Mode) ===
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF808080);
  static const Color textDisabled = Color(0xFF4D4D4D);

  // === TEXT COLORS (Light Mode) ===
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0xFF4D4D4D);
  static const Color textTertiaryLight = Color(0xFF808080);
  static const Color textDisabledLight = Color(0xFFB3B3B3);

  // === MODE CATEGORY COLORS ===
  static const Color visionBlue = Color(0xFF4DA6FF);
  static const Color motorPurple = Color(0xFF9F7AEA);
  static const Color neuroMagenta = Color(0xFFE879F9);
  static const Color calmTeal = Color(0xFF2DD4BF);
  static const Color hearingAmber = Color(0xFFFBBF24);
  static const Color hearingPink = Color(0xFFFF4D9F);
  static const Color customGreen = Color(0xFF4ADE80);

  // === SEMANTIC COLORS ===
  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF60A5FA);

  // === INTERACTION STATES ===
  static const Color activeGlow = Color(0x33D71921);
  static const Color pressedOverlay = Color(0x1AFFFFFF);
  static const Color hoverOverlay = Color(0x0DFFFFFF);

  // === HELPER METHODS ===
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vision':
        return visionBlue;
      case 'motor':
        return motorPurple;
      case 'neurodivergent':
        return neuroMagenta;
      case 'calm':
        return calmTeal;
      case 'hearing':
        return hearingAmber;
      case 'custom':
        return customGreen;
      default:
        return textSecondary;
    }
  }

  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}

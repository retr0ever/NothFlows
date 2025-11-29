import 'package:flutter/material.dart';
import 'nothflows_colors.dart';

/// NothFlows shape system - border radii, shadows, borders
class NothFlowsShapes {
  NothFlowsShapes._();

  // === BORDER RADII ===
  static const double radiusNone = 0;
  static const double radiusXs = 4.0;    // Tiny elements (badges)
  static const double radiusSm = 8.0;    // Small controls (chips)
  static const double radiusMd = 12.0;   // Buttons, inputs
  static const double radiusLg = 16.0;   // Cards, tiles
  static const double radiusXl = 20.0;   // Panels, sheets
  static const double radiusXxl = 24.0;  // Large cards, modals
  static const double radiusFull = 100.0; // Pills, toggles

  // === BORDER RADIUS OBJECTS ===
  static final BorderRadius borderRadiusXs = BorderRadius.circular(radiusXs);
  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadiusXxl = BorderRadius.circular(radiusXxl);
  static final BorderRadius borderRadiusFull = BorderRadius.circular(radiusFull);

  // === BORDER WIDTHS ===
  static const double borderThin = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;

  // === ELEVATION (subtle, Nothing-style) ===
  static List<BoxShadow> get elevationNone => [];

  static List<BoxShadow> get elevationLow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elevationMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevationHigh => [
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // === ACTIVE GLOW (for Nothing Red accents) ===
  static List<BoxShadow> get activeGlow => [
    BoxShadow(
      color: NothFlowsColors.nothingRed.withOpacity(0.25),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // === COMMON BORDERS ===
  static Border get borderDefault => Border.all(
    color: NothFlowsColors.borderDark,
    width: borderThin,
  );

  static Border get borderFocus => Border.all(
    color: NothFlowsColors.borderDarkFocus,
    width: borderThin,
  );

  static Border get borderActive => Border.all(
    color: NothFlowsColors.nothingRed,
    width: borderThick,
  );

  static Border borderColored(Color color, {double width = borderThin}) => Border.all(
    color: color,
    width: width,
  );

  // === COMMON DECORATIONS ===
  static BoxDecoration cardDecoration({
    bool isDark = true,
    bool isActive = false,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: isDark ? NothFlowsColors.surfaceDark : NothFlowsColors.surfaceLightAlt,
      borderRadius: borderRadiusLg,
      border: Border.all(
        color: isActive
            ? NothFlowsColors.nothingRed
            : (borderColor ?? NothFlowsColors.borderDark),
        width: isActive ? borderThick : borderThin,
      ),
      boxShadow: isActive ? activeGlow : elevationNone,
    );
  }

  static BoxDecoration panelDecoration({
    bool isDark = true,
    double radius = radiusLg,
  }) {
    return BoxDecoration(
      color: isDark ? NothFlowsColors.surfaceDark : NothFlowsColors.surfaceLightAlt,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark ? NothFlowsColors.borderDark : NothFlowsColors.borderLight,
        width: borderThin,
      ),
    );
  }

  static BoxDecoration sheetDecoration({bool isDark = true}) {
    return BoxDecoration(
      color: isDark ? NothFlowsColors.surfaceDarkAlt : NothFlowsColors.surfaceLightAlt,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(radiusXxl),
      ),
    );
  }
}

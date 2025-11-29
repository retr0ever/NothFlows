import 'package:flutter/material.dart';

/// NothFlows spacing system based on 4px grid
class NothFlowsSpacing {
  NothFlowsSpacing._();

  // === BASE UNIT: 4px ===
  static const double unit = 4.0;

  // === SPACING SCALE ===
  static const double xxs = 4.0;   // 1 unit - Tight internal spacing
  static const double xs = 8.0;    // 2 units - Inline elements
  static const double sm = 12.0;   // 3 units - Related elements
  static const double md = 16.0;   // 4 units - Standard component spacing
  static const double lg = 24.0;   // 6 units - Section spacing
  static const double xl = 32.0;   // 8 units - Major sections
  static const double xxl = 48.0;  // 12 units - Screen-level spacing
  static const double xxxl = 64.0; // 16 units - Hero spacing

  // === CONTENT PADDING ===
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 24.0,
  );

  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: 24.0,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);

  static const EdgeInsets compactCardPadding = EdgeInsets.all(16.0);

  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 14.0,
  );

  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 8.0,
  );

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 16.0,
  );

  // === RESPONSIVE HELPERS ===
  static EdgeInsets responsiveScreenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return EdgeInsets.symmetric(
      horizontal: width < 400 ? 16.0 : 24.0,
      vertical: 24.0,
    );
  }

  static double responsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 400 ? 16.0 : 24.0;
  }
}

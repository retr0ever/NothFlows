import 'package:flutter/material.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_shapes.dart';
import '../theme/nothflows_spacing.dart';

/// Panel variants
enum NothPanelVariant { standard, elevated, bordered }

/// Reusable panel widget following Nothing design language
/// Replaces the old GlassPanel with a solid, Nothing-style approach
class NothPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final VoidCallback? onTap;
  final NothPanelVariant variant;
  final bool isActive;

  const NothPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = NothFlowsShapes.radiusLg,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    this.variant = NothPanelVariant.standard,
    this.isActive = false,
  });

  /// Standard panel with subtle border
  const NothPanel.standard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = NothFlowsShapes.radiusLg,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    this.isActive = false,
  }) : variant = NothPanelVariant.standard;

  /// Elevated panel with shadow
  const NothPanel.elevated({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = NothFlowsShapes.radiusLg,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    this.isActive = false,
  }) : variant = NothPanelVariant.elevated;

  /// Bordered panel with accent color border
  const NothPanel.bordered({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = NothFlowsShapes.radiusLg,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    this.isActive = false,
  }) : variant = NothPanelVariant.bordered;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveBackgroundColor = backgroundColor ??
        (isDark ? NothFlowsColors.surfaceDark : NothFlowsColors.surfaceLightAlt);

    final effectiveBorderColor = borderColor ??
        (isActive
            ? NothFlowsColors.nothingRed
            : (isDark ? NothFlowsColors.borderDark : NothFlowsColors.borderLight));

    final effectiveBorderWidth = borderWidth ??
        (isActive ? NothFlowsShapes.borderThick : NothFlowsShapes.borderThin);

    List<BoxShadow> shadows;
    switch (variant) {
      case NothPanelVariant.elevated:
        shadows = NothFlowsShapes.elevationLow;
        break;
      case NothPanelVariant.bordered:
      case NothPanelVariant.standard:
        shadows = isActive ? NothFlowsShapes.activeGlow : NothFlowsShapes.elevationNone;
        break;
    }

    Widget content = Container(
      padding: padding ?? NothFlowsSpacing.cardPadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: effectiveBorderWidth,
        ),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}

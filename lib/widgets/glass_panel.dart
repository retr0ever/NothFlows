import 'package:flutter/material.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_shapes.dart';

/// Glassmorphic panel widget adjusted for NothingOS aesthetic
/// @deprecated Use NothPanel instead for new code
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final double blur;
  final Border? border;
  final VoidCallback? onTap;
  final double elevation;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.color,
    this.blur = 0,
    this.border,
    this.onTap,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use new theme colors
    final baseColor = color ??
        (isDark
            ? NothFlowsColors.surfaceDark
            : NothFlowsColors.surfaceLight);

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            Border.all(
              color: isDark
                  ? NothFlowsColors.borderDark
                  : NothFlowsColors.borderLight,
              width: NothFlowsShapes.borderThin,
            ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: elevation,
                  offset: Offset(0, elevation / 2),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }
}

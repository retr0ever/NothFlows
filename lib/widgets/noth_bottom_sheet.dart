import 'package:flutter/material.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';
import '../theme/nothflows_spacing.dart';

/// Standardized bottom sheet following Nothing design language
class NothBottomSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final bool showHandle;
  final bool showDivider;
  final EdgeInsetsGeometry? padding;

  const NothBottomSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.actions,
    this.showHandle = true,
    this.showDivider = true,
    this.padding,
  });

  /// Show the bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    List<Widget>? actions,
    bool showHandle = true,
    bool showDivider = true,
    bool isScrollControlled = true,
    bool isDismissible = true,
    EdgeInsetsGeometry? padding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      builder: (context) => NothBottomSheet(
        title: title,
        subtitle: subtitle,
        actions: actions,
        showHandle: showHandle,
        showDivider: showDivider,
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark
            ? NothFlowsColors.surfaceDarkAlt
            : NothFlowsColors.surfaceLightAlt,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(NothFlowsShapes.radiusXxl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            if (showHandle)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? NothFlowsColors.borderDark
                        : NothFlowsColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

            // Header
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title!,
                      style: NothFlowsTypography.displaySmall.copyWith(
                        color: isDark
                            ? NothFlowsColors.textPrimary
                            : NothFlowsColors.textPrimaryLight,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: NothFlowsTypography.bodyMedium.copyWith(
                          color: isDark
                              ? NothFlowsColors.textSecondary
                              : NothFlowsColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Divider
            if (showDivider && title != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(
                  height: 1,
                  color: isDark
                      ? NothFlowsColors.borderDark
                      : NothFlowsColors.borderLight,
                ),
              ),

            // Content
            Flexible(
              child: Padding(
                padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
                child: child,
              ),
            ),

            // Actions
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: actions!
                      .asMap()
                      .entries
                      .expand((entry) => [
                            if (entry.key > 0) const SizedBox(width: 12),
                            Expanded(child: entry.value),
                          ])
                      .toList(),
                ),
              ),

            // Bottom spacing if no actions
            if (actions == null || actions!.isEmpty)
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Sheet handle widget for custom sheets
class NothSheetHandle extends StatelessWidget {
  const NothSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDark
              ? NothFlowsColors.borderDark
              : NothFlowsColors.borderLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

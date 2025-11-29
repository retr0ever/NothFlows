import 'package:flutter/material.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';

/// Custom list tile widget following Nothing design language
class NothListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final Color? leadingBackgroundColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool showChevron;
  final bool enabled;

  const NothListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leadingIconColor,
    this.leadingBackgroundColor,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.showChevron = false,
    this.enabled = true,
  });

  /// List tile with chevron trailing
  const NothListTile.navigation({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leadingIconColor,
    this.leadingBackgroundColor,
    this.onTap,
    this.enabled = true,
  })  : trailing = null,
        isDestructive = false,
        showChevron = true;

  /// Destructive list tile for dangerous actions
  const NothListTile.destructive({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.onTap,
    this.enabled = true,
  })  : trailing = null,
        isDestructive = true,
        showChevron = false,
        leadingIconColor = NothFlowsColors.error,
        leadingBackgroundColor = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opacity = enabled ? 1.0 : 0.5;

    final effectiveLeadingColor = isDestructive
        ? NothFlowsColors.error
        : (leadingIconColor ??
            (isDark
                ? NothFlowsColors.textPrimary
                : NothFlowsColors.textPrimaryLight));

    final effectiveBackgroundColor = leadingBackgroundColor ??
        effectiveLeadingColor.withOpacity(0.1);

    final titleColor = isDestructive
        ? NothFlowsColors.error
        : (isDark
            ? NothFlowsColors.textPrimary
            : NothFlowsColors.textPrimaryLight);

    final subtitleColor = isDark
        ? NothFlowsColors.textSecondary
        : NothFlowsColors.textSecondaryLight;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: NothFlowsShapes.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Leading icon
                if (leadingIcon != null)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: effectiveBackgroundColor,
                      borderRadius: NothFlowsShapes.borderRadiusSm,
                    ),
                    child: Icon(
                      leadingIcon,
                      color: effectiveLeadingColor,
                      size: 20,
                    ),
                  ),

                if (leadingIcon != null) const SizedBox(width: 12),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: NothFlowsTypography.bodyLarge.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: NothFlowsTypography.bodySmall.copyWith(
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing
                if (trailing != null) trailing!,

                if (showChevron)
                  Icon(
                    Icons.chevron_right,
                    color: isDark
                        ? NothFlowsColors.textTertiary
                        : NothFlowsColors.textTertiaryLight,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

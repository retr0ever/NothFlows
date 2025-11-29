import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_spacing.dart';
import 'noth_button.dart';

/// Empty state widget following Nothing design language
class NothEmptyState extends StatelessWidget {
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final bool showLogo;

  const NothEmptyState({
    super.key,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: NothFlowsSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo or icon
          if (showLogo)
            Opacity(
              opacity: 0.15,
              child: SvgPicture.asset(
                'assets/icons/nothflows_logo.svg',
                width: 64,
                height: 64,
                colorFilter: ColorFilter.mode(
                  isDark
                      ? NothFlowsColors.textPrimary
                      : NothFlowsColors.textPrimaryLight,
                  BlendMode.srcIn,
                ),
              ),
            )
          else if (icon != null)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (isDark
                        ? NothFlowsColors.textPrimary
                        : NothFlowsColors.textPrimaryLight)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: (isDark
                        ? NothFlowsColors.textPrimary
                        : NothFlowsColors.textPrimaryLight)
                    .withOpacity(0.5),
              ),
            ),

          const SizedBox(height: NothFlowsSpacing.lg),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: NothFlowsTypography.headingMedium.copyWith(
              color: isDark
                  ? NothFlowsColors.textPrimary
                  : NothFlowsColors.textPrimaryLight,
            ),
          ),

          // Description
          if (description != null) ...[
            const SizedBox(height: NothFlowsSpacing.xs),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: NothFlowsTypography.bodyMedium.copyWith(
                color: isDark
                    ? NothFlowsColors.textSecondary
                    : NothFlowsColors.textSecondaryLight,
              ),
            ),
          ],

          // Action button
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: NothFlowsSpacing.lg),
            NothButton.secondary(
              label: actionLabel!,
              onPressed: onAction,
              isExpanded: false,
            ),
          ],
        ],
      ),
    );
  }
}

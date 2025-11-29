import 'package:flutter/material.dart';
import '../models/mode_model.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_shapes.dart';
import '../theme/nothflows_typography.dart';

/// Card displaying a mode summary (NothingOS style)
/// @deprecated Use NothModeCard instead for new code
class ModeCard extends StatelessWidget {
  final ModeModel mode;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const ModeCard({
    super.key,
    required this.mode,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flows = mode.flows.length;

    return InkWell(
      onTap: onTap,
      borderRadius: NothFlowsShapes.borderRadiusXl,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? NothFlowsColors.surfaceDark
              : NothFlowsColors.surfaceLight,
          borderRadius: NothFlowsShapes.borderRadiusXl,
          border: Border.all(
            color: mode.isActive
                ? NothFlowsColors.nothingRed
                : (isDark
                    ? NothFlowsColors.borderDark
                    : NothFlowsColors.borderLight),
            width: mode.isActive
                ? NothFlowsShapes.borderThick
                : NothFlowsShapes.borderThin,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon in a dot-matrix-like container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: mode.isActive
                        ? NothFlowsColors.nothingRed.withOpacity(0.1)
                        : (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05)),
                    borderRadius: NothFlowsShapes.borderRadiusMd,
                  ),
                  child: Icon(
                    mode.icon,
                    color: mode.isActive
                        ? NothFlowsColors.nothingRed
                        : (isDark
                            ? NothFlowsColors.textPrimary
                            : NothFlowsColors.textPrimaryLight),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),

                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: mode.color.withOpacity(0.15),
                    borderRadius: NothFlowsShapes.borderRadiusSm,
                  ),
                  child: Text(
                    mode.category.toUpperCase(),
                    style: NothFlowsTypography.labelSmall.copyWith(
                      color: mode.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const Spacer(),

                // Toggle Switch (Custom Nothing Style)
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 56,
                    height: 32,
                    decoration: BoxDecoration(
                      color: mode.isActive
                          ? NothFlowsColors.nothingRed
                          : (isDark
                              ? NothFlowsColors.borderDark
                              : NothFlowsColors.borderLight),
                      borderRadius: NothFlowsShapes.borderRadiusFull,
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          left: mode.isActive ? 26 : 2,
                          top: 2,
                          bottom: 2,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? NothFlowsColors.nothingBlack
                                  : NothFlowsColors.nothingWhite,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Mode Name
            Text(
              mode.name.toUpperCase(),
              style: NothFlowsTypography.modeName.copyWith(
                color: isDark
                    ? NothFlowsColors.textPrimary
                    : NothFlowsColors.textPrimaryLight,
              ),
            ),

            const SizedBox(height: 4),

            // Flow Count
            Text(
              '$flows ${flows == 1 ? 'AUTOMATION' : 'AUTOMATIONS'}',
              style: NothFlowsTypography.labelMedium.copyWith(
                color: isDark
                    ? NothFlowsColors.textTertiary
                    : NothFlowsColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

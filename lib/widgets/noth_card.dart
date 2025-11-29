import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/mode_model.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';
import 'noth_toggle.dart';
import 'noth_chip.dart';

/// Mode card widget following Nothing design language
class NothModeCard extends StatelessWidget {
  final ModeModel mode;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const NothModeCard({
    super.key,
    required this.mode,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flows = mode.flows.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: NothFlowsShapes.borderRadiusXl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 140,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? NothFlowsColors.surfaceDark
                : NothFlowsColors.surfaceLightAlt,
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
            boxShadow: mode.isActive
                ? NothFlowsShapes.activeGlow
                : NothFlowsShapes.elevationNone,
          ),
          child: Stack(
            children: [
              // Dot-matrix watermark
              Positioned(
                right: -8,
                bottom: -8,
                child: Opacity(
                  opacity: 0.03,
                  child: SvgPicture.asset(
                    'assets/icons/nothflows_logo.svg',
                    width: 64,
                    height: 64,
                    colorFilter: ColorFilter.mode(
                      isDark
                          ? NothFlowsColors.nothingWhite
                          : NothFlowsColors.nothingBlack,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),

              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Icon, category badge, toggle
                  Row(
                    children: [
                      // Icon container
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: mode.isActive
                              ? NothFlowsColors.nothingRed.withOpacity(0.1)
                              : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05)),
                          borderRadius: NothFlowsShapes.borderRadiusMd,
                        ),
                        child: Icon(
                          mode.icon,
                          color: mode.isActive
                              ? NothFlowsColors.nothingRed
                              : (isDark
                                  ? NothFlowsColors.textSecondary
                                  : NothFlowsColors.textSecondaryLight),
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Category badge
                      NothCategoryBadge(
                        category: mode.category,
                        color: mode.color,
                      ),

                      const Spacer(),

                      // Toggle
                      NothToggle(
                        value: mode.isActive,
                        onChanged: (_) => onToggle(),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Mode name
                  Text(
                    mode.name.toUpperCase(),
                    style: NothFlowsTypography.modeName.copyWith(
                      color: isDark
                          ? NothFlowsColors.textPrimary
                          : NothFlowsColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Flow count with dot prefix
                  Row(
                    children: [
                      // Dot indicators
                      ...List.generate(
                        flows.clamp(0, 4),
                        (index) => Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            color: mode.isActive
                                ? NothFlowsColors.nothingRed
                                : (isDark
                                    ? NothFlowsColors.textTertiary
                                    : NothFlowsColors.textTertiaryLight),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      if (flows > 4) ...[
                        Text(
                          '+',
                          style: NothFlowsTypography.caption.copyWith(
                            color: isDark
                                ? NothFlowsColors.textTertiary
                                : NothFlowsColors.textTertiaryLight,
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

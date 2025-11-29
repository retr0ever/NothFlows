import 'package:flutter/material.dart';
import '../services/automation_executor.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';
import '../theme/nothflows_spacing.dart';
import '../widgets/noth_panel.dart';
import '../widgets/noth_button.dart';

/// Bottom sheet for showing execution results
class ResultsSheet extends StatelessWidget {
  final List<ExecutionResult> results;

  const ResultsSheet({
    super.key,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successCount = results.where((r) => r.success).length;
    final totalCount = results.length;
    final allSuccess = successCount == totalCount;

    final statusColor = allSuccess
        ? NothFlowsColors.success
        : NothFlowsColors.warning;

    return Container(
      padding: const EdgeInsets.all(NothFlowsSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? NothFlowsColors.surfaceDark
            : NothFlowsColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(
            color: isDark
                ? NothFlowsColors.borderDark
                : NothFlowsColors.borderLight,
            width: NothFlowsShapes.borderThin,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? NothFlowsColors.borderDark
                    : NothFlowsColors.borderLight,
                borderRadius: NothFlowsShapes.borderRadiusFull,
              ),
            ),
          ),

          const SizedBox(height: NothFlowsSpacing.lg),

          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: NothFlowsShapes.borderRadiusMd,
                ),
                child: Icon(
                  allSuccess
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: NothFlowsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Execution Results',
                      style: NothFlowsTypography.headingLarge.copyWith(
                        color: isDark
                            ? NothFlowsColors.textPrimary
                            : NothFlowsColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '$successCount/$totalCount actions completed',
                      style: NothFlowsTypography.bodySmall.copyWith(
                        color: isDark
                            ? NothFlowsColors.textSecondary
                            : NothFlowsColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: NothFlowsSpacing.lg),

          // Results list
          ...results.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value;
            final resultColor = result.success
                ? NothFlowsColors.success
                : NothFlowsColors.error;

            return Padding(
              padding: const EdgeInsets.only(bottom: NothFlowsSpacing.sm),
              child: NothPanel(
                padding: const EdgeInsets.all(NothFlowsSpacing.md),
                child: Row(
                  children: [
                    // Step number
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: resultColor.withOpacity(0.15),
                        borderRadius: NothFlowsShapes.borderRadiusSm,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: NothFlowsTypography.labelMedium.copyWith(
                            color: resultColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: NothFlowsSpacing.sm),

                    // Status icon
                    Icon(
                      result.success ? Icons.check : Icons.close,
                      color: resultColor,
                      size: 20,
                    ),

                    const SizedBox(width: NothFlowsSpacing.sm),

                    // Result description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatActionType(result.actionType),
                            style: NothFlowsTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? NothFlowsColors.textPrimary
                                  : NothFlowsColors.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (result.message != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              result.message!,
                              style: NothFlowsTypography.bodySmall.copyWith(
                                color: isDark
                                    ? NothFlowsColors.textSecondary
                                    : NothFlowsColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: NothFlowsSpacing.lg),

          // Close button
          SizedBox(
            width: double.infinity,
            child: NothButton.primary(
              label: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  String _formatActionType(String actionType) {
    return actionType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

import 'package:flutter/material.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../services/recommendation_service.dart';

/// A card displaying a smart suggestion with actions
class SuggestionCard extends StatelessWidget {
  final Recommendation recommendation;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;
  final VoidCallback onBlock;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const SuggestionCard({
    super.key,
    required this.recommendation,
    required this.onAccept,
    required this.onDismiss,
    required this.onBlock,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: NothFlowsColors.surfaceDarkAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NothFlowsColors.info.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: onToggleExpand,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: NothFlowsColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: NothFlowsColors.info,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suggestion',
                          style: NothFlowsTypography.labelSmall.copyWith(
                            color: NothFlowsColors.info,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recommendation.description,
                          style: NothFlowsTypography.bodyMedium.copyWith(
                            color: NothFlowsColors.textPrimary,
                          ),
                          maxLines: isExpanded ? 5 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Expand indicator
                  if (onToggleExpand != null)
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: NothFlowsColors.textSecondary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded) ...[
            Divider(
              height: 1,
              color: NothFlowsColors.borderDark,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Why section
                  Text(
                    'Why this suggestion?',
                    style: NothFlowsTypography.labelSmall.copyWith(
                      color: NothFlowsColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommendation.reason,
                    style: NothFlowsTypography.bodySmall.copyWith(
                      color: NothFlowsColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Confidence indicator
                  Row(
                    children: [
                      Text(
                        'Confidence: ',
                        style: NothFlowsTypography.labelSmall.copyWith(
                          color: NothFlowsColors.textTertiary,
                        ),
                      ),
                      _buildConfidenceIndicator(),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Actions
          Divider(
            height: 1,
            color: NothFlowsColors.borderDark,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Block button (less prominent)
                TextButton(
                  onPressed: onBlock,
                  style: TextButton.styleFrom(
                    foregroundColor: NothFlowsColors.textTertiary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    "Don't suggest",
                    style: NothFlowsTypography.labelSmall,
                  ),
                ),
                const Spacer(),
                // Dismiss button
                TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: NothFlowsColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    'Not now',
                    style: NothFlowsTypography.labelMedium,
                  ),
                ),
                const SizedBox(width: 8),
                // Accept button
                FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: NothFlowsColors.info,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Activate',
                    style: NothFlowsTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    final confidenceText = recommendation.confidence >= 0.8
        ? 'High'
        : recommendation.confidence >= 0.5
            ? 'Medium'
            : 'Low';
    final confidenceColor = recommendation.confidence >= 0.8
        ? NothFlowsColors.success
        : recommendation.confidence >= 0.5
            ? NothFlowsColors.warning
            : NothFlowsColors.textTertiary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: NothFlowsColors.surfaceDark,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: recommendation.confidence,
            child: Container(
              decoration: BoxDecoration(
                color: confidenceColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          confidenceText,
          style: NothFlowsTypography.labelSmall.copyWith(
            color: confidenceColor,
          ),
        ),
      ],
    );
  }
}

/// Compact suggestion banner for minimal intrusion
class SuggestionBanner extends StatelessWidget {
  final Recommendation recommendation;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const SuggestionBanner({
    super.key,
    required this.recommendation,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: NothFlowsColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NothFlowsColors.info.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: NothFlowsColors.info,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recommendation.description,
                    style: NothFlowsTypography.bodySmall.copyWith(
                      color: NothFlowsColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close,
                    color: NothFlowsColors.textTertiary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

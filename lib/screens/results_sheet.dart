import 'package:flutter/material.dart';
import '../services/automation_executor.dart';
import '../widgets/glass_panel.dart';

/// Bottom sheet for showing execution results
class ResultsSheet extends StatelessWidget {
  final List<ExecutionResult> results;

  const ResultsSheet({
    super.key,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final successCount = results.where((r) => r.success).length;
    final totalCount = results.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (successCount == totalCount
                          ? const Color(0xFF4DFF88)
                          : const Color(0xFFFFB84D))
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  successCount == totalCount
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: successCount == totalCount
                      ? const Color(0xFF4DFF88)
                      : const Color(0xFFFFB84D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Execution Results',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '$successCount/$totalCount actions completed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Results list
          ...results.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassPanel(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Step number
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: (result.success
                                ? const Color(0xFF4DFF88)
                                : const Color(0xFFFF4D4D))
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: result.success
                                ? const Color(0xFF4DFF88)
                                : const Color(0xFFFF4D4D),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Status icon
                    Icon(
                      result.success ? Icons.check : Icons.close,
                      color: result.success
                          ? const Color(0xFF4DFF88)
                          : const Color(0xFFFF4D4D),
                      size: 20,
                    ),

                    const SizedBox(width: 12),

                    // Result description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatActionType(result.actionType),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (result.message != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              result.message!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.6),
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

          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: successCount == totalCount
                    ? const Color(0xFF4DFF88)
                    : const Color(0xFFFFB84D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
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

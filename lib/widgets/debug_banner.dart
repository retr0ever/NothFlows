import 'package:flutter/material.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';
import '../theme/nothflows_spacing.dart';

/// Debug banner widget for displaying errors and warnings during testing
class DebugBanner extends StatelessWidget {
  final String? error;
  final String? warning;
  final String? info;
  final VoidCallback? onDismiss;

  const DebugBanner({
    super.key,
    this.error,
    this.warning,
    this.info,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final message = error ?? warning ?? info;
    if (message == null) return const SizedBox.shrink();

    final color = error != null
        ? NothFlowsColors.error
        : warning != null
            ? NothFlowsColors.warning
            : NothFlowsColors.info;

    final icon = error != null
        ? Icons.error_outline
        : warning != null
            ? Icons.warning_amber_outlined
            : Icons.info_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: NothFlowsSpacing.md,
        vertical: NothFlowsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: NothFlowsSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: NothFlowsTypography.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, color: color, size: 18),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Persistent error display at the bottom of the screen
class DebugErrorOverlay extends StatelessWidget {
  final List<String> errors;
  final VoidCallback? onClear;

  const DebugErrorOverlay({
    super.key,
    required this.errors,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: NothFlowsColors.error.withOpacity(0.05),
            border: Border(
              top: BorderSide(
                color: NothFlowsColors.error,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: NothFlowsSpacing.md,
                  vertical: NothFlowsSpacing.xs,
                ),
                color: NothFlowsColors.error.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.bug_report,
                      color: NothFlowsColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: NothFlowsSpacing.xs),
                    Text(
                      'Debug Errors',
                      style: NothFlowsTypography.labelMedium.copyWith(
                        color: NothFlowsColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${errors.length} error${errors.length > 1 ? 's' : ''}',
                      style: NothFlowsTypography.caption.copyWith(
                        color: NothFlowsColors.error.withOpacity(0.8),
                      ),
                    ),
                    if (onClear != null) ...[
                      const SizedBox(width: NothFlowsSpacing.xs),
                      IconButton(
                        icon: Icon(
                          Icons.clear_all,
                          size: 18,
                          color: NothFlowsColors.error,
                        ),
                        onPressed: onClear,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(NothFlowsSpacing.xs),
                  shrinkWrap: true,
                  itemCount: errors.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: NothFlowsColors.error.withOpacity(0.2),
                  ),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: NothFlowsSpacing.xs,
                        vertical: NothFlowsSpacing.xxs,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}.',
                            style: NothFlowsTypography.caption.copyWith(
                              color: NothFlowsColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: NothFlowsSpacing.xs),
                          Expanded(
                            child: Text(
                              errors[index],
                              style: NothFlowsTypography.caption.copyWith(
                                fontFamily: 'monospace',
                                color: NothFlowsColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Snackbar helper for showing errors - uses NothToast pattern
class DebugSnackbar {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: NothFlowsColors.nothingWhite),
            const SizedBox(width: NothFlowsSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: NothFlowsTypography.bodySmall.copyWith(
                  color: NothFlowsColors.nothingWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: NothFlowsColors.error,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
        ),
        margin: const EdgeInsets.all(NothFlowsSpacing.md),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: NothFlowsColors.nothingWhite,
          onPressed: () {},
        ),
      ),
    );
  }

  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: NothFlowsColors.nothingBlack),
            const SizedBox(width: NothFlowsSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: NothFlowsTypography.bodySmall.copyWith(
                  color: NothFlowsColors.nothingBlack,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: NothFlowsColors.warning,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
        ),
        margin: const EdgeInsets.all(NothFlowsSpacing.md),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: NothFlowsColors.nothingWhite),
            const SizedBox(width: NothFlowsSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: NothFlowsTypography.bodySmall.copyWith(
                  color: NothFlowsColors.nothingWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: NothFlowsColors.info,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
        ),
        margin: const EdgeInsets.all(NothFlowsSpacing.md),
      ),
    );
  }
}

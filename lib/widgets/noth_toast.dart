import 'package:flutter/material.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';

/// Toast type variants
enum NothToastType { info, success, error, warning }

/// Custom toast/snackbar widget following Nothing design language
class NothToast {
  NothToast._();

  /// Show a toast message
  static void show(
    BuildContext context,
    String message, {
    NothToastType type = NothToastType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _NothToastContent(
          message: message,
          type: type,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: _getTypeColor(type),
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Show info toast
  static void info(BuildContext context, String message) {
    show(context, message, type: NothToastType.info);
  }

  /// Show success toast
  static void success(BuildContext context, String message) {
    show(context, message, type: NothToastType.success);
  }

  /// Show error toast
  static void error(BuildContext context, String message) {
    show(context, message, type: NothToastType.error);
  }

  /// Show warning toast
  static void warning(BuildContext context, String message) {
    show(context, message, type: NothToastType.warning);
  }

  static Color _getTypeColor(NothToastType type) {
    switch (type) {
      case NothToastType.info:
        return NothFlowsColors.info;
      case NothToastType.success:
        return NothFlowsColors.success;
      case NothToastType.error:
        return NothFlowsColors.error;
      case NothToastType.warning:
        return NothFlowsColors.warning;
    }
  }
}

class _NothToastContent extends StatelessWidget {
  final String message;
  final NothToastType type;

  const _NothToastContent({
    required this.message,
    required this.type,
  });

  Color get _indicatorColor {
    switch (type) {
      case NothToastType.info:
        return NothFlowsColors.info;
      case NothToastType.success:
        return NothFlowsColors.success;
      case NothToastType.error:
        return NothFlowsColors.error;
      case NothToastType.warning:
        return NothFlowsColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? NothFlowsColors.surfaceDarkAlt
            : NothFlowsColors.surfaceLightAlt,
        borderRadius: NothFlowsShapes.borderRadiusMd,
        border: Border.all(
          color: isDark
              ? NothFlowsColors.borderDark
              : NothFlowsColors.borderLight,
        ),
        boxShadow: NothFlowsShapes.elevationLow,
      ),
      child: Row(
        children: [
          // Status indicator dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Message
          Expanded(
            child: Text(
              message,
              style: NothFlowsTypography.bodyMedium.copyWith(
                color: isDark
                    ? NothFlowsColors.textPrimary
                    : NothFlowsColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

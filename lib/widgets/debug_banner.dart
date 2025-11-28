import 'package:flutter/material.dart';

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
        ? Colors.red
        : warning != null
            ? Colors.orange
            : Colors.blue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            error != null
                ? Icons.error_outline
                : warning != null
                    ? Icons.warning_amber_outlined
                    : Icons.info_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
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
            color: Colors.red.shade50,
            border: Border(
              top: BorderSide(color: Colors.red, width: 2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Debug Errors',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${errors.length} error${errors.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                    if (onClear != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear_all, size: 18),
                        color: Colors.red,
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
                  padding: const EdgeInsets.all(8),
                  shrinkWrap: true,
                  itemCount: errors.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}.',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errors[index],
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
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

/// Snackbar helper for showing errors
class DebugSnackbar {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
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
            const Icon(Icons.warning_amber_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/flow_dsl.dart';
import '../widgets/glass_panel.dart';

/// Bottom sheet for previewing a flow before adding it
class FlowPreviewSheet extends StatelessWidget {
  final FlowDSL flow;
  final bool isEditing;

  const FlowPreviewSheet({
    super.key,
    required this.flow,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
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
          ),

          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTriggerColor(flow.trigger).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: _getTriggerColor(flow.trigger),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Flow Details' : 'Preview Flow',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${flow.actions.length} ${flow.actions.length == 1 ? 'action' : 'actions'}',
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

          // Trigger
          GlassPanel(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: _getTriggerColor(flow.trigger),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trigger',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTrigger(flow.trigger),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Actions header
          Text(
            'Actions',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 12),

          // Actions list
          ...flow.actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;

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
                        color: _getActionColor(action.type).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getActionColor(action.type),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Action icon
                    Icon(
                      _getActionIcon(action.type),
                      color: _getActionColor(action.type),
                      size: 20,
                    ),

                    const SizedBox(width: 12),

                    // Action description
                    Expanded(
                      child: Text(
                        _getActionDescription(action),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Buttons
          if (!isEditing)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getTriggerColor(flow.trigger),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add Flow',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  String _formatTrigger(String trigger) {
    final parts = trigger.split(':');
    final mode = parts.last;
    final event = trigger.contains('on') ? 'activated' : 'deactivated';

    return 'When ${mode.toUpperCase()} mode is $event';
  }

  Color _getTriggerColor(String trigger) {
    final mode = trigger.split(':').last;
    switch (mode) {
      case 'sleep':
        return const Color(0xFF5B4DFF);
      case 'focus':
        return const Color(0xFFFF4D4D);
      case 'custom':
        return const Color(0xFF4DFF88);
      default:
        return const Color(0xFF888888);
    }
  }

  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'clean_screenshots':
      case 'clean_downloads':
        return Icons.cleaning_services;
      case 'mute_apps':
        return Icons.notifications_off;
      case 'lower_brightness':
        return Icons.brightness_low;
      case 'set_volume':
        return Icons.volume_down;
      case 'enable_dnd':
        return Icons.do_not_disturb_on;
      case 'disable_wifi':
        return Icons.wifi_off;
      case 'disable_bluetooth':
        return Icons.bluetooth_disabled;
      case 'set_wallpaper':
        return Icons.wallpaper;
      case 'launch_app':
        return Icons.open_in_new;
      default:
        return Icons.settings;
    }
  }

  Color _getActionColor(String actionType) {
    switch (actionType) {
      case 'clean_screenshots':
      case 'clean_downloads':
        return const Color(0xFF4DFF88);
      case 'mute_apps':
      case 'enable_dnd':
        return const Color(0xFFFF4D4D);
      case 'lower_brightness':
      case 'set_volume':
        return const Color(0xFF5B4DFF);
      case 'disable_wifi':
      case 'disable_bluetooth':
        return const Color(0xFFFFB84D);
      case 'set_wallpaper':
        return const Color(0xFFFF4D9F);
      case 'launch_app':
        return const Color(0xFF4DDDFF);
      default:
        return const Color(0xFF888888);
    }
  }

  String _getActionDescription(FlowAction action) {
    switch (action.type) {
      case 'clean_screenshots':
        final days = action.parameters['older_than_days'] ?? 30;
        return 'Clean screenshots older than $days days';
      case 'clean_downloads':
        final days = action.parameters['older_than_days'] ?? 30;
        return 'Clean downloads older than $days days';
      case 'mute_apps':
        final apps = action.parameters['apps'] as List<dynamic>? ?? [];
        return 'Mute notifications: ${apps.join(", ")}';
      case 'lower_brightness':
        final level = action.parameters['to'] ?? 20;
        return 'Set brightness to $level%';
      case 'set_volume':
        final level = action.parameters['level'] ?? 50;
        return 'Set volume to $level%';
      case 'enable_dnd':
        return 'Enable Do Not Disturb';
      case 'disable_wifi':
        return 'Disable Wi-Fi';
      case 'disable_bluetooth':
        return 'Disable Bluetooth';
      case 'set_wallpaper':
        final path = action.parameters['path'] ?? 'default';
        return 'Set wallpaper to $path';
      case 'launch_app':
        final app = action.parameters['app'] ?? 'unknown';
        return 'Launch $app';
      default:
        return action.type;
    }
  }
}

import 'package:flutter/material.dart';
import '../models/flow_dsl.dart';
import 'glass_panel.dart';

/// Tile widget for displaying a flow
class FlowTile extends StatelessWidget {
  final FlowDSL flow;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FlowTile({
    super.key,
    required this.flow,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      onTap: onTap,
      child: Row(
        children: [
          // Icon based on first action type
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getColorForAction(flow.actions.first.type).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForAction(flow.actions.first.type),
              color: _getColorForAction(flow.actions.first.type),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Flow info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action count
                Text(
                  '${flow.actions.length} ${flow.actions.length == 1 ? 'action' : 'actions'}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                // First action preview
                Text(
                  _getActionPreview(flow.actions.first),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Delete button
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDelete,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
        ],
      ),
    );
  }

  IconData _getIconForAction(String actionType) {
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

  Color _getColorForAction(String actionType) {
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

  String _getActionPreview(FlowAction action) {
    switch (action.type) {
      case 'clean_screenshots':
        final days = action.parameters['older_than_days'] ?? 30;
        return 'Clean screenshots ($days days)';
      case 'clean_downloads':
        final days = action.parameters['older_than_days'] ?? 30;
        return 'Clean downloads ($days days)';
      case 'mute_apps':
        final apps = action.parameters['apps'] as List<dynamic>? ?? [];
        return 'Mute ${apps.length} apps';
      case 'lower_brightness':
        final level = action.parameters['to'] ?? 20;
        return 'Brightness to $level%';
      case 'set_volume':
        final level = action.parameters['level'] ?? 50;
        return 'Volume to $level%';
      case 'enable_dnd':
        return 'Enable Do Not Disturb';
      case 'disable_wifi':
        return 'Disable Wi-Fi';
      case 'disable_bluetooth':
        return 'Disable Bluetooth';
      case 'set_wallpaper':
        return 'Change wallpaper';
      case 'launch_app':
        final app = action.parameters['app'] ?? 'app';
        return 'Launch $app';
      default:
        return action.type;
    }
  }
}

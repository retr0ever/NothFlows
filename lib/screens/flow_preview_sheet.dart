import 'package:flutter/material.dart';
import '../models/flow_dsl.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';
import '../theme/nothflows_spacing.dart';
import '../widgets/noth_panel.dart';
import '../widgets/noth_button.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: _getTriggerColor(flow.trigger).withOpacity(0.15),
                  borderRadius: NothFlowsShapes.borderRadiusMd,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: _getTriggerColor(flow.trigger),
                  size: 24,
                ),
              ),
              const SizedBox(width: NothFlowsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Flow Details' : 'Preview Flow',
                      style: NothFlowsTypography.headingLarge.copyWith(
                        color: isDark
                            ? NothFlowsColors.textPrimary
                            : NothFlowsColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '${flow.actions.length} ${flow.actions.length == 1 ? 'action' : 'actions'}',
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

          // Trigger
          NothPanel(
            padding: const EdgeInsets.all(NothFlowsSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: _getTriggerColor(flow.trigger),
                  size: 24,
                ),
                const SizedBox(width: NothFlowsSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRIGGER',
                        style: NothFlowsTypography.labelSmall.copyWith(
                          color: isDark
                              ? NothFlowsColors.textTertiary
                              : NothFlowsColors.textTertiaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTrigger(flow.trigger),
                        style: NothFlowsTypography.bodyMedium.copyWith(
                          color: isDark
                              ? NothFlowsColors.textPrimary
                              : NothFlowsColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: NothFlowsSpacing.md),

          // Actions header
          Text(
            'ACTIONS',
            style: NothFlowsTypography.labelSmall.copyWith(
              color: isDark
                  ? NothFlowsColors.textTertiary
                  : NothFlowsColors.textTertiaryLight,
            ),
          ),

          const SizedBox(height: NothFlowsSpacing.sm),

          // Actions list
          ...flow.actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;

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
                        color: _getActionColor(action.type).withOpacity(0.15),
                        borderRadius: NothFlowsShapes.borderRadiusSm,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: NothFlowsTypography.labelMedium.copyWith(
                            color: _getActionColor(action.type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: NothFlowsSpacing.sm),

                    // Action icon
                    Icon(
                      _getActionIcon(action.type),
                      color: _getActionColor(action.type),
                      size: 20,
                    ),

                    const SizedBox(width: NothFlowsSpacing.sm),

                    // Action description
                    Expanded(
                      child: Text(
                        _getActionDescription(action),
                        style: NothFlowsTypography.bodyMedium.copyWith(
                          color: isDark
                              ? NothFlowsColors.textPrimary
                              : NothFlowsColors.textPrimaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: NothFlowsSpacing.lg),

          // Buttons
          if (!isEditing)
            Row(
              children: [
                Expanded(
                  child: NothButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: NothFlowsSpacing.sm),
                Expanded(
                  flex: 2,
                  child: NothButton.primary(
                    label: 'Add Flow',
                    onPressed: () => Navigator.pop(context, true),
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
    return NothFlowsColors.getCategoryColor(mode);
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
        return NothFlowsColors.success;
      case 'mute_apps':
      case 'enable_dnd':
        return NothFlowsColors.nothingRed;
      case 'lower_brightness':
      case 'set_volume':
        return NothFlowsColors.visionBlue;
      case 'disable_wifi':
      case 'disable_bluetooth':
        return NothFlowsColors.warning;
      case 'set_wallpaper':
        return NothFlowsColors.hearingPink;
      case 'launch_app':
        return NothFlowsColors.info;
      default:
        return NothFlowsColors.textSecondary;
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

import 'package:flutter/material.dart';
import '../models/mode_model.dart';
import 'glass_panel.dart';

/// Card widget for displaying a mode on the home screen
class ModeCard extends StatelessWidget {
  final ModeModel mode;
  final VoidCallback onTap;
  final VoidCallback? onToggle;

  const ModeCard({
    super.key,
    required this.mode,
    required this.onTap,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      elevation: mode.isActive ? 8 : 0,
      border: mode.isActive
          ? Border.all(
              color: mode.color.withOpacity(0.5),
              width: 2,
            )
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and toggle
              Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: mode.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      mode.icon,
                      color: mode.color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  // Toggle switch
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: mode.isActive,
                      onChanged: onToggle != null ? (_) => onToggle!() : null,
                      activeColor: mode.color,
                      inactiveTrackColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Mode name
              Text(
                mode.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 4),

              // Description
              Text(
                mode.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  letterSpacing: 0,
                ),
              ),

              const SizedBox(height: 16),

              // Flow count
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${mode.flows.length} ${mode.flows.length == 1 ? 'flow' : 'flows'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Last activated
              if (mode.lastActivated != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatLastActivated(mode.lastActivated!),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastActivated(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

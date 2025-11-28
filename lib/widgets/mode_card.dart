import 'package:flutter/material.dart';
import '../models/mode_model.dart';
import '../main.dart';

/// Card displaying a mode summary (NothingOS style)
class ModeCard extends StatelessWidget {
  final ModeModel mode;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const ModeCard({
    super.key,
    required this.mode,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flows = mode.flows.length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? NothFlowsApp.nothingDarkGrey : NothFlowsApp.nothingWhite,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: mode.isActive
                ? NothFlowsApp.nothingRed
                : (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
            width: mode.isActive ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon in a dot-matrix-like container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: mode.isActive
                        ? NothFlowsApp.nothingRed.withOpacity(0.1)
                        : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    mode.icon,
                    color: mode.isActive
                        ? NothFlowsApp.nothingRed
                        : (isDark ? Colors.white : Colors.black),
                    size: 24,
                  ),
                ),
                const Spacer(),
                
                // Toggle Switch (Custom Nothing Style)
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 56,
                    height: 32,
                    decoration: BoxDecoration(
                      color: mode.isActive
                          ? NothFlowsApp.nothingRed
                          : (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          left: mode.isActive ? 26 : 2,
                          top: 2,
                          bottom: 2,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black : Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Mode Name
            Text(
              mode.name.toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
                fontFamily: 'Roboto Mono',
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Flow Count
            Text(
              '$flows ${flows == 1 ? 'AUTOMATION' : 'AUTOMATIONS'}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

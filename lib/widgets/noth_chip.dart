import 'package:flutter/material.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';

/// Custom chip widget following Nothing design language
class NothChip extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? selectedColor;
  final IconData? icon;

  const NothChip({
    super.key,
    required this.label,
    this.onTap,
    this.isSelected = false,
    this.selectedColor,
    this.icon,
  });

  @override
  State<NothChip> createState() => _NothChipState();
}

class _NothChipState extends State<NothChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = widget.selectedColor ?? NothFlowsColors.nothingRed;

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (widget.isSelected) {
      backgroundColor = accentColor.withOpacity(0.15);
      borderColor = accentColor;
      textColor = accentColor;
    } else {
      backgroundColor = isDark
          ? NothFlowsColors.surfaceDark
          : NothFlowsColors.surfaceLightAlt;
      borderColor = _isPressed
          ? (isDark ? NothFlowsColors.borderDarkFocus : NothFlowsColors.borderLight)
          : (isDark ? NothFlowsColors.borderDark : NothFlowsColors.borderLight);
      textColor = isDark
          ? NothFlowsColors.textPrimary
          : NothFlowsColors.textPrimaryLight;
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(NothFlowsShapes.radiusFull),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected
                  ? NothFlowsShapes.borderMedium
                  : NothFlowsShapes.borderThin,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: textColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: NothFlowsTypography.bodySmall.copyWith(
                  color: textColor,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category badge chip for mode categories
class NothCategoryBadge extends StatelessWidget {
  final String category;
  final Color? color;

  const NothCategoryBadge({
    super.key,
    required this.category,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? NothFlowsColors.getCategoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(NothFlowsShapes.radiusSm),
      ),
      child: Text(
        category.toUpperCase(),
        style: NothFlowsTypography.labelSmall.copyWith(
          color: effectiveColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

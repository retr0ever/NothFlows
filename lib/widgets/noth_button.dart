import 'package:flutter/material.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';

/// Button variants for NothFlows
enum NothButtonVariant { primary, secondary, ghost, destructive }

/// Custom button widget following Nothing design language
class NothButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final NothButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final double? height;

  const NothButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = NothButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.height,
  });

  /// Primary button - solid red background
  const NothButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.height,
  }) : variant = NothButtonVariant.primary;

  /// Secondary button - outlined style
  const NothButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.height,
  }) : variant = NothButtonVariant.secondary;

  /// Ghost button - text only
  const NothButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.height,
  }) : variant = NothButtonVariant.ghost;

  /// Destructive button - for dangerous actions
  const NothButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    this.height,
  }) : variant = NothButtonVariant.destructive;

  @override
  State<NothButton> createState() => _NothButtonState();
}

class _NothButtonState extends State<NothButton>
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
    if (widget.onPressed != null && !widget.isLoading) {
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
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: widget.height ?? 56,
          width: widget.isExpanded ? double.infinity : null,
          padding: widget.isExpanded
              ? null
              : const EdgeInsets.symmetric(horizontal: 24),
          decoration: _getDecoration(isEnabled),
          child: Center(
            child: widget.isLoading
                ? _buildLoadingIndicator()
                : _buildContent(),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getDecoration(bool isEnabled) {
    final opacity = isEnabled ? 1.0 : 0.5;

    switch (widget.variant) {
      case NothButtonVariant.primary:
        return BoxDecoration(
          color: NothFlowsColors.nothingRed.withOpacity(opacity),
          borderRadius: NothFlowsShapes.borderRadiusMd,
        );

      case NothButtonVariant.secondary:
        return BoxDecoration(
          color: _isPressed
              ? NothFlowsColors.surfaceDark
              : Colors.transparent,
          borderRadius: NothFlowsShapes.borderRadiusMd,
          border: Border.all(
            color: _isPressed
                ? NothFlowsColors.textPrimary
                : NothFlowsColors.borderDark,
            width: NothFlowsShapes.borderMedium,
          ),
        );

      case NothButtonVariant.ghost:
        return BoxDecoration(
          color: _isPressed
              ? NothFlowsColors.surfaceDark
              : Colors.transparent,
          borderRadius: NothFlowsShapes.borderRadiusMd,
        );

      case NothButtonVariant.destructive:
        return BoxDecoration(
          color: NothFlowsColors.error.withOpacity(opacity * 0.1),
          borderRadius: NothFlowsShapes.borderRadiusMd,
          border: Border.all(
            color: NothFlowsColors.error.withOpacity(opacity),
            width: NothFlowsShapes.borderThin,
          ),
        );
    }
  }

  Widget _buildLoadingIndicator() {
    Color color;
    switch (widget.variant) {
      case NothButtonVariant.primary:
        color = NothFlowsColors.nothingWhite;
        break;
      case NothButtonVariant.secondary:
      case NothButtonVariant.ghost:
        color = NothFlowsColors.textPrimary;
        break;
      case NothButtonVariant.destructive:
        color = NothFlowsColors.error;
        break;
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildContent() {
    Color textColor;
    switch (widget.variant) {
      case NothButtonVariant.primary:
        textColor = NothFlowsColors.nothingWhite;
        break;
      case NothButtonVariant.secondary:
        textColor = _isPressed
            ? NothFlowsColors.textPrimary
            : NothFlowsColors.textSecondary;
        break;
      case NothButtonVariant.ghost:
        textColor = _isPressed
            ? NothFlowsColors.nothingRed
            : NothFlowsColors.textSecondary;
        break;
      case NothButtonVariant.destructive:
        textColor = NothFlowsColors.error;
        break;
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: NothFlowsTypography.buttonLarge.copyWith(color: textColor),
          ),
        ],
      );
    }

    return Text(
      widget.label,
      style: NothFlowsTypography.buttonLarge.copyWith(color: textColor),
    );
  }
}

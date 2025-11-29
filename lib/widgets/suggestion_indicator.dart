import 'package:flutter/material.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';

/// A subtle badge indicator showing pending suggestions
class SuggestionIndicator extends StatefulWidget {
  final int count;
  final VoidCallback onTap;
  final bool animate;

  const SuggestionIndicator({
    super.key,
    required this.count,
    required this.onTap,
    this.animate = true,
  });

  @override
  State<SuggestionIndicator> createState() => _SuggestionIndicatorState();
}

class _SuggestionIndicatorState extends State<SuggestionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Only pulse once on first appearance
    if (widget.animate && !_hasAnimated && widget.count > 0) {
      _controller.forward().then((_) {
        _controller.reverse();
        _hasAnimated = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hasAnimated ? 1.0 : _pulseAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: NothFlowsColors.info.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: NothFlowsColors.info.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: NothFlowsColors.info,
              ),
              const SizedBox(width: 4),
              Text(
                widget.count == 1 ? '1 suggestion' : '${widget.count} suggestions',
                style: NothFlowsTypography.labelSmall.copyWith(
                  color: NothFlowsColors.info,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal dot indicator for suggestions
class SuggestionDot extends StatelessWidget {
  final bool hasRecommendation;
  final VoidCallback onTap;

  const SuggestionDot({
    super.key,
    required this.hasRecommendation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasRecommendation) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: NothFlowsColors.info,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: NothFlowsColors.info.withValues(alpha: 0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

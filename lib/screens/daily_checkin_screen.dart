import 'package:flutter/material.dart';
import '../services/cactus_llm_service.dart';
import '../services/personalization_service.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';
import '../theme/nothflows_spacing.dart';
import '../widgets/noth_button.dart';
import '../widgets/noth_text_field.dart';
import '../widgets/noth_panel.dart';
import '../widgets/noth_toast.dart';

/// Daily check-in screen for capturing user state and suggesting modes
/// Redesigned with proper scrolling and formatting fixes
class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  final _textController = TextEditingController();
  final _llmService = CactusLLMService();
  final _personalizationService = PersonalizationService();
  final _scrollController = ScrollController();

  String? _suggestedCategory;
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getRecommendations() async {
    final input = _textController.text.trim();

    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Please describe how you\'re feeling';
        _suggestedCategory = null;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _suggestedCategory = null;
    });

    try {
      // Infer accessibility category from user input
      final category = await _llmService.inferCategoryFromCheckin(input);

      // Store the check-in
      await _personalizationService.storeCheckIn(input, category);

      setState(() {
        _suggestedCategory = category;
        _isProcessing = false;
      });

      // Scroll to show the suggestion
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing request. Please try again.';
        _isProcessing = false;
      });
      debugPrint('Error in check-in: $e');
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'vision':
        return 'VISION';
      case 'hearing':
        return 'HEARING';
      case 'motor':
        return 'MOTOR';
      case 'calm':
        return 'CALM';
      case 'neurodivergent':
        return 'NEURODIVERGENT';
      default:
        return 'CUSTOM';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'vision':
        return NothFlowsColors.visionBlue;
      case 'hearing':
        return NothFlowsColors.hearingAmber;
      case 'motor':
        return NothFlowsColors.motorPurple;
      case 'calm':
        return NothFlowsColors.calmTeal;
      case 'neurodivergent':
        return NothFlowsColors.neuroMagenta;
      default:
        return NothFlowsColors.customGreen;
    }
  }

  String _getRecommendationText(String category) {
    switch (category) {
      case 'vision':
        return 'Try Vision Assist mode for enhanced readability and screen clarity.';
      case 'hearing':
        return 'Try Hearing Support mode for captions and visual notifications.';
      case 'motor':
        return 'Try Motor Assist mode for simplified interactions and gestures.';
      case 'calm':
        return 'Try Calm Mode to reduce anxiety and minimize overstimulation.';
      case 'neurodivergent':
        return 'Try Neurodivergent Focus mode to minimize distractions.';
      default:
        return 'Consider creating a custom assistive mode for your specific needs.';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'vision':
        return Icons.visibility_outlined;
      case 'hearing':
        return Icons.hearing_outlined;
      case 'motor':
        return Icons.pan_tool_outlined;
      case 'calm':
        return Icons.spa_outlined;
      case 'neurodivergent':
        return Icons.psychology_outlined;
      default:
        return Icons.tune_outlined;
    }
  }

  void _activateSuggestedMode() {
    if (_suggestedCategory != null) {
      Navigator.pop(context, _suggestedCategory);
      NothToast.success(
        context,
        'Navigate to ${_getCategoryLabel(_suggestedCategory!)} mode to activate',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 400 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor:
          isDark ? NothFlowsColors.nothingBlack : NothFlowsColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark
                ? NothFlowsColors.textPrimary
                : NothFlowsColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Daily Check-In',
          style: NothFlowsTypography.headingLarge.copyWith(
            color: isDark
                ? NothFlowsColors.textPrimary
                : NothFlowsColors.textPrimaryLight,
          ),
        ),
      ),
      // FIX: Use Column with Expanded for scrollable content + fixed button
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: NothFlowsSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header text - split into two lines for better visual hierarchy
                  Text(
                    'How are you',
                    style: NothFlowsTypography.displaySmall.copyWith(
                      color: isDark
                          ? NothFlowsColors.textPrimary
                          : NothFlowsColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    'feeling today?',
                    style: NothFlowsTypography.displaySmall.copyWith(
                      color: isDark
                          ? NothFlowsColors.textPrimary
                          : NothFlowsColors.textPrimaryLight,
                    ),
                  ),

                  const SizedBox(height: NothFlowsSpacing.sm),

                  // Subtitle
                  Text(
                    'Tell us about your current state, and we\'ll suggest the best mode for you.',
                    style: NothFlowsTypography.bodyMedium.copyWith(
                      color: isDark
                          ? NothFlowsColors.textSecondary
                          : NothFlowsColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: NothFlowsSpacing.xl),

                  // Input field with responsive sizing
                  NothTextField(
                    controller: _textController,
                    hintText:
                        'e.g., "Having trouble reading small text" or "Feeling overwhelmed by notifications"',
                    minLines: 3,
                    maxLines: MediaQuery.of(context).orientation ==
                            Orientation.landscape
                        ? 3
                        : 5,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _getRecommendations(),
                    semanticLabel: 'Describe how you are feeling',
                    semanticHint:
                        'Enter text describing your current state or difficulties',
                  ),

                  const SizedBox(height: NothFlowsSpacing.lg),

                  // Error message
                  if (_errorMessage != null) ...[
                    NothPanel(
                      padding: const EdgeInsets.all(14),
                      backgroundColor: NothFlowsColors.error.withOpacity(0.1),
                      borderColor: NothFlowsColors.error.withOpacity(0.3),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: NothFlowsColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: NothFlowsTypography.bodyMedium.copyWith(
                                color: NothFlowsColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: NothFlowsSpacing.lg),
                  ],

                  // Suggested category display
                  if (_suggestedCategory != null) ...[
                    NothPanel(
                      padding: const EdgeInsets.all(20),
                      borderColor:
                          _getCategoryColor(_suggestedCategory!).withOpacity(0.4),
                      borderWidth: NothFlowsShapes.borderThick,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: _getCategoryColor(_suggestedCategory!),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Suggested Focus',
                                style: NothFlowsTypography.headingSmall.copyWith(
                                  color: isDark
                                      ? NothFlowsColors.textPrimary
                                      : NothFlowsColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: NothFlowsSpacing.md),

                          // Category chip with icon
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(_suggestedCategory!)
                                  .withOpacity(0.15),
                              borderRadius: NothFlowsShapes.borderRadiusMd,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIcon(_suggestedCategory!),
                                  color: _getCategoryColor(_suggestedCategory!),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getCategoryLabel(_suggestedCategory!),
                                  style: NothFlowsTypography.labelLarge.copyWith(
                                    color: _getCategoryColor(_suggestedCategory!),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: NothFlowsSpacing.md),

                          // Recommendation text with max lines
                          Text(
                            _getRecommendationText(_suggestedCategory!),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: NothFlowsTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? NothFlowsColors.textSecondary
                                  : NothFlowsColors.textSecondaryLight,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: NothFlowsSpacing.lg),

                          // Activate button
                          NothButton.secondary(
                            label: 'Go to This Mode',
                            icon: Icons.arrow_forward,
                            onPressed: _activateSuggestedMode,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: NothFlowsSpacing.lg),
                  ],

                  // Bottom padding to ensure content doesn't get hidden behind button
                  const SizedBox(height: NothFlowsSpacing.md),
                ],
              ),
            ),
          ),

          // Fixed bottom button area
          Container(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              NothFlowsSpacing.md,
              horizontalPadding,
              NothFlowsSpacing.lg + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? NothFlowsColors.nothingBlack
                  : NothFlowsColors.surfaceLight,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? NothFlowsColors.borderDark
                      : NothFlowsColors.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: NothButton.primary(
              label: 'Get Recommendations',
              onPressed: _isProcessing ? null : _getRecommendations,
              isLoading: _isProcessing,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/cactus_llm_service.dart';
import '../services/personalization_service.dart';

/// Daily check-in screen for capturing user state and suggesting modes
class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  final _textController = TextEditingController();
  final _llmService = CactusLLMService();
  final _personalizationService = PersonalizationService();

  String? _suggestedCategory;
  String? _errorMessage;
  bool _isProcessing = false;

  @override
  void dispose() {
    _textController.dispose();
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
      // Infer disability context from user input
      final category = _llmService.inferDisabilityContext(input);

      // Store the check-in
      await _personalizationService.storeCheckIn(input, category);

      setState(() {
        _suggestedCategory = category;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing request: $e';
        _isProcessing = false;
      });
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

  String _getRecommendationText(String category) {
    switch (category) {
      case 'vision':
        return 'Try Vision Assist mode for enhanced readability and screen clarity';
      case 'hearing':
        return 'Try Hearing Support mode for captions and visual notifications';
      case 'motor':
        return 'Try Motor Assist mode for simplified interactions';
      case 'calm':
        return 'Try Calm Mode to reduce anxiety and overstimulation';
      case 'neurodivergent':
        return 'Try Neurodivergent Focus mode to minimize distractions';
      default:
        return 'Consider creating a custom assistive mode for your needs';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Daily Check-In',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header text
              const Text(
                'How are you feeling?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Describe your current state, and we\'ll suggest the best accessibility mode for you.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Input field
              Semantics(
                label: 'Describe how you are feeling',
                hint: 'Enter text describing your current state or difficulties',
                textField: true,
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'e.g., "I\'m having trouble reading small text" or "Feeling overwhelmed by notifications"',
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.4),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .color!
                            .withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .color!
                            .withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF5B4DFF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  maxLines: 5,
                  minLines: 3,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),

              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Get Recommendations button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _getRecommendations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Get Recommendations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // Suggested category display
              if (_suggestedCategory != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF5B4DFF).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF5B4DFF),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Suggested Focus',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B4DFF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getCategoryLabel(_suggestedCategory!),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5B4DFF),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getRecommendationText(_suggestedCategory!),
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

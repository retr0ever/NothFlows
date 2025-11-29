import 'package:flutter/foundation.dart';
import '../models/suggestion_outcome.dart';
import '../models/habit_pattern.dart';
import '../models/user_preference.dart';
import 'habit_tracker_service.dart';
import 'knowledge_base_service.dart';
import 'pattern_analyzer_service.dart';
import 'recommendation_service.dart';

/// Service for handling user feedback and learning from it
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final _habitTracker = HabitTrackerService();
  final _knowledgeBase = KnowledgeBaseService();
  final _patternAnalyzer = PatternAnalyzerService();

  // Feedback accumulation for relearning trigger
  int _feedbackSinceLastAnalysis = 0;
  static const int reanalysisThreshold = 10;

  /// Process feedback when user accepts a suggestion
  Future<void> onSuggestionAccepted(Recommendation recommendation) async {
    debugPrint('[Feedback] Processing accepted suggestion: ${recommendation.modeId}');

    // Skip pattern update for demo suggestions
    if (recommendation.patternId.startsWith('demo')) {
      debugPrint('[Feedback] Demo suggestion accepted, skipping pattern update');
      return;
    }

    // Update pattern confidence
    final patterns = await _habitTracker.getPatterns();
    try {
      final pattern = patterns.firstWhere(
        (p) => p.id == recommendation.patternId,
      );

      final updatedPattern = pattern.copyWith(
        acceptedCount: pattern.acceptedCount + 1,
        confidence: (pattern.confidence + 0.05).clamp(0.0, 1.0),
        lastSeen: DateTime.now(),
        status: PatternStatus.accepted,
      );

      await _habitTracker.updatePattern(updatedPattern);

      // Learn positive preferences
      await _learnFromPositiveFeedback(recommendation);

      _feedbackSinceLastAnalysis++;
      await _checkReanalysis();
    } catch (e) {
      debugPrint('[Feedback] Pattern not found for suggestion: ${recommendation.patternId}');
    }
  }

  /// Process feedback when user rejects a suggestion
  Future<void> onSuggestionRejected(
    Recommendation recommendation, {
    String? reason,
  }) async {
    debugPrint('[Feedback] Processing rejected suggestion: ${recommendation.modeId}');

    // Skip pattern update for demo suggestions
    if (recommendation.patternId.startsWith('demo')) {
      debugPrint('[Feedback] Demo suggestion rejected, skipping pattern update');
      return;
    }

    // Update pattern confidence
    final patterns = await _habitTracker.getPatterns();
    try {
      final pattern = patterns.firstWhere(
        (p) => p.id == recommendation.patternId,
      );

      final updatedPattern = pattern.copyWith(
        rejectedCount: pattern.rejectedCount + 1,
        confidence: (pattern.confidence - 0.1).clamp(0.0, 1.0),
        lastSeen: DateTime.now(),
        status: PatternStatus.dismissed,
      );

      await _habitTracker.updatePattern(updatedPattern);

      // Check if pattern should be deactivated
      await _checkPatternHealth(updatedPattern);

      // Learn from negative feedback
      await _learnFromNegativeFeedback(recommendation, reason);

      _feedbackSinceLastAnalysis++;
      await _checkReanalysis();
    } catch (e) {
      debugPrint('[Feedback] Pattern not found for suggestion: ${recommendation.patternId}');
    }
  }

  /// Process feedback when user blocks a suggestion permanently
  Future<void> onSuggestionBlocked(Recommendation recommendation) async {
    debugPrint('[Feedback] Processing blocked suggestion: ${recommendation.modeId}');

    // Skip pattern update for demo suggestions
    if (recommendation.patternId.startsWith('demo')) {
      debugPrint('[Feedback] Demo suggestion blocked, skipping pattern update');
      return;
    }

    // Update pattern to blocked status
    final patterns = await _habitTracker.getPatterns();
    try {
      final pattern = patterns.firstWhere(
        (p) => p.id == recommendation.patternId,
      );

      final updatedPattern = pattern.copyWith(
        rejectedCount: pattern.rejectedCount + 1,
        status: PatternStatus.blocked,
      );

      await _habitTracker.updatePattern(updatedPattern);

      // Learn strong negative preference
      await _knowledgeBase.updatePreferenceFromFeedback(
        preferenceType: 'blocked_patterns',
        value: recommendation.patternId,
        isPositiveFeedback: false,
      );

      _feedbackSinceLastAnalysis++;
    } catch (e) {
      debugPrint('[Feedback] Pattern not found for suggestion: ${recommendation.patternId}');
    }
  }

  /// Process implicit feedback when suggestion is ignored
  Future<void> onSuggestionIgnored(Recommendation recommendation) async {
    debugPrint('[Feedback] Processing ignored suggestion: ${recommendation.modeId}');

    // Slight confidence decrease
    final patterns = await _habitTracker.getPatterns();
    try {
      final pattern = patterns.firstWhere(
        (p) => p.id == recommendation.patternId,
      );

      final updatedPattern = pattern.copyWith(
        ignoredCount: pattern.ignoredCount + 1,
        confidence: (pattern.confidence - 0.02).clamp(0.0, 1.0),
      );

      await _habitTracker.updatePattern(updatedPattern);
    } catch (e) {
      debugPrint('[Feedback] Pattern not found for ignored suggestion');
    }

    _feedbackSinceLastAnalysis++;
    await _checkReanalysis();
  }

  /// Learn from positive feedback
  Future<void> _learnFromPositiveFeedback(Recommendation recommendation) async {
    // User accepted, so they like suggestions
    await _knowledgeBase.updatePreferenceFromFeedback(
      preferenceType: PreferenceTypes.suggestionStyle,
      value: PreferenceTypes.reminderOnly,
      isPositiveFeedback: true,
    );
  }

  /// Learn from negative feedback
  Future<void> _learnFromNegativeFeedback(
    Recommendation recommendation,
    String? reason,
  ) async {
    // Check recent rejection rate
    final outcomes = await _habitTracker.getOutcomes();
    final recent = outcomes.take(10).toList();

    final rejectionCount = recent.where((o) => o.isNegative).length;

    if (rejectionCount >= 7) {
      // User is rejecting most suggestions - reduce frequency
      await _knowledgeBase.updatePreferenceFromFeedback(
        preferenceType: PreferenceTypes.suggestionFrequency,
        value: PreferenceTypes.minimal,
        isPositiveFeedback: true,
      );
      debugPrint('[Feedback] High rejection rate detected, reducing suggestions');
    }
  }

  /// Check if pattern should be deactivated due to poor performance
  Future<void> _checkPatternHealth(HabitPattern pattern) async {
    final total = pattern.acceptedCount + pattern.rejectedCount + pattern.ignoredCount;
    if (total < 5) return; // Not enough data

    final rejectRate = pattern.rejectedCount / total;

    // Deactivate patterns with high rejection rate
    if (rejectRate > 0.6 && pattern.status != PatternStatus.blocked) {
      final deactivated = pattern.copyWith(status: PatternStatus.blocked);
      await _habitTracker.updatePattern(deactivated);
      debugPrint('[Feedback] Deactivated pattern ${pattern.id} due to high rejection rate');
    }

    // Lower confidence for patterns with moderate rejection
    if (rejectRate > 0.3 && pattern.confidence > 0.5) {
      final lowered = pattern.copyWith(
        confidence: (pattern.confidence * 0.9).clamp(0.0, 1.0),
      );
      await _habitTracker.updatePattern(lowered);
    }
  }

  /// Trigger reanalysis if enough feedback accumulated
  Future<void> _checkReanalysis() async {
    if (_feedbackSinceLastAnalysis >= reanalysisThreshold) {
      debugPrint('[Feedback] Triggering reanalysis due to accumulated feedback');
      await _patternAnalyzer.analyzePatterns();
      _feedbackSinceLastAnalysis = 0;
      _knowledgeBase.invalidateCache();
    }
  }

  /// Get feedback statistics
  Future<Map<String, dynamic>> getFeedbackStats() async {
    final outcomes = await _habitTracker.getOutcomes();

    final accepted = outcomes.where((o) => o.isPositive).length;
    final rejected = outcomes.where((o) => o.isNegative).length;
    final ignored = outcomes
        .where((o) => o.outcome == SuggestionOutcomeType.ignored)
        .length;

    final total = outcomes.length;
    final acceptanceRate = total > 0 ? accepted / total : 0.0;

    return {
      'total': total,
      'accepted': accepted,
      'rejected': rejected,
      'ignored': ignored,
      'acceptanceRate': acceptanceRate,
      'feedbackSinceLastAnalysis': _feedbackSinceLastAnalysis,
    };
  }

  /// Reset feedback counter (for testing)
  void resetFeedbackCounter() {
    _feedbackSinceLastAnalysis = 0;
  }
}

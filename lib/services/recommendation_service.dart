import 'package:flutter/foundation.dart';
import '../models/habit_pattern.dart';
import '../models/usage_event.dart';
import '../models/suggestion_outcome.dart';
import '../models/user_preference.dart';
import 'habit_tracker_service.dart';
import 'pattern_analyzer_service.dart';
import 'knowledge_base_service.dart';
import 'sensor_service.dart';

/// A recommendation to suggest to the user
class Recommendation {
  final String id;
  final String modeId;
  final String patternId;
  final String description;
  final String reason;
  final double confidence;
  final DateTime createdAt;

  Recommendation({
    required this.id,
    required this.modeId,
    required this.patternId,
    required this.description,
    required this.reason,
    required this.confidence,
    required this.createdAt,
  });

  @override
  String toString() =>
      'Recommendation($modeId: $description, confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
}

/// Service for generating and managing recommendations
class RecommendationService {
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  final _habitTracker = HabitTrackerService();
  final _patternAnalyzer = PatternAnalyzerService();
  final _knowledgeBase = KnowledgeBaseService();
  final _sensorService = SensorService();

  // Rate limiting
  DateTime? _lastSuggestionTime;
  final List<String> _shownSuggestionIds = [];
  static const Duration cooldownPeriod = Duration(minutes: 30);
  static const int maxSuggestionsPerDay = 5;
  static const double minConfidenceForSuggestion = 0.6;

  /// Get current recommendation based on context
  Future<Recommendation?> getCurrentRecommendation() async {
    // Check rate limiting
    if (!await _canShowSuggestion()) {
      debugPrint('[Recommendation] Rate limited, skipping suggestion');
      return null;
    }

    // Check if user wants minimal suggestions
    final freqPref = await _knowledgeBase.getPreferenceValue(
      PreferenceTypes.suggestionFrequency,
    );
    final minConfidence = freqPref == PreferenceTypes.minimal ? 0.8 : 0.6;

    // Get current context
    final currentHour = DateTime.now().hour;
    final currentTimeOfDay = UsageEvent.create(
      modeId: '',
      triggerSource: 'system',
    ).timeOfDay;

    // Get the last activated mode (for sequence patterns)
    final recentEvents = await _habitTracker.getRecentEvents(days: 1);
    String? previousModeId;
    if (recentEvents.isNotEmpty) {
      final lastActivation = recentEvents.firstWhere(
        (e) => e.isActivation,
        orElse: () => recentEvents.first,
      );
      previousModeId = lastActivation.modeId;
    }

    // Find relevant patterns
    final relevantPatterns = await _patternAnalyzer.getRelevantPatterns(
      currentTimeOfDay: currentTimeOfDay,
      currentHour: currentHour,
      ambientLight: _sensorService.ambientLight,
      deviceMotion: _sensorService.deviceMotion,
      previousModeId: previousModeId,
    );

    if (relevantPatterns.isEmpty) {
      debugPrint('[Recommendation] No relevant patterns for current context');
      return null;
    }

    // Filter by confidence and already shown
    final candidates = relevantPatterns
        .where((p) => p.confidence >= minConfidence)
        .where((p) => !_shownSuggestionIds.contains(p.id))
        .where((p) => p.status != PatternStatus.blocked)
        .toList();

    if (candidates.isEmpty) {
      debugPrint('[Recommendation] No candidates after filtering');
      return null;
    }

    // Sort by confidence and acceptance rate
    candidates.sort((a, b) {
      final scoreA = a.confidence * (0.5 + a.acceptanceRate * 0.5);
      final scoreB = b.confidence * (0.5 + b.acceptanceRate * 0.5);
      return scoreB.compareTo(scoreA);
    });

    final topPattern = candidates.first;

    // Generate recommendation
    final recommendation = Recommendation(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      modeId: topPattern.modeId,
      patternId: topPattern.id,
      description: topPattern.description,
      reason: _generateReasonText(topPattern),
      confidence: topPattern.confidence,
      createdAt: DateTime.now(),
    );

    debugPrint('[Recommendation] Generated: $recommendation');
    return recommendation;
  }

  /// Generate a human-readable reason for the suggestion
  String _generateReasonText(HabitPattern pattern) {
    final conditions = pattern.conditions;
    if (conditions == null) {
      return 'Based on your usage patterns';
    }

    final parts = <String>[];

    if (conditions.timeOfDay != null) {
      parts.add("It's ${conditions.timeOfDay}");
    }

    if (conditions.hours != null && conditions.hours!.isNotEmpty) {
      final hour = conditions.hours!.first;
      parts.add("It's around $hour:00");
    }

    if (conditions.ambientLight != null) {
      switch (conditions.ambientLight) {
        case 'low':
          parts.add('the lighting is dim');
          break;
        case 'high':
          parts.add("it's bright");
          break;
      }
    }

    if (conditions.deviceMotion != null) {
      switch (conditions.deviceMotion) {
        case 'still':
          parts.add("you're sitting still");
          break;
        case 'walking':
          parts.add("you're moving around");
          break;
      }
    }

    if (conditions.previousModeId != null) {
      parts.add('you just used ${conditions.previousModeId} mode');
    }

    if (parts.isEmpty) {
      return 'Based on your past usage';
    }

    if (parts.length == 1) {
      return '${parts.first}, and you usually activate ${pattern.modeId} mode around this time';
    }

    return '${parts.join(" and ")}, which is when you often use ${pattern.modeId} mode';
  }

  /// Check if we can show a suggestion (rate limiting)
  Future<bool> _canShowSuggestion() async {
    // Check cooldown
    if (_lastSuggestionTime != null) {
      final elapsed = DateTime.now().difference(_lastSuggestionTime!);
      if (elapsed < cooldownPeriod) {
        return false;
      }
    }

    // Check daily limit
    final todayOutcomes = await _getTodayOutcomes();
    if (todayOutcomes.length >= maxSuggestionsPerDay) {
      return false;
    }

    return true;
  }

  /// Get outcomes from today
  Future<List<SuggestionOutcome>> _getTodayOutcomes() async {
    final outcomes = await _habitTracker.getOutcomes();
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return outcomes
        .where((o) => o.timestamp.isAfter(startOfDay))
        .toList();
  }

  /// Record that a suggestion was shown
  void markSuggestionShown(Recommendation recommendation) {
    _lastSuggestionTime = DateTime.now();
    _shownSuggestionIds.add(recommendation.patternId);

    // Clear old shown IDs (keep last 20)
    if (_shownSuggestionIds.length > 20) {
      _shownSuggestionIds.removeRange(0, _shownSuggestionIds.length - 20);
    }

    _knowledgeBase.recordSuggestionShown(
      suggestionId: recommendation.id,
      patternId: recommendation.patternId,
      modeId: recommendation.modeId,
    );
  }

  /// Handle user accepting a suggestion
  Future<void> acceptSuggestion(Recommendation recommendation) async {
    await _knowledgeBase.recordSuggestionOutcome(
      suggestionId: recommendation.id,
      patternId: recommendation.patternId,
      modeId: recommendation.modeId,
      outcome: SuggestionOutcomeType.accepted,
    );

    debugPrint('[Recommendation] User accepted: ${recommendation.modeId}');
  }

  /// Handle user rejecting a suggestion
  Future<void> rejectSuggestion(
    Recommendation recommendation, {
    String? reason,
    bool permanent = false,
  }) async {
    await _knowledgeBase.recordSuggestionOutcome(
      suggestionId: recommendation.id,
      patternId: recommendation.patternId,
      modeId: recommendation.modeId,
      outcome: permanent
          ? SuggestionOutcomeType.blocked
          : SuggestionOutcomeType.rejected,
      reason: reason,
    );

    debugPrint('[Recommendation] User ${permanent ? "blocked" : "rejected"}: ${recommendation.modeId}');
  }

  /// Handle suggestion being ignored (timed out)
  Future<void> ignoreSuggestion(Recommendation recommendation) async {
    await _knowledgeBase.recordSuggestionOutcome(
      suggestionId: recommendation.id,
      patternId: recommendation.patternId,
      modeId: recommendation.modeId,
      outcome: SuggestionOutcomeType.ignored,
    );

    debugPrint('[Recommendation] User ignored: ${recommendation.modeId}');
  }

  /// Trigger pattern analysis if needed
  Future<void> runAnalysisIfNeeded() async {
    if (await _patternAnalyzer.shouldRunAnalysis()) {
      debugPrint('[Recommendation] Running pattern analysis...');
      await _patternAnalyzer.analyzePatterns();
    }
  }

  /// Check if there are any pending recommendations
  Future<bool> hasPendingRecommendation() async {
    final recommendation = await getCurrentRecommendation();
    return recommendation != null;
  }

  /// Get number of suggestions shown today
  Future<int> getSuggestionCountToday() async {
    final todayOutcomes = await _getTodayOutcomes();
    return todayOutcomes.length;
  }

  /// Reset rate limiting (for testing)
  void resetRateLimiting() {
    _lastSuggestionTime = null;
    _shownSuggestionIds.clear();
  }

  // Demo mode state
  Recommendation? _demoRecommendation;

  /// Create a demo recommendation for presentation purposes
  /// Call this to instantly show a suggestion without needing historical data
  Recommendation createDemoRecommendation({
    String modeId = 'vision',
    String? customDescription,
    String? customReason,
  }) {
    final now = DateTime.now();
    final hour = now.hour;
    final timeOfDay = hour >= 5 && hour < 12
        ? 'morning'
        : hour >= 12 && hour < 17
            ? 'afternoon'
            : hour >= 17 && hour < 21
                ? 'evening'
                : 'night';

    final modeNames = {
      'vision': 'Vision Assist',
      'motor': 'Motor Support',
      'neuro': 'Focus Mode',
      'calm': 'Calm Mode',
      'hearing': 'Hearing Support',
      'custom': 'Custom Mode',
    };

    final modeName = modeNames[modeId] ?? 'Vision Assist';

    _demoRecommendation = Recommendation(
      id: 'demo_${now.millisecondsSinceEpoch}',
      modeId: modeId,
      patternId: 'demo_pattern',
      description: customDescription ?? 'Activate $modeName?',
      reason: customReason ??
          'You usually use $modeName around this time in the $timeOfDay. '
              'Based on your habits from the past week, this might help you now.',
      confidence: 0.85,
      createdAt: now,
    );

    debugPrint('[Recommendation] Created demo recommendation for $modeId');
    return _demoRecommendation!;
  }

  /// Get demo recommendation if one exists
  Recommendation? getDemoRecommendation() => _demoRecommendation;

  /// Clear demo recommendation
  void clearDemoRecommendation() {
    _demoRecommendation = null;
  }

  /// Check if in demo mode
  bool get hasDemoRecommendation => _demoRecommendation != null;
}

import 'package:flutter/foundation.dart';
import '../models/user_knowledge_base.dart';
import '../models/usage_event.dart';
import '../models/habit_pattern.dart';
import '../models/user_preference.dart';
import '../models/suggestion_outcome.dart';
import 'habit_tracker_service.dart';

/// Service for managing the user's knowledge base and generating LLM context
class KnowledgeBaseService {
  static final KnowledgeBaseService _instance = KnowledgeBaseService._internal();
  factory KnowledgeBaseService() => _instance;
  KnowledgeBaseService._internal();

  final _habitTracker = HabitTrackerService();

  // Cached knowledge base
  UserKnowledgeBase? _cachedKnowledgeBase;
  DateTime? _lastBuildTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Build and return the current knowledge base
  Future<UserKnowledgeBase> getKnowledgeBase({bool forceRefresh = false}) async {
    // Return cached if still valid
    if (!forceRefresh &&
        _cachedKnowledgeBase != null &&
        _lastBuildTime != null &&
        DateTime.now().difference(_lastBuildTime!) < _cacheExpiry) {
      return _cachedKnowledgeBase!;
    }

    // Build fresh knowledge base
    final events = await _habitTracker.getRecentEvents(days: 14);
    final patterns = await _habitTracker.getPatterns();
    final preferences = await _habitTracker.getPreferences();
    final outcomes = await _habitTracker.getOutcomes();

    _cachedKnowledgeBase = UserKnowledgeBase.build(
      events: events,
      patterns: patterns,
      preferences: preferences,
      outcomes: outcomes,
    );
    _lastBuildTime = DateTime.now();

    debugPrint('[KnowledgeBase] Built: $_cachedKnowledgeBase');
    return _cachedKnowledgeBase!;
  }

  /// Generate a prompt summary for LLM injection
  Future<String> getPromptSummary() async {
    final kb = await getKnowledgeBase();
    return kb.toPromptSummary();
  }

  /// Check if we have enough data for meaningful suggestions
  Future<bool> hasEnoughData() async {
    final events = await _habitTracker.getRecentEvents(days: 7);
    return events.length >= 3; // Need at least 3 events to start detecting patterns
  }

  /// Update a user preference based on feedback
  Future<void> updatePreferenceFromFeedback({
    required String preferenceType,
    required String value,
    bool isPositiveFeedback = true,
  }) async {
    final existingPref = await _habitTracker.getPreference(preferenceType);

    if (existingPref != null) {
      // Update existing preference
      final newConfidence = isPositiveFeedback
          ? (existingPref.confidence + 0.1).clamp(0.0, 1.0)
          : (existingPref.confidence - 0.1).clamp(0.0, 1.0);

      final updated = existingPref.copyWith(
        value: value,
        confidence: newConfidence,
        evidenceCount: existingPref.evidenceCount + 1,
      );

      await _habitTracker.savePreference(updated);
    } else {
      // Create new preference
      final newPref = UserPreference.create(
        preferenceType: preferenceType,
        value: value,
        confidence: 0.5,
        evidenceCount: 1,
      );

      await _habitTracker.savePreference(newPref);
    }

    // Invalidate cache
    _cachedKnowledgeBase = null;
  }

  /// Record that a suggestion was shown to the user
  Future<void> recordSuggestionShown({
    required String suggestionId,
    required String patternId,
    required String modeId,
  }) async {
    debugPrint('[KnowledgeBase] Suggestion shown: $suggestionId for mode $modeId');
    // Could track shown suggestions if needed for rate limiting
  }

  /// Record suggestion outcome and update pattern confidence
  Future<void> recordSuggestionOutcome({
    required String suggestionId,
    required String patternId,
    required String modeId,
    required SuggestionOutcomeType outcome,
    String? reason,
    int responseTimeMs = 0,
  }) async {
    // Record the outcome
    final outcomeRecord = SuggestionOutcome.create(
      suggestionId: suggestionId,
      patternId: patternId,
      modeId: modeId,
      outcome: outcome,
      reason: reason,
      responseTimeMs: responseTimeMs,
    );

    await _habitTracker.recordOutcome(outcomeRecord);

    // Update pattern based on outcome
    final patterns = await _habitTracker.getPatterns();
    final pattern = patterns.firstWhere(
      (p) => p.id == patternId,
      orElse: () => throw Exception('Pattern not found: $patternId'),
    );

    HabitPattern updatedPattern;
    switch (outcome) {
      case SuggestionOutcomeType.accepted:
        updatedPattern = pattern.copyWith(
          acceptedCount: pattern.acceptedCount + 1,
          confidence: (pattern.confidence + 0.05).clamp(0.0, 1.0),
          status: PatternStatus.accepted,
        );
        break;

      case SuggestionOutcomeType.rejected:
        updatedPattern = pattern.copyWith(
          rejectedCount: pattern.rejectedCount + 1,
          confidence: (pattern.confidence - 0.1).clamp(0.0, 1.0),
          status: PatternStatus.dismissed,
        );
        break;

      case SuggestionOutcomeType.ignored:
        updatedPattern = pattern.copyWith(
          ignoredCount: pattern.ignoredCount + 1,
          confidence: (pattern.confidence - 0.02).clamp(0.0, 1.0),
        );
        break;

      case SuggestionOutcomeType.blocked:
        updatedPattern = pattern.copyWith(
          rejectedCount: pattern.rejectedCount + 1,
          status: PatternStatus.blocked,
        );
        break;
    }

    await _habitTracker.updatePattern(updatedPattern);

    // Learn preferences from outcomes
    await _learnPreferencesFromOutcome(outcome);

    // Invalidate cache
    _cachedKnowledgeBase = null;

    debugPrint('[KnowledgeBase] Recorded outcome: ${outcome.name} for pattern $patternId');
  }

  /// Learn user preferences from suggestion outcomes
  Future<void> _learnPreferencesFromOutcome(SuggestionOutcomeType outcome) async {
    // If user consistently rejects auto-suggestions, learn they prefer reminders
    final recentOutcomes = await _habitTracker.getOutcomes();
    final last5 = recentOutcomes.take(5).toList();

    if (last5.length >= 5) {
      final rejectedCount = last5.where((o) => o.isNegative).length;

      if (rejectedCount >= 4) {
        // User is rejecting most suggestions
        await updatePreferenceFromFeedback(
          preferenceType: PreferenceTypes.suggestionFrequency,
          value: PreferenceTypes.minimal,
          isPositiveFeedback: true,
        );
      }
    }
  }

  /// Get the user's preference for a specific type
  Future<String?> getPreferenceValue(String preferenceType) async {
    final pref = await _habitTracker.getPreference(preferenceType);
    return pref?.value;
  }

  /// Check if suggestions should be shown based on user preferences
  Future<bool> shouldShowSuggestions() async {
    final freqPref = await getPreferenceValue(PreferenceTypes.suggestionFrequency);

    if (freqPref == PreferenceTypes.minimal) {
      // Minimal mode: only show for very high confidence patterns
      return true; // Still show, but filtering happens elsewhere
    }

    return true;
  }

  /// Clear the cache (call after significant changes)
  void invalidateCache() {
    _cachedKnowledgeBase = null;
    _lastBuildTime = null;
  }
}

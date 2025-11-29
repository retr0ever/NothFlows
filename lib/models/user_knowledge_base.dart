import 'habit_pattern.dart';
import 'user_preference.dart';
import 'suggestion_outcome.dart';
import 'usage_event.dart';

/// Aggregated knowledge base for LLM context injection
class UserKnowledgeBase {
  /// Usage patterns (auto-detected)
  final List<HabitPattern> patterns;

  /// User preferences (from feedback)
  final List<UserPreference> preferences;

  /// Recent suggestion outcomes
  final List<SuggestionOutcome> recentOutcomes;

  /// Mode usage frequency (mode_id -> count in last 7 days)
  final Map<String, int> modeFrequency;

  /// Most active hours (hour -> count)
  final Map<int, int> activeHours;

  /// Context facts (derived insights)
  final List<String> facts;

  UserKnowledgeBase({
    this.patterns = const [],
    this.preferences = const [],
    this.recentOutcomes = const [],
    this.modeFrequency = const {},
    this.activeHours = const {},
    this.facts = const [],
  });

  /// Build from raw data
  factory UserKnowledgeBase.build({
    required List<UsageEvent> events,
    required List<HabitPattern> patterns,
    required List<UserPreference> preferences,
    required List<SuggestionOutcome> outcomes,
  }) {
    // Calculate mode frequency from last 7 days
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentEvents = events.where((e) => e.timestamp.isAfter(sevenDaysAgo));

    final modeFrequency = <String, int>{};
    final activeHours = <int, int>{};

    for (final event in recentEvents) {
      if (event.isActivation) {
        modeFrequency[event.modeId] = (modeFrequency[event.modeId] ?? 0) + 1;
        activeHours[event.hourOfDay] = (activeHours[event.hourOfDay] ?? 0) + 1;
      }
    }

    // Derive facts from data
    final facts = <String>[];

    // Most used mode
    if (modeFrequency.isNotEmpty) {
      final topMode = modeFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      facts.add('Most used mode: ${topMode.key} (${topMode.value}x this week)');
    }

    // Most active time
    if (activeHours.isNotEmpty) {
      final topHour = activeHours.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      facts.add('Most active around ${topHour.key}:00');
    }

    // Preference insights
    for (final pref in preferences.where((p) => p.isReliable)) {
      facts.add('Prefers ${pref.preferenceType}: ${pref.value}');
    }

    // Acceptance rate
    if (outcomes.isNotEmpty) {
      final accepted = outcomes.where((o) => o.isPositive).length;
      final rate = (accepted / outcomes.length * 100).toStringAsFixed(0);
      facts.add('Suggestion acceptance rate: $rate%');
    }

    return UserKnowledgeBase(
      patterns: patterns.where((p) => p.isActive).toList(),
      preferences: preferences,
      recentOutcomes: outcomes.take(20).toList(),
      modeFrequency: modeFrequency,
      activeHours: activeHours,
      facts: facts,
    );
  }

  /// Generate a condensed summary for LLM prompt injection
  String toPromptSummary() {
    final buffer = StringBuffer();

    // Mode frequency
    if (modeFrequency.isNotEmpty) {
      final sorted = modeFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topModes = sorted.take(3).map((e) => '${e.key} (${e.value}x)');
      buffer.writeln('- Frequently uses: ${topModes.join(", ")}');
    }

    // Active patterns
    final activePatterns = patterns.where((p) => p.isSignificant).take(3);
    for (final pattern in activePatterns) {
      buffer.writeln('- Pattern: ${pattern.description}');
    }

    // Preferences
    final reliablePrefs = preferences.where((p) => p.isReliable);
    for (final pref in reliablePrefs) {
      if (pref.preferenceType == PreferenceTypes.suggestionStyle) {
        if (pref.value == PreferenceTypes.reminderOnly) {
          buffer.writeln('- Prefers reminder-style suggestions over auto-activation');
        }
      } else if (pref.preferenceType == PreferenceTypes.voiceAnnouncements) {
        buffer.writeln('- Voice announcements preference: ${pref.value}');
      }
    }

    // Recent feedback trends
    if (recentOutcomes.isNotEmpty) {
      final rejected = recentOutcomes.where((o) => o.isNegative).length;
      if (rejected > recentOutcomes.length * 0.5) {
        buffer.writeln('- Has been dismissing suggestions frequently');
      }
    }

    // Derived facts
    for (final fact in facts.take(3)) {
      buffer.writeln('- $fact');
    }

    return buffer.toString().trim();
  }

  /// Check if we have enough data for meaningful suggestions
  bool get hasEnoughData => modeFrequency.isNotEmpty && patterns.isNotEmpty;

  /// Get user's preferred suggestion style
  String? get preferredSuggestionStyle {
    final pref = preferences.firstWhere(
      (p) => p.preferenceType == PreferenceTypes.suggestionStyle && p.isReliable,
      orElse: () => UserPreference.create(
        preferenceType: PreferenceTypes.suggestionStyle,
        value: PreferenceTypes.reminderOnly,
      ),
    );
    return pref.value;
  }

  @override
  String toString() =>
      'UserKnowledgeBase(${patterns.length} patterns, ${preferences.length} prefs, ${modeFrequency.length} modes tracked)';
}

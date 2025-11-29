import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/usage_event.dart';
import '../models/habit_pattern.dart';
import '../models/user_preference.dart';
import '../models/suggestion_outcome.dart';
import 'sensor_service.dart';

/// Service for tracking user habits and storing usage events
class HabitTrackerService {
  static final HabitTrackerService _instance = HabitTrackerService._internal();
  factory HabitTrackerService() => _instance;
  HabitTrackerService._internal();

  // Hive box names
  static const String _eventsBoxName = 'usage_events';
  static const String _patternsBoxName = 'habit_patterns';
  static const String _preferencesBoxName = 'user_preferences';
  static const String _outcomesBoxName = 'suggestion_outcomes';

  // Hive boxes
  Box<UsageEvent>? _eventsBox;
  Box<HabitPattern>? _patternsBox;
  Box<UserPreference>? _preferencesBox;
  Box<SuggestionOutcome>? _outcomesBox;

  bool _isInitialized = false;

  // Configuration
  static const int maxEvents = 500; // Keep last 500 events
  static const int maxOutcomes = 100; // Keep last 100 outcomes
  static const Duration eventRetention = Duration(days: 30);

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(UsageEventAdapter());
      }
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(HabitPatternAdapter());
      }
      if (!Hive.isAdapterRegistered(12)) {
        Hive.registerAdapter(UserPreferenceAdapter());
      }
      if (!Hive.isAdapterRegistered(13)) {
        Hive.registerAdapter(SuggestionOutcomeAdapter());
      }
      if (!Hive.isAdapterRegistered(14)) {
        Hive.registerAdapter(PatternStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(15)) {
        Hive.registerAdapter(PatternConditionsAdapter());
      }
      if (!Hive.isAdapterRegistered(16)) {
        Hive.registerAdapter(SuggestionOutcomeTypeAdapter());
      }

      // Open boxes
      _eventsBox = await Hive.openBox<UsageEvent>(_eventsBoxName);
      _patternsBox = await Hive.openBox<HabitPattern>(_patternsBoxName);
      _preferencesBox = await Hive.openBox<UserPreference>(_preferencesBoxName);
      _outcomesBox = await Hive.openBox<SuggestionOutcome>(_outcomesBoxName);

      _isInitialized = true;
      debugPrint('[HabitTracker] Initialized with ${_eventsBox!.length} events, '
          '${_patternsBox!.length} patterns');

      // Prune old data on startup
      await _pruneOldData();
    } catch (e) {
      debugPrint('[HabitTracker] Failed to initialize: $e');
      rethrow;
    }
  }

  /// Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // ============ Event Recording ============

  /// Record a mode activation/deactivation event
  Future<void> recordModeEvent({
    required String modeId,
    required bool isActivation,
    required String triggerSource,
    List<String>? flowActions,
  }) async {
    await _ensureInitialized();

    final sensor = SensorService();
    final event = UsageEvent.create(
      modeId: modeId,
      triggerSource: triggerSource,
      ambientLight: sensor.ambientLight,
      deviceMotion: sensor.deviceMotion,
      flowActions: flowActions,
      isActivation: isActivation,
    );

    await _eventsBox!.put(event.id, event);
    debugPrint('[HabitTracker] Recorded event: $event');

    // Check if we need to prune
    if (_eventsBox!.length > maxEvents) {
      await _pruneOldEvents();
    }
  }

  /// Get all usage events
  Future<List<UsageEvent>> getEvents() async {
    await _ensureInitialized();
    return _eventsBox!.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get events for a specific mode
  Future<List<UsageEvent>> getEventsForMode(String modeId) async {
    final events = await getEvents();
    return events.where((e) => e.modeId == modeId).toList();
  }

  /// Get events within a time range
  Future<List<UsageEvent>> getEventsInRange(DateTime start, DateTime end) async {
    final events = await getEvents();
    return events
        .where((e) => e.timestamp.isAfter(start) && e.timestamp.isBefore(end))
        .toList();
  }

  /// Get recent events (last N days)
  Future<List<UsageEvent>> getRecentEvents({int days = 14}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final events = await getEvents();
    return events.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  // ============ Pattern Storage ============

  /// Save a detected pattern
  Future<void> savePattern(HabitPattern pattern) async {
    await _ensureInitialized();
    await _patternsBox!.put(pattern.id, pattern);
    debugPrint('[HabitTracker] Saved pattern: $pattern');
  }

  /// Get all patterns
  Future<List<HabitPattern>> getPatterns() async {
    await _ensureInitialized();
    return _patternsBox!.values.toList();
  }

  /// Get active patterns (not blocked/dismissed)
  Future<List<HabitPattern>> getActivePatterns() async {
    final patterns = await getPatterns();
    return patterns.where((p) => p.isActive && p.isSignificant).toList();
  }

  /// Update a pattern
  Future<void> updatePattern(HabitPattern pattern) async {
    await _ensureInitialized();
    await _patternsBox!.put(pattern.id, pattern);
  }

  /// Delete a pattern
  Future<void> deletePattern(String patternId) async {
    await _ensureInitialized();
    await _patternsBox!.delete(patternId);
  }

  // ============ Preference Storage ============

  /// Save a user preference
  Future<void> savePreference(UserPreference preference) async {
    await _ensureInitialized();
    await _preferencesBox!.put(preference.id, preference);
    debugPrint('[HabitTracker] Saved preference: $preference');
  }

  /// Get all preferences
  Future<List<UserPreference>> getPreferences() async {
    await _ensureInitialized();
    return _preferencesBox!.values.toList();
  }

  /// Get a specific preference by type
  Future<UserPreference?> getPreference(String preferenceType) async {
    final prefs = await getPreferences();
    try {
      return prefs.firstWhere((p) => p.preferenceType == preferenceType);
    } catch (e) {
      return null;
    }
  }

  // ============ Outcome Storage ============

  /// Record a suggestion outcome
  Future<void> recordOutcome(SuggestionOutcome outcome) async {
    await _ensureInitialized();
    await _outcomesBox!.put(outcome.id, outcome);
    debugPrint('[HabitTracker] Recorded outcome: $outcome');

    // Prune if needed
    if (_outcomesBox!.length > maxOutcomes) {
      await _pruneOldOutcomes();
    }
  }

  /// Get all outcomes
  Future<List<SuggestionOutcome>> getOutcomes() async {
    await _ensureInitialized();
    return _outcomesBox!.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get outcomes for a specific pattern
  Future<List<SuggestionOutcome>> getOutcomesForPattern(String patternId) async {
    final outcomes = await getOutcomes();
    return outcomes.where((o) => o.patternId == patternId).toList();
  }

  // ============ Data Cleanup ============

  /// Prune old data
  Future<void> _pruneOldData() async {
    await _pruneOldEvents();
    await _pruneOldOutcomes();
  }

  /// Remove events older than retention period
  Future<void> _pruneOldEvents() async {
    final cutoff = DateTime.now().subtract(eventRetention);
    final keysToDelete = <dynamic>[];

    for (final key in _eventsBox!.keys) {
      final event = _eventsBox!.get(key);
      if (event != null && event.timestamp.isBefore(cutoff)) {
        keysToDelete.add(key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _eventsBox!.deleteAll(keysToDelete);
      debugPrint('[HabitTracker] Pruned ${keysToDelete.length} old events');
    }

    // Also cap total events
    if (_eventsBox!.length > maxEvents) {
      final events = _eventsBox!.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final toDelete = events.take(_eventsBox!.length - maxEvents);
      for (final event in toDelete) {
        await _eventsBox!.delete(event.id);
      }
    }
  }

  /// Remove old outcomes
  Future<void> _pruneOldOutcomes() async {
    if (_outcomesBox!.length > maxOutcomes) {
      final outcomes = _outcomesBox!.values.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final toDelete = outcomes.take(_outcomesBox!.length - maxOutcomes);
      for (final outcome in toDelete) {
        await _outcomesBox!.delete(outcome.id);
      }
      debugPrint('[HabitTracker] Pruned ${toDelete.length} old outcomes');
    }
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _eventsBox!.clear();
    await _patternsBox!.clear();
    await _preferencesBox!.clear();
    await _outcomesBox!.clear();
    debugPrint('[HabitTracker] Cleared all data');
  }

  // ============ Statistics ============

  /// Get mode usage statistics
  Future<Map<String, int>> getModeUsageStats({int days = 7}) async {
    final events = await getRecentEvents(days: days);
    final stats = <String, int>{};

    for (final event in events) {
      if (event.isActivation) {
        stats[event.modeId] = (stats[event.modeId] ?? 0) + 1;
      }
    }

    return stats;
  }

  /// Get hourly usage distribution
  Future<Map<int, int>> getHourlyDistribution({int days = 14}) async {
    final events = await getRecentEvents(days: days);
    final distribution = <int, int>{};

    for (final event in events) {
      if (event.isActivation) {
        distribution[event.hourOfDay] =
            (distribution[event.hourOfDay] ?? 0) + 1;
      }
    }

    return distribution;
  }

  /// Get day-of-week usage distribution
  Future<Map<String, int>> getDayOfWeekDistribution({int days = 14}) async {
    final events = await getRecentEvents(days: days);
    final distribution = <String, int>{};

    for (final event in events) {
      if (event.isActivation) {
        distribution[event.dayOfWeek] =
            (distribution[event.dayOfWeek] ?? 0) + 1;
      }
    }

    return distribution;
  }
}

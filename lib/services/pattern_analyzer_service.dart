import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/usage_event.dart';
import '../models/habit_pattern.dart';
import 'habit_tracker_service.dart';
import 'cactus_llm_service.dart';
import 'knowledge_base_service.dart';

/// Service for detecting behavioral patterns from usage events
class PatternAnalyzerService {
  static final PatternAnalyzerService _instance = PatternAnalyzerService._internal();
  factory PatternAnalyzerService() => _instance;
  PatternAnalyzerService._internal();

  final _habitTracker = HabitTrackerService();
  final _llmService = CactusLLMService();
  final _knowledgeBase = KnowledgeBaseService();

  // Configuration
  static const int minOccurrences = 3;
  static const double minConfidence = 0.6;
  static const Duration analysisWindow = Duration(days: 14);

  /// Run full pattern analysis
  Future<List<HabitPattern>> analyzePatterns() async {
    debugPrint('[PatternAnalyzer] Starting pattern analysis...');

    final events = await _habitTracker.getRecentEvents(days: 14);
    if (events.length < minOccurrences) {
      debugPrint('[PatternAnalyzer] Not enough events (${events.length}) for analysis');
      return [];
    }

    // Phase 1: Statistical pre-analysis
    final timePatterns = _detectTimePatterns(events);
    final contextPatterns = _detectContextPatterns(events);
    final sequencePatterns = _detectSequencePatterns(events);

    // Combine all detected patterns
    final allPatterns = [
      ...timePatterns,
      ...contextPatterns,
      ...sequencePatterns,
    ];

    debugPrint('[PatternAnalyzer] Detected ${allPatterns.length} patterns');

    // Phase 2: LLM enhancement (generate natural descriptions)
    final enhancedPatterns = await _enhancePatternsWithLLM(allPatterns, events);

    // Save patterns
    for (final pattern in enhancedPatterns) {
      await _habitTracker.savePattern(pattern);
    }

    return enhancedPatterns;
  }

  /// Detect time-based patterns
  List<HabitPattern> _detectTimePatterns(List<UsageEvent> events) {
    final patterns = <HabitPattern>[];

    // Group events by mode
    final byMode = <String, List<UsageEvent>>{};
    for (final event in events.where((e) => e.isActivation)) {
      byMode.putIfAbsent(event.modeId, () => []).add(event);
    }

    // Analyze each mode
    for (final entry in byMode.entries) {
      final modeId = entry.key;
      final modeEvents = entry.value;

      if (modeEvents.length < minOccurrences) continue;

      // Check for time-of-day patterns
      final todPattern = _detectTimeOfDayPattern(modeId, modeEvents);
      if (todPattern != null) patterns.add(todPattern);

      // Check for hourly patterns
      final hourPattern = _detectHourlyPattern(modeId, modeEvents);
      if (hourPattern != null) patterns.add(hourPattern);

      // Check for day-of-week patterns
      final dowPattern = _detectDayOfWeekPattern(modeId, modeEvents);
      if (dowPattern != null) patterns.add(dowPattern);
    }

    return patterns;
  }

  /// Detect time-of-day pattern (morning/afternoon/evening/night)
  HabitPattern? _detectTimeOfDayPattern(String modeId, List<UsageEvent> events) {
    final todCounts = <String, int>{};
    for (final event in events) {
      todCounts[event.timeOfDay] = (todCounts[event.timeOfDay] ?? 0) + 1;
    }

    // Find dominant time of day
    final total = events.length;
    for (final entry in todCounts.entries) {
      final ratio = entry.value / total;
      if (ratio >= 0.5 && entry.value >= minOccurrences) {
        return HabitPattern(
          id: 'pattern_${modeId}_tod_${DateTime.now().millisecondsSinceEpoch}',
          modeId: modeId,
          patternType: 'time_based',
          description: 'You often use $modeId mode in the ${entry.key}',
          confidence: ratio,
          occurrences: entry.value,
          conditions: PatternConditions(timeOfDay: entry.key),
          detectedAt: DateTime.now(),
          lastSeen: events.last.timestamp,
        );
      }
    }
    return null;
  }

  /// Detect hourly pattern (specific hours)
  HabitPattern? _detectHourlyPattern(String modeId, List<UsageEvent> events) {
    final hourCounts = <int, int>{};
    for (final event in events) {
      hourCounts[event.hourOfDay] = (hourCounts[event.hourOfDay] ?? 0) + 1;
    }

    // Find peak hours (within 2-hour window)
    int maxCount = 0;
    List<int> peakHours = [];

    for (int h = 0; h < 24; h++) {
      final windowCount = (hourCounts[h] ?? 0) +
          (hourCounts[(h + 1) % 24] ?? 0) +
          (hourCounts[(h + 2) % 24] ?? 0);

      if (windowCount > maxCount) {
        maxCount = windowCount;
        peakHours = [h, (h + 1) % 24, (h + 2) % 24];
      }
    }

    final ratio = maxCount / events.length;
    if (ratio >= 0.5 && maxCount >= minOccurrences) {
      final hourStr = peakHours.first;
      return HabitPattern(
        id: 'pattern_${modeId}_hour_${DateTime.now().millisecondsSinceEpoch}',
        modeId: modeId,
        patternType: 'time_based',
        description: 'You tend to use $modeId mode around ${hourStr}:00',
        confidence: ratio,
        occurrences: maxCount,
        conditions: PatternConditions(hours: peakHours),
        detectedAt: DateTime.now(),
        lastSeen: events.last.timestamp,
      );
    }
    return null;
  }

  /// Detect day-of-week pattern
  HabitPattern? _detectDayOfWeekPattern(String modeId, List<UsageEvent> events) {
    final dowCounts = <String, int>{};
    for (final event in events) {
      dowCounts[event.dayOfWeek] = (dowCounts[event.dayOfWeek] ?? 0) + 1;
    }

    // Check for weekend vs weekday pattern
    final weekendCount = (dowCounts['saturday'] ?? 0) + (dowCounts['sunday'] ?? 0);
    final weekdayCount = events.length - weekendCount;

    final totalDays = events.map((e) => e.dayOfWeek).toSet().length;
    if (totalDays < 3) return null; // Not enough day variety

    // Strong weekend pattern
    if (weekendCount >= minOccurrences && weekendCount / events.length >= 0.6) {
      return HabitPattern(
        id: 'pattern_${modeId}_weekend_${DateTime.now().millisecondsSinceEpoch}',
        modeId: modeId,
        patternType: 'time_based',
        description: 'You use $modeId mode mostly on weekends',
        confidence: weekendCount / events.length,
        occurrences: weekendCount,
        conditions: PatternConditions(daysOfWeek: ['saturday', 'sunday']),
        detectedAt: DateTime.now(),
        lastSeen: events.last.timestamp,
      );
    }

    // Strong weekday pattern
    if (weekdayCount >= minOccurrences && weekdayCount / events.length >= 0.7) {
      return HabitPattern(
        id: 'pattern_${modeId}_weekday_${DateTime.now().millisecondsSinceEpoch}',
        modeId: modeId,
        patternType: 'time_based',
        description: 'You use $modeId mode mainly on weekdays',
        confidence: weekdayCount / events.length,
        occurrences: weekdayCount,
        conditions: PatternConditions(
          daysOfWeek: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
        ),
        detectedAt: DateTime.now(),
        lastSeen: events.last.timestamp,
      );
    }

    return null;
  }

  /// Detect context-based patterns (light, motion)
  List<HabitPattern> _detectContextPatterns(List<UsageEvent> events) {
    final patterns = <HabitPattern>[];

    // Group events by mode
    final byMode = <String, List<UsageEvent>>{};
    for (final event in events.where((e) => e.isActivation && e.ambientLight != null)) {
      byMode.putIfAbsent(event.modeId, () => []).add(event);
    }

    for (final entry in byMode.entries) {
      final modeId = entry.key;
      final modeEvents = entry.value;

      if (modeEvents.length < minOccurrences) continue;

      // Check ambient light correlation
      final lightCounts = <String, int>{};
      for (final event in modeEvents) {
        if (event.ambientLight != null) {
          lightCounts[event.ambientLight!] =
              (lightCounts[event.ambientLight!] ?? 0) + 1;
        }
      }

      for (final lightEntry in lightCounts.entries) {
        final ratio = lightEntry.value / modeEvents.length;
        if (ratio >= 0.6 && lightEntry.value >= minOccurrences) {
          // Special handling for Vision mode + low light
          String description;
          if (modeId == 'vision' && lightEntry.key == 'low') {
            description = 'You often use Vision mode when lighting is dim';
          } else {
            description =
                'You tend to use $modeId mode when ambient light is ${lightEntry.key}';
          }

          patterns.add(HabitPattern(
            id: 'pattern_${modeId}_light_${DateTime.now().millisecondsSinceEpoch}',
            modeId: modeId,
            patternType: 'context_based',
            description: description,
            confidence: ratio,
            occurrences: lightEntry.value,
            conditions: PatternConditions(ambientLight: lightEntry.key),
            detectedAt: DateTime.now(),
            lastSeen: modeEvents.last.timestamp,
          ));
        }
      }

      // Check device motion correlation
      final motionCounts = <String, int>{};
      for (final event in modeEvents) {
        if (event.deviceMotion != null) {
          motionCounts[event.deviceMotion!] =
              (motionCounts[event.deviceMotion!] ?? 0) + 1;
        }
      }

      for (final motionEntry in motionCounts.entries) {
        final ratio = motionEntry.value / modeEvents.length;
        if (ratio >= 0.7 && motionEntry.value >= minOccurrences) {
          String motionDesc;
          switch (motionEntry.key) {
            case 'still':
              motionDesc = 'when relaxing or sitting still';
              break;
            case 'walking':
              motionDesc = 'while walking or moving';
              break;
            case 'shaky':
              motionDesc = 'when device is shaky';
              break;
            default:
              motionDesc = 'when ${motionEntry.key}';
          }

          patterns.add(HabitPattern(
            id: 'pattern_${modeId}_motion_${DateTime.now().millisecondsSinceEpoch}',
            modeId: modeId,
            patternType: 'context_based',
            description: 'You use $modeId mode $motionDesc',
            confidence: ratio,
            occurrences: motionEntry.value,
            conditions: PatternConditions(deviceMotion: motionEntry.key),
            detectedAt: DateTime.now(),
            lastSeen: modeEvents.last.timestamp,
          ));
        }
      }
    }

    return patterns;
  }

  /// Detect sequence patterns (mode A followed by mode B)
  List<HabitPattern> _detectSequencePatterns(List<UsageEvent> events) {
    final patterns = <HabitPattern>[];

    // Sort events by timestamp
    final sorted = events.where((e) => e.isActivation).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sorted.length < 4) return patterns;

    // Track sequences (mode A -> mode B within 30 minutes)
    final sequences = <String, int>{};
    for (int i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i];
      final next = sorted[i + 1];

      final timeDiff = next.timestamp.difference(current.timestamp);
      if (timeDiff.inMinutes <= 30 && timeDiff.inMinutes > 0) {
        final key = '${current.modeId}->${next.modeId}';
        sequences[key] = (sequences[key] ?? 0) + 1;
      }
    }

    // Find significant sequences
    for (final entry in sequences.entries) {
      if (entry.value >= minOccurrences) {
        final parts = entry.key.split('->');
        final fromMode = parts[0];
        final toMode = parts[1];

        if (fromMode == toMode) continue; // Skip self-transitions

        patterns.add(HabitPattern(
          id: 'pattern_seq_${fromMode}_${toMode}_${DateTime.now().millisecondsSinceEpoch}',
          modeId: toMode,
          patternType: 'sequence',
          description: 'You often switch from $fromMode to $toMode mode',
          confidence: entry.value / (sorted.length - 1),
          occurrences: entry.value,
          conditions: PatternConditions(previousModeId: fromMode),
          detectedAt: DateTime.now(),
          lastSeen: sorted.last.timestamp,
        ));
      }
    }

    return patterns;
  }

  /// Enhance patterns with LLM-generated descriptions
  Future<List<HabitPattern>> _enhancePatternsWithLLM(
    List<HabitPattern> patterns,
    List<UsageEvent> events,
  ) async {
    if (patterns.isEmpty || !_llmService.isReady) {
      return patterns;
    }

    // For now, just return the patterns with their template descriptions
    // In a full implementation, we'd call the LLM to generate more natural descriptions
    debugPrint('[PatternAnalyzer] Patterns ready (LLM enhancement skipped for performance)');

    return patterns;
  }

  /// Check if analysis should run (not too frequent)
  Future<bool> shouldRunAnalysis() async {
    final patterns = await _habitTracker.getPatterns();

    // Run if no patterns exist
    if (patterns.isEmpty) return true;

    // Run if last pattern is old
    final lastPattern = patterns
        .map((p) => p.detectedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return DateTime.now().difference(lastPattern).inHours >= 24;
  }

  /// Get patterns relevant to current context
  Future<List<HabitPattern>> getRelevantPatterns({
    required String? currentTimeOfDay,
    required int currentHour,
    required String? ambientLight,
    required String? deviceMotion,
    String? previousModeId,
  }) async {
    final patterns = await _habitTracker.getActivePatterns();

    return patterns.where((pattern) {
      final conditions = pattern.conditions;
      if (conditions == null || conditions.isEmpty) return false;

      // Check time of day match
      if (conditions.timeOfDay != null &&
          conditions.timeOfDay != currentTimeOfDay) {
        return false;
      }

      // Check hour match (within window)
      if (conditions.hours != null && conditions.hours!.isNotEmpty) {
        if (!conditions.hours!.contains(currentHour) &&
            !conditions.hours!.contains((currentHour + 1) % 24) &&
            !conditions.hours!.contains((currentHour - 1 + 24) % 24)) {
          return false;
        }
      }

      // Check ambient light match
      if (conditions.ambientLight != null &&
          conditions.ambientLight != ambientLight) {
        return false;
      }

      // Check motion match
      if (conditions.deviceMotion != null &&
          conditions.deviceMotion != deviceMotion) {
        return false;
      }

      // Check sequence match
      if (conditions.previousModeId != null &&
          conditions.previousModeId != previousModeId) {
        return false;
      }

      return true;
    }).toList();
  }
}

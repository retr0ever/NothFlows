import 'package:hive/hive.dart';

part 'habit_pattern.g.dart';

/// Status of a detected pattern
@HiveType(typeId: 14)
enum PatternStatus {
  @HiveField(0)
  pending, // Detected but not yet shown to user

  @HiveField(1)
  active, // Shown to user, available for suggestions

  @HiveField(2)
  accepted, // User accepted a suggestion based on this

  @HiveField(3)
  dismissed, // User dismissed (temporary)

  @HiveField(4)
  blocked, // User said "don't suggest this" (permanent)
}

/// Conditions that trigger a pattern
@HiveType(typeId: 15)
class PatternConditions extends HiveObject {
  @HiveField(0)
  final List<int>? hours; // Hours when pattern applies (e.g., [19, 20, 21])

  @HiveField(1)
  final List<String>? daysOfWeek; // Days when pattern applies

  @HiveField(2)
  final String? timeOfDay; // 'morning', 'afternoon', 'evening', 'night'

  @HiveField(3)
  final String? ambientLight; // 'low', 'medium', 'high'

  @HiveField(4)
  final String? deviceMotion; // 'still', 'walking', 'shaky'

  @HiveField(5)
  final String? previousModeId; // Pattern follows another mode (sequence)

  PatternConditions({
    this.hours,
    this.daysOfWeek,
    this.timeOfDay,
    this.ambientLight,
    this.deviceMotion,
    this.previousModeId,
  });

  /// Check if conditions are empty
  bool get isEmpty =>
      hours == null &&
      daysOfWeek == null &&
      timeOfDay == null &&
      ambientLight == null &&
      deviceMotion == null &&
      previousModeId == null;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        if (hours != null) 'hours': hours,
        if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
        if (timeOfDay != null) 'timeOfDay': timeOfDay,
        if (ambientLight != null) 'ambientLight': ambientLight,
        if (deviceMotion != null) 'deviceMotion': deviceMotion,
        if (previousModeId != null) 'previousModeId': previousModeId,
      };

  /// Create from JSON
  factory PatternConditions.fromJson(Map<String, dynamic> json) {
    return PatternConditions(
      hours: json['hours'] != null ? List<int>.from(json['hours']) : null,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<String>.from(json['daysOfWeek'])
          : null,
      timeOfDay: json['timeOfDay'],
      ambientLight: json['ambientLight'],
      deviceMotion: json['deviceMotion'],
      previousModeId: json['previousModeId'],
    );
  }

  /// Get human-readable description
  String toReadableString() {
    final parts = <String>[];

    if (hours != null && hours!.isNotEmpty) {
      final hourStr = hours!.map((h) => '${h}:00').join(', ');
      parts.add('around $hourStr');
    }

    if (timeOfDay != null) {
      parts.add('in the $timeOfDay');
    }

    if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      if (daysOfWeek!.length == 2 &&
          daysOfWeek!.contains('saturday') &&
          daysOfWeek!.contains('sunday')) {
        parts.add('on weekends');
      } else if (daysOfWeek!.length == 5 &&
          !daysOfWeek!.contains('saturday') &&
          !daysOfWeek!.contains('sunday')) {
        parts.add('on weekdays');
      } else {
        parts.add('on ${daysOfWeek!.join(", ")}');
      }
    }

    if (ambientLight != null) {
      parts.add('when lighting is $ambientLight');
    }

    if (deviceMotion != null) {
      parts.add('when $deviceMotion');
    }

    if (previousModeId != null) {
      parts.add('after using $previousModeId mode');
    }

    return parts.isEmpty ? 'any time' : parts.join(', ');
  }
}

/// Represents a detected behavioral pattern
@HiveType(typeId: 11)
class HabitPattern extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String modeId;

  @HiveField(2)
  final String patternType; // 'time_based', 'context_based', 'sequence'

  @HiveField(3)
  final String description; // Human-readable (LLM-generated)

  @HiveField(4)
  final double confidence; // 0.0 - 1.0

  @HiveField(5)
  final int occurrences;

  @HiveField(6)
  final PatternConditions? conditions;

  @HiveField(7)
  final DateTime detectedAt;

  @HiveField(8)
  final DateTime lastSeen;

  @HiveField(9)
  final PatternStatus status;

  @HiveField(10)
  final String? llmRationale; // Why LLM detected this pattern

  @HiveField(11)
  final int acceptedCount;

  @HiveField(12)
  final int rejectedCount;

  @HiveField(13)
  final int ignoredCount;

  HabitPattern({
    required this.id,
    required this.modeId,
    required this.patternType,
    required this.description,
    required this.confidence,
    required this.occurrences,
    this.conditions,
    required this.detectedAt,
    required this.lastSeen,
    this.status = PatternStatus.pending,
    this.llmRationale,
    this.acceptedCount = 0,
    this.rejectedCount = 0,
    this.ignoredCount = 0,
  });

  /// Check if pattern is significant enough to suggest
  bool get isSignificant => confidence >= 0.6 && occurrences >= 3;

  /// Check if pattern is active (can be shown to user)
  bool get isActive =>
      status == PatternStatus.pending || status == PatternStatus.active;

  /// Calculate acceptance rate
  double get acceptanceRate {
    final total = acceptedCount + rejectedCount + ignoredCount;
    if (total == 0) return 0.5; // Neutral default
    return acceptedCount / total;
  }

  /// Create a copy with updated fields
  HabitPattern copyWith({
    String? id,
    String? modeId,
    String? patternType,
    String? description,
    double? confidence,
    int? occurrences,
    PatternConditions? conditions,
    DateTime? detectedAt,
    DateTime? lastSeen,
    PatternStatus? status,
    String? llmRationale,
    int? acceptedCount,
    int? rejectedCount,
    int? ignoredCount,
  }) {
    return HabitPattern(
      id: id ?? this.id,
      modeId: modeId ?? this.modeId,
      patternType: patternType ?? this.patternType,
      description: description ?? this.description,
      confidence: confidence ?? this.confidence,
      occurrences: occurrences ?? this.occurrences,
      conditions: conditions ?? this.conditions,
      detectedAt: detectedAt ?? this.detectedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
      llmRationale: llmRationale ?? this.llmRationale,
      acceptedCount: acceptedCount ?? this.acceptedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      ignoredCount: ignoredCount ?? this.ignoredCount,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'modeId': modeId,
        'patternType': patternType,
        'description': description,
        'confidence': confidence,
        'occurrences': occurrences,
        'conditions': conditions?.toJson(),
        'detectedAt': detectedAt.toIso8601String(),
        'lastSeen': lastSeen.toIso8601String(),
        'status': status.name,
        'llmRationale': llmRationale,
        'acceptedCount': acceptedCount,
        'rejectedCount': rejectedCount,
        'ignoredCount': ignoredCount,
      };

  @override
  String toString() =>
      'HabitPattern($modeId: $description, confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
}

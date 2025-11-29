import 'package:hive/hive.dart';

part 'user_preference.g.dart';

/// Represents a learned user preference from feedback
@HiveType(typeId: 12)
class UserPreference extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String preferenceType; // 'suggestion_style', 'voice_announcements', etc.

  @HiveField(2)
  final String value; // 'reminder_only', 'always', 'never', etc.

  @HiveField(3)
  final double confidence; // How confident we are in this preference (0.0-1.0)

  @HiveField(4)
  final DateTime learnedAt;

  @HiveField(5)
  final int evidenceCount; // Number of feedback events supporting this

  @HiveField(6)
  final DateTime lastUpdated;

  UserPreference({
    required this.id,
    required this.preferenceType,
    required this.value,
    required this.confidence,
    required this.learnedAt,
    required this.evidenceCount,
    required this.lastUpdated,
  });

  /// Create a new preference
  factory UserPreference.create({
    required String preferenceType,
    required String value,
    double confidence = 0.5,
    int evidenceCount = 1,
  }) {
    final now = DateTime.now();
    return UserPreference(
      id: 'pref_${preferenceType}_${now.millisecondsSinceEpoch}',
      preferenceType: preferenceType,
      value: value,
      confidence: confidence,
      learnedAt: now,
      evidenceCount: evidenceCount,
      lastUpdated: now,
    );
  }

  /// Create a copy with updated fields
  UserPreference copyWith({
    String? id,
    String? preferenceType,
    String? value,
    double? confidence,
    DateTime? learnedAt,
    int? evidenceCount,
    DateTime? lastUpdated,
  }) {
    return UserPreference(
      id: id ?? this.id,
      preferenceType: preferenceType ?? this.preferenceType,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      learnedAt: learnedAt ?? this.learnedAt,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  /// Check if this preference is reliable (high confidence + enough evidence)
  bool get isReliable => confidence >= 0.7 && evidenceCount >= 3;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'preferenceType': preferenceType,
        'value': value,
        'confidence': confidence,
        'learnedAt': learnedAt.toIso8601String(),
        'evidenceCount': evidenceCount,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  @override
  String toString() =>
      'UserPreference($preferenceType: $value, confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
}

/// Common preference types
class PreferenceTypes {
  static const String suggestionStyle = 'suggestion_style';
  static const String voiceAnnouncements = 'voice_announcements';
  static const String autoActivate = 'auto_activate';
  static const String suggestionFrequency = 'suggestion_frequency';

  // Values for suggestionStyle
  static const String reminderOnly = 'reminder_only';
  static const String fullAuto = 'full_auto';

  // Values for voiceAnnouncements
  static const String always = 'always';
  static const String highConfidenceOnly = 'high_confidence_only';
  static const String never = 'never';

  // Values for suggestionFrequency
  static const String frequent = 'frequent';
  static const String moderate = 'moderate';
  static const String minimal = 'minimal';
}

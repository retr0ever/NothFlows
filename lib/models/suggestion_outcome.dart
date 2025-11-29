import 'package:hive/hive.dart';

part 'suggestion_outcome.g.dart';

/// Outcome of a suggestion shown to the user
@HiveType(typeId: 16)
enum SuggestionOutcomeType {
  @HiveField(0)
  accepted, // User activated the suggested mode

  @HiveField(1)
  rejected, // User explicitly dismissed/rejected

  @HiveField(2)
  ignored, // Suggestion timed out without action

  @HiveField(3)
  blocked, // User said "don't suggest this"
}

/// Represents the outcome of a suggestion shown to the user
@HiveType(typeId: 13)
class SuggestionOutcome extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String suggestionId;

  @HiveField(2)
  final String patternId;

  @HiveField(3)
  final String modeId;

  @HiveField(4)
  final SuggestionOutcomeType outcome;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final String? reason; // Optional reason from user

  @HiveField(7)
  final int responseTimeMs; // How long user took to respond (0 if ignored)

  @HiveField(8)
  final String? contextAtTime; // Serialized context when shown

  SuggestionOutcome({
    required this.id,
    required this.suggestionId,
    required this.patternId,
    required this.modeId,
    required this.outcome,
    required this.timestamp,
    this.reason,
    this.responseTimeMs = 0,
    this.contextAtTime,
  });

  /// Create a new outcome record
  factory SuggestionOutcome.create({
    required String suggestionId,
    required String patternId,
    required String modeId,
    required SuggestionOutcomeType outcome,
    String? reason,
    int responseTimeMs = 0,
    String? contextAtTime,
  }) {
    final now = DateTime.now();
    return SuggestionOutcome(
      id: 'outcome_${now.millisecondsSinceEpoch}',
      suggestionId: suggestionId,
      patternId: patternId,
      modeId: modeId,
      outcome: outcome,
      timestamp: now,
      reason: reason,
      responseTimeMs: responseTimeMs,
      contextAtTime: contextAtTime,
    );
  }

  /// Check if this was a positive outcome
  bool get isPositive => outcome == SuggestionOutcomeType.accepted;

  /// Check if this was a negative outcome
  bool get isNegative =>
      outcome == SuggestionOutcomeType.rejected ||
      outcome == SuggestionOutcomeType.blocked;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'suggestionId': suggestionId,
        'patternId': patternId,
        'modeId': modeId,
        'outcome': outcome.name,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
        'responseTimeMs': responseTimeMs,
        'contextAtTime': contextAtTime,
      };

  @override
  String toString() =>
      'SuggestionOutcome($modeId: ${outcome.name})';
}

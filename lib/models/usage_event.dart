import 'package:hive/hive.dart';

part 'usage_event.g.dart';

/// Represents a single usage event for habit tracking
@HiveType(typeId: 10)
class UsageEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String modeId;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String timeOfDay; // 'morning', 'afternoon', 'evening', 'night'

  @HiveField(4)
  final int hourOfDay; // 0-23 for precise patterns

  @HiveField(5)
  final String dayOfWeek; // 'monday', 'tuesday', etc.

  @HiveField(6)
  final String? ambientLight; // 'low', 'medium', 'high' from SensorService

  @HiveField(7)
  final String? deviceMotion; // 'still', 'walking', 'shaky' from SensorService

  @HiveField(8)
  final String triggerSource; // 'manual', 'voice'

  @HiveField(9)
  final List<String>? flowActions; // actions executed (if any)

  @HiveField(10)
  final bool isActivation; // true = mode activated, false = deactivated

  UsageEvent({
    required this.id,
    required this.modeId,
    required this.timestamp,
    required this.timeOfDay,
    required this.hourOfDay,
    required this.dayOfWeek,
    this.ambientLight,
    this.deviceMotion,
    required this.triggerSource,
    this.flowActions,
    this.isActivation = true,
  });

  /// Create a usage event with auto-generated context
  factory UsageEvent.create({
    required String modeId,
    required String triggerSource,
    String? ambientLight,
    String? deviceMotion,
    List<String>? flowActions,
    bool isActivation = true,
  }) {
    final now = DateTime.now();
    return UsageEvent(
      id: 'event_${now.millisecondsSinceEpoch}',
      modeId: modeId,
      timestamp: now,
      timeOfDay: _getTimeOfDay(now.hour),
      hourOfDay: now.hour,
      dayOfWeek: _getDayOfWeek(now.weekday),
      ambientLight: ambientLight,
      deviceMotion: deviceMotion,
      triggerSource: triggerSource,
      flowActions: flowActions,
      isActivation: isActivation,
    );
  }

  /// Get time of day string from hour
  static String _getTimeOfDay(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  /// Get day of week string from weekday number
  static String _getDayOfWeek(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[weekday - 1];
  }

  /// Check if this is a weekend event
  bool get isWeekend => dayOfWeek == 'saturday' || dayOfWeek == 'sunday';

  /// Convert to JSON for debugging/export
  Map<String, dynamic> toJson() => {
        'id': id,
        'modeId': modeId,
        'timestamp': timestamp.toIso8601String(),
        'timeOfDay': timeOfDay,
        'hourOfDay': hourOfDay,
        'dayOfWeek': dayOfWeek,
        'ambientLight': ambientLight,
        'deviceMotion': deviceMotion,
        'triggerSource': triggerSource,
        'flowActions': flowActions,
        'isActivation': isActivation,
      };

  @override
  String toString() =>
      'UsageEvent($modeId at $timeOfDay, ${isActivation ? "on" : "off"})';
}

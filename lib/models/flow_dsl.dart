import 'dart:convert';

/// Represents a single accessibility action in a flow
class FlowAction {
  final String type;
  final Map<String, dynamic> parameters;

  FlowAction({
    required this.type,
    required this.parameters,
  });

  factory FlowAction.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final parameters = Map<String, dynamic>.from(json);
    parameters.remove('type');

    return FlowAction(
      type: type,
      parameters: parameters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      ...parameters,
    };
  }

  @override
  String toString() => 'FlowAction(type: $type, params: $parameters)';
}

/// Represents conditions that trigger a flow
/// Supports sensory and context-based triggers
class FlowConditions {
  final String? ambientLight; // 'low', 'medium', 'high'
  final String? noiseLevel; // 'quiet', 'moderate', 'loud'
  final String? deviceMotion; // 'still', 'walking', 'shaky'
  final List<String>? recentUsage; // Recently used apps
  final String? timeOfDay; // 'morning', 'afternoon', 'evening', 'night'
  final int? batteryLevel; // 0-100
  final bool? isCharging;

  FlowConditions({
    this.ambientLight,
    this.noiseLevel,
    this.deviceMotion,
    this.recentUsage,
    this.timeOfDay,
    this.batteryLevel,
    this.isCharging,
  });

  factory FlowConditions.fromJson(Map<String, dynamic> json) {
    return FlowConditions(
      ambientLight: json['ambient_light'] as String?,
      noiseLevel: json['noise_level'] as String?,
      deviceMotion: json['device_motion'] as String?,
      recentUsage: (json['recent_usage'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      timeOfDay: json['time_of_day'] as String?,
      batteryLevel: json['battery_level'] as int?,
      isCharging: json['is_charging'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (ambientLight != null) map['ambient_light'] = ambientLight;
    if (noiseLevel != null) map['noise_level'] = noiseLevel;
    if (deviceMotion != null) map['device_motion'] = deviceMotion;
    if (recentUsage != null) map['recent_usage'] = recentUsage;
    if (timeOfDay != null) map['time_of_day'] = timeOfDay;
    if (batteryLevel != null) map['battery_level'] = batteryLevel;
    if (isCharging != null) map['is_charging'] = isCharging;
    return map;
  }

  bool get isEmpty => ambientLight == null && noiseLevel == null &&
      deviceMotion == null && recentUsage == null && timeOfDay == null &&
      batteryLevel == null && isCharging == null;

  @override
  String toString() => 'FlowConditions(${toJson()})';
}

/// DSL representation of an accessibility automation flow
/// Supports conditional triggers based on sensory and context data
class FlowDSL {
  final String trigger;
  final FlowConditions? conditions;
  final List<FlowAction> actions;
  final String? id;
  final DateTime? createdAt;

  FlowDSL({
    required this.trigger,
    this.conditions,
    required this.actions,
    this.id,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Validates the DSL structure for accessibility flows
  bool isValid() {
    if (trigger.isEmpty) return false;
    if (actions.isEmpty) return false;

    // Validate trigger format: "assistive_mode.on:modeName" or "assistive_mode.off:modeName"
    final triggerPattern = RegExp(r'^(mode|assistive_mode)\.(on|off):(vision|motor|neurodivergent|calm|hearing|custom|sleep|focus)$');
    if (!triggerPattern.hasMatch(trigger)) return false;

    // Validate each action has a valid type (expanded for accessibility)
    final validActionTypes = {
      // Original actions
      'clean_screenshots',
      'clean_downloads',
      'mute_apps',
      'lower_brightness',
      'set_volume',
      'enable_dnd',
      'disable_wifi',
      'disable_bluetooth',
      'set_wallpaper',
      'launch_app',
      // New accessibility actions
      'increase_text_size',
      'increase_contrast',
      'enable_screen_reader',
      'reduce_animation',
      'boost_brightness',
      'reduce_gesture_sensitivity',
      'enable_voice_typing',
      'enable_live_transcribe',
      'simplify_home_screen',
      'mute_distraction_apps',
      'highlight_focus_apps',
      'launch_care_app',
      'enable_high_visibility',
      'enable_captions',
      'flash_screen_alerts',
      'boost_haptic_feedback',
      'enable_one_handed_mode',
      'increase_touch_targets',
      // Voice command actions
      'voice_activation',
      'speak_response',
    };

    for (final action in actions) {
      if (!validActionTypes.contains(action.type)) return false;
    }

    return true;
  }

  /// Parse from JSON string
  factory FlowDSL.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return FlowDSL.fromJson(json);
  }

  /// Parse from JSON map
  factory FlowDSL.fromJson(Map<String, dynamic> json) {
    return FlowDSL(
      trigger: json['trigger'] as String,
      conditions: json['conditions'] != null
          ? FlowConditions.fromJson(json['conditions'] as Map<String, dynamic>)
          : null,
      actions: (json['actions'] as List<dynamic>)
          .map((a) => FlowAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      id: json['id'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'trigger': trigger,
      if (conditions != null && !conditions!.isEmpty) 'conditions': conditions!.toJson(),
      'actions': actions.map((a) => a.toJson()).toList(),
      if (id != null) 'id': id,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Convert to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Get human-readable description
  String getDescription() {
    final buffer = StringBuffer();
    final mode = trigger.split(':').last;
    final event = trigger.contains('on') ? 'activated' : 'deactivated';

    buffer.writeln('When $mode mode is $event:');
    for (final action in actions) {
      buffer.write('  • ');
      switch (action.type) {
        case 'clean_screenshots':
          final days = action.parameters['older_than_days'] ?? 30;
          buffer.writeln('Clean screenshots older than $days days');
          break;
        case 'clean_downloads':
          final days = action.parameters['older_than_days'] ?? 30;
          buffer.writeln('Clean downloads older than $days days');
          break;
        case 'mute_apps':
          final apps = action.parameters['apps'] as List<dynamic>? ?? [];
          buffer.writeln('Mute apps: ${apps.join(", ")}');
          break;
        case 'lower_brightness':
          final level = action.parameters['to'] ?? 20;
          buffer.writeln('Set brightness to $level%');
          break;
        case 'set_volume':
          final level = action.parameters['level'] ?? 50;
          buffer.writeln('Set volume to $level%');
          break;
        case 'enable_dnd':
          buffer.writeln('Enable Do Not Disturb');
          break;
        case 'disable_wifi':
          buffer.writeln('Disable Wi-Fi');
          break;
        case 'disable_bluetooth':
          buffer.writeln('Disable Bluetooth');
          break;
        case 'set_wallpaper':
          final path = action.parameters['path'] ?? 'default';
          buffer.writeln('Set wallpaper to $path');
          break;
        case 'launch_app':
          final app = action.parameters['app'] ?? 'unknown';
          buffer.writeln('Launch $app');
          break;

        // Vision Assist actions
        case 'increase_text_size':
          final size = action.parameters['to'] ?? 'large';
          buffer.writeln('Increase text size to $size');
          break;
        case 'increase_contrast':
        case 'enable_high_visibility':
          buffer.writeln('Enable high contrast mode');
          break;
        case 'enable_screen_reader':
          buffer.writeln('Enable screen reader (TalkBack)');
          break;
        case 'boost_brightness':
          final level = action.parameters['to'] ?? 100;
          buffer.writeln('Boost brightness to $level%');
          break;

        // Motor Assist actions
        case 'reduce_gesture_sensitivity':
          buffer.writeln('Reduce gesture sensitivity');
          break;
        case 'enable_voice_typing':
          buffer.writeln('Enable voice typing');
          break;
        case 'enable_one_handed_mode':
          buffer.writeln('Enable one-handed mode');
          break;
        case 'increase_touch_targets':
          buffer.writeln('Increase touch target sizes');
          break;

        // Cognitive/Neurodivergent actions
        case 'reduce_animation':
          buffer.writeln('Reduce animation speed');
          break;
        case 'simplify_home_screen':
          buffer.writeln('Simplify home screen layout');
          break;
        case 'mute_distraction_apps':
          buffer.writeln('Mute distraction apps');
          break;
        case 'highlight_focus_apps':
          buffer.writeln('Highlight focus apps');
          break;

        // Hearing Support actions
        case 'enable_live_transcribe':
          buffer.writeln('Enable Live Transcribe');
          break;
        case 'enable_captions':
          buffer.writeln('Enable system-wide captions');
          break;
        case 'flash_screen_alerts':
          buffer.writeln('Enable screen flash for alerts');
          break;
        case 'boost_haptic_feedback':
          final strength = action.parameters['strength'] ?? 'strong';
          buffer.writeln('Boost haptic feedback ($strength)');
          break;

        // Safety action
        case 'launch_care_app':
          final app = action.parameters['app'] ?? 'Emergency Contacts';
          buffer.writeln('Launch $app');
          break;

        default:
          buffer.writeln(action.type);
      }
    }
    return buffer.toString().trim();
  }

  FlowDSL copyWith({
    String? trigger,
    FlowConditions? conditions,
    List<FlowAction>? actions,
    String? id,
    DateTime? createdAt,
  }) {
    return FlowDSL(
      trigger: trigger ?? this.trigger,
      conditions: conditions ?? this.conditions,
      actions: actions ?? this.actions,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'FlowDSL(trigger: $trigger, actions: ${actions.length})';
}

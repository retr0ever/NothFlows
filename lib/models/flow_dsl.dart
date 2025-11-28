import 'dart:convert';

/// Represents a single action in a flow
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

/// DSL representation of a flow automation
class FlowDSL {
  final String trigger;
  final List<FlowAction> actions;
  final String? id;
  final DateTime? createdAt;

  FlowDSL({
    required this.trigger,
    required this.actions,
    this.id,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Validates the DSL structure
  bool isValid() {
    if (trigger.isEmpty) return false;
    if (actions.isEmpty) return false;

    // Validate trigger format: "mode.on:modeName" or "mode.off:modeName"
    final triggerPattern = RegExp(r'^mode\.(on|off):(sleep|focus|custom)$');
    if (!triggerPattern.hasMatch(trigger)) return false;

    // Validate each action has a valid type
    final validActionTypes = {
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
        default:
          buffer.writeln(action.type);
      }
    }
    return buffer.toString().trim();
  }

  FlowDSL copyWith({
    String? trigger,
    List<FlowAction>? actions,
    String? id,
    DateTime? createdAt,
  }) {
    return FlowDSL(
      trigger: trigger ?? this.trigger,
      actions: actions ?? this.actions,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'FlowDSL(trigger: $trigger, actions: ${actions.length})';
}

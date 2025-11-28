import 'package:flutter/material.dart';
import 'flow_dsl.dart';

/// Represents a mode (Sleep, Focus, Custom) with associated flows
class ModeModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<FlowDSL> flows;
  final bool isActive;
  final DateTime? lastActivated;

  ModeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    List<FlowDSL>? flows,
    this.isActive = false,
    this.lastActivated,
  }) : flows = flows ?? [];

  /// Predefined modes
  static ModeModel get sleep => ModeModel(
        id: 'sleep',
        name: 'Sleep',
        description: 'Wind down for the night',
        icon: Icons.nightlight_round,
        color: const Color(0xFF5B4DFF),
      );

  static ModeModel get focus => ModeModel(
        id: 'focus',
        name: 'Focus',
        description: 'Minimise distractions',
        icon: Icons.lightbulb_outline,
        color: const Color(0xFFFF4D4D),
      );

  static ModeModel get custom => ModeModel(
        id: 'custom',
        name: 'Custom',
        description: 'Create your own mode',
        icon: Icons.tune,
        color: const Color(0xFF4DFF88),
      );

  static List<ModeModel> get defaults => [sleep, focus, custom];

  /// Get example flows for this mode
  List<String> get exampleFlows {
    switch (id) {
      case 'sleep':
        return [
          'Clean screenshots older than 30 days',
          'Lower brightness to 20%',
          'Enable Do Not Disturb',
          'Mute all social media apps',
          'Set volume to 10%',
        ];
      case 'focus':
        return [
          'Mute Instagram, TikTok, and Twitter',
          'Enable Do Not Disturb',
          'Clean downloads older than 7 days',
          'Set brightness to 80%',
          'Launch Notion',
        ];
      case 'custom':
        return [
          'Disable Wi-Fi and Bluetooth',
          'Clean screenshots older than 14 days',
          'Set volume to 0%',
          'Lower brightness to 50%',
        ];
      default:
        return [];
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color.value,
      'flows': flows.map((f) => f.toJson()).toList(),
      'isActive': isActive,
      'lastActivated': lastActivated?.toIso8601String(),
    };
  }

  /// Parse from JSON
  factory ModeModel.fromJson(Map<String, dynamic> json) {
    // Get the default mode to retrieve icon
    final defaultMode = ModeModel.defaults.firstWhere(
      (m) => m.id == json['id'],
      orElse: () => ModeModel.custom,
    );

    return ModeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: defaultMode.icon,
      color: Color(json['color'] as int),
      flows: (json['flows'] as List<dynamic>?)
              ?.map((f) => FlowDSL.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? false,
      lastActivated: json['lastActivated'] != null
          ? DateTime.parse(json['lastActivated'] as String)
          : null,
    );
  }

  /// Add a flow to this mode
  ModeModel addFlow(FlowDSL flow) {
    return copyWith(flows: [...flows, flow]);
  }

  /// Remove a flow from this mode
  ModeModel removeFlow(String flowId) {
    return copyWith(
      flows: flows.where((f) => f.id != flowId).toList(),
    );
  }

  /// Toggle mode activation
  ModeModel toggleActive() {
    return copyWith(
      isActive: !isActive,
      lastActivated: !isActive ? DateTime.now() : lastActivated,
    );
  }

  ModeModel copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    List<FlowDSL>? flows,
    bool? isActive,
    DateTime? lastActivated,
  }) {
    return ModeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      flows: flows ?? this.flows,
      isActive: isActive ?? this.isActive,
      lastActivated: lastActivated ?? this.lastActivated,
    );
  }

  @override
  String toString() => 'ModeModel(id: $id, name: $name, flows: ${flows.length}, active: $isActive)';
}

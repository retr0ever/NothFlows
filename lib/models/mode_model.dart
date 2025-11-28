import 'package:flutter/material.dart';
import 'flow_dsl.dart';

/// Represents an assistive mode (Vision, Motor, Neurodivergent, Calm, Hearing, Custom) with associated flows
/// Accessibility-first automation modes designed for disabled users
class ModeModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<FlowDSL> flows;
  final bool isActive;
  final DateTime? lastActivated;
  final String category; // 'vision', 'motor', 'cognitive', 'sensory', 'custom'

  ModeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    List<FlowDSL>? flows,
    this.isActive = false,
    this.lastActivated,
  }) : flows = flows ?? [];

  /// Predefined assistive modes
  static ModeModel get visionAssist => ModeModel(
        id: 'vision',
        name: 'Vision Assist',
        description: 'Enhance readability and screen clarity',
        icon: Icons.visibility,
        color: const Color(0xFF4D9FFF),
        category: 'vision',
      );

  static ModeModel get motorAssist => ModeModel(
        id: 'motor',
        name: 'Motor Assist',
        description: 'Reduce gesture complexity and simplify interactions',
        icon: Icons.touch_app,
        color: const Color(0xFF9F4DFF),
        category: 'motor',
      );

  static ModeModel get neurodivergentFocus => ModeModel(
        id: 'neurodivergent',
        name: 'Neurodivergent Focus',
        description: 'Minimise distractions and sensory overload',
        icon: Icons.psychology,
        color: const Color(0xFFFF4D9F),
        category: 'cognitive',
      );

  static ModeModel get calmMode => ModeModel(
        id: 'calm',
        name: 'Calm Mode',
        description: 'Reduce anxiety and overstimulation',
        icon: Icons.self_improvement,
        color: const Color(0xFF4DFFB8),
        category: 'sensory',
      );

  static ModeModel get hearingSupport => ModeModel(
        id: 'hearing',
        name: 'Hearing Support',
        description: 'Enable captions and visual notifications',
        icon: Icons.hearing,
        color: const Color(0xFFFFB84D),
        category: 'sensory',
      );

  static ModeModel get customAssistive => ModeModel(
        id: 'custom',
        name: 'Custom Assistive',
        description: 'Build your own assistive routine',
        icon: Icons.accessibility_new,
        color: const Color(0xFF4DFF88),
        category: 'custom',
      );

  static List<ModeModel> get defaults => [
        visionAssist,
        motorAssist,
        neurodivergentFocus,
        calmMode,
        hearingSupport,
        customAssistive,
      ];

  /// Get example flows for this assistive mode
  List<String> get exampleFlows {
    switch (id) {
      case 'vision':
        return [
          'Increase text size to maximum',
          'Increase contrast and enable high visibility',
          'Boost brightness to 100%',
          'Enable screen reader',
          'Reduce animation speed',
        ];
      case 'motor':
        return [
          'Reduce gesture sensitivity',
          'Simplify home screen layout',
          'Enable voice typing',
          'Increase touch target sizes',
          'Enable one-handed mode',
        ];
      case 'neurodivergent':
        return [
          'Mute all distraction apps',
          'Enable Do Not Disturb',
          'Reduce animation and transitions',
          'Highlight focus apps only',
          'Set calm wallpaper',
        ];
      case 'calm':
        return [
          'Enable Do Not Disturb',
          'Lower brightness to 30%',
          'Set volume to 10%',
          'Reduce animation speed',
          'Mute all notifications',
        ];
      case 'hearing':
        return [
          'Enable live transcribe',
          'Enable visual notification alerts',
          'Boost haptic feedback',
          'Enable captions everywhere',
          'Flash screen for alerts',
        ];
      case 'custom':
        return [
          'Build your own assistive routine',
          'Combine multiple accessibility features',
          'Create personalized workflows',
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
      'category': category,
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
      orElse: () => ModeModel.customAssistive,
    );

    return ModeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? 'custom',
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
    String? category,
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
      category: category ?? this.category,
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

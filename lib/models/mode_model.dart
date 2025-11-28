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
        flows: [
          FlowDSL(
            trigger: 'mode.on:vision',
            actions: [
              FlowAction(type: 'increase_text_size', parameters: {'to': 'large'}),
              FlowAction(type: 'increase_contrast', parameters: {}),
              FlowAction(type: 'boost_brightness', parameters: {'to': 100}),
            ],
          ),
          FlowDSL(
            trigger: 'mode.off:vision',
            actions: [
              FlowAction(type: 'increase_text_size', parameters: {'to': 'medium'}),
              FlowAction(type: 'set_volume', parameters: {'level': 50}),
            ],
          ),
        ],
      );

  static ModeModel get motorAssist => ModeModel(
        id: 'motor',
        name: 'Motor Assist',
        description: 'Reduce gesture complexity and simplify interactions',
        icon: Icons.touch_app,
        color: const Color(0xFF9F4DFF),
        category: 'motor',
        flows: [
          FlowDSL(
            trigger: 'mode.on:motor',
            actions: [
              FlowAction(type: 'reduce_gesture_sensitivity', parameters: {}),
              FlowAction(type: 'enable_voice_typing', parameters: {}),
              FlowAction(type: 'increase_touch_targets', parameters: {}),
            ],
          ),
          FlowDSL(
            trigger: 'mode.off:motor',
            actions: [
              FlowAction(type: 'increase_text_size', parameters: {'to': 'medium'}),
            ],
          ),
        ],
      );

  static ModeModel get neurodivergentFocus => ModeModel(
        id: 'neurodivergent',
        name: 'Neurodivergent Focus',
        description: 'Minimise distractions and sensory overload',
        icon: Icons.psychology,
        color: const Color(0xFFFF4D9F),
        category: 'cognitive',
        flows: [
          FlowDSL(
            trigger: 'mode.on:neurodivergent',
            actions: [
              FlowAction(type: 'reduce_animation', parameters: {}),
              FlowAction(type: 'mute_distraction_apps', parameters: {}),
              FlowAction(type: 'enable_dnd', parameters: {}),
              FlowAction(type: 'simplify_home_screen', parameters: {}),
            ],
          ),
          FlowDSL(
            trigger: 'mode.off:neurodivergent',
            actions: [
              FlowAction(type: 'set_volume', parameters: {'level': 50}),
            ],
          ),
        ],
      );

  static ModeModel get calmMode => ModeModel(
        id: 'calm',
        name: 'Calm Mode',
        description: 'Reduce anxiety and overstimulation',
        icon: Icons.self_improvement,
        color: const Color(0xFF4DFFB8),
        category: 'sensory',
        flows: [
          FlowDSL(
            trigger: 'mode.on:calm',
            actions: [
              FlowAction(type: 'enable_dnd', parameters: {}),
              FlowAction(type: 'lower_brightness', parameters: {'to': 30}),
              FlowAction(type: 'set_volume', parameters: {'level': 10}),
              FlowAction(type: 'reduce_animation', parameters: {}),
            ],
          ),
          FlowDSL(
            trigger: 'mode.off:calm',
            actions: [
              FlowAction(type: 'set_volume', parameters: {'level': 50}),
              FlowAction(type: 'set_brightness', parameters: {'to': 50}),
            ],
          ),
        ],
      );

  static ModeModel get hearingSupport => ModeModel(
        id: 'hearing',
        name: 'Hearing Support',
        description: 'Enable captions and visual notifications',
        icon: Icons.hearing,
        color: const Color(0xFFFFB84D),
        category: 'sensory',
        flows: [
          FlowDSL(
            trigger: 'mode.on:hearing',
            actions: [
              FlowAction(type: 'enable_captions', parameters: {}),
              FlowAction(type: 'flash_screen_alerts', parameters: {}),
              FlowAction(type: 'boost_haptic_feedback', parameters: {'strength': 'strong'}),
              FlowAction(type: 'enable_live_transcribe', parameters: {}),
            ],
          ),
          FlowDSL(
            trigger: 'mode.off:hearing',
            actions: [
              FlowAction(type: 'boost_haptic_feedback', parameters: {'strength': 'medium'}),
            ],
          ),
        ],
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
          'Set text size to large',
          'Enable high contrast display',
          'Boost screen brightness to maximum',
        ];
      case 'motor':
        return [
          'Reduce gesture sensitivity',
          'Open voice typing settings',
          'Increase touch target sizes',
        ];
      case 'neurodivergent':
        return [
          'Mute distraction apps',
          'Enable Do Not Disturb',
          'Reduce system animations',
          'Simplify home screen',
        ];
      case 'calm':
        return [
          'Enable Do Not Disturb',
          'Lower brightness to 30%',
          'Reduce volume to 10%',
          'Slow down animations',
        ];
      case 'hearing':
        return [
          'Enable system-wide captions',
          'Flash screen for notifications',
          'Boost haptic feedback to maximum',
          'Launch Live Transcribe app',
        ];
      case 'custom':
        return [
          'Tap to configure your own flows',
          'Combine any accessibility actions',
          'Create personalised automations',
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

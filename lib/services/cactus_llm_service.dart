import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import '../models/flow_dsl.dart';

/// Service for interacting with Cactus LLM for on-device inference
/// Upgraded to multi-step accessibility planner
class CactusLLMService {
  static final CactusLLMService _instance = CactusLLMService._internal();
  factory CactusLLMService() => _instance;
  CactusLLMService._internal();

  CactusLM? _llm;
  bool _isInitialised = false;
  bool _isLoading = false;

  /// System prompt for accessibility automation planner
  static const String systemPrompt = '''You are an accessibility automation planner for disabled users.

Input: Natural language request + user disability context + sensor data
Output: ONLY valid JSON DSL with multi-step accessibility flows

Schema:
{
  "trigger": "assistive_mode.on:MODE",
  "conditions": {
    "ambient_light": "low|medium|high",
    "noise_level": "quiet|moderate|loud",
    "device_motion": "still|walking|shaky",
    "recent_usage": ["app1", "app2"],
    "time_of_day": "morning|afternoon|evening|night"
  },
  "actions": [
    {"type": "ACTION_TYPE", "param": value}
  ]
}

Available Modes: vision, motor, neurodivergent, calm, hearing, custom, sleep, focus

Available Actions:
[Vision] increase_text_size, increase_contrast, enable_screen_reader, boost_brightness, reduce_animation
[Motor] reduce_gesture_sensitivity, enable_voice_typing, enable_one_handed_mode, increase_touch_targets
[Cognitive] reduce_animation, simplify_home_screen, mute_distraction_apps, highlight_focus_apps, enable_dnd
[Hearing] enable_live_transcribe, enable_captions, flash_screen_alerts, boost_haptic_feedback
[General] lower_brightness, set_volume, mute_apps, launch_app, clean_screenshots, clean_downloads, disable_wifi, disable_bluetooth

Rules:
1. Infer disability context from user request
2. Generate 2-5 related actions (multi-step plans)
3. Add conditions when sensory triggers are mentioned
4. Combine complementary actions (e.g., high contrast + large text for vision)
5. Output ONLY JSON, no explanations or thinking

Examples:

Input: "My eyes hurt, make everything easier to see"
Output: {"trigger":"assistive_mode.on:vision","conditions":{"ambient_light":"high"},"actions":[{"type":"increase_text_size","to":"max"},{"type":"increase_contrast"},{"type":"reduce_animation"},{"type":"boost_brightness","to":80}]}

Input: "I'm feeling anxious and overwhelmed"
Output: {"trigger":"assistive_mode.on:calm","actions":[{"type":"enable_dnd"},{"type":"lower_brightness","to":30},{"type":"set_volume","level":10},{"type":"reduce_animation"},{"type":"mute_distraction_apps"}]}

Input: "It's noisy and I can't hear notifications"
Output: {"trigger":"assistive_mode.on:hearing","conditions":{"noise_level":"loud"},"actions":[{"type":"enable_live_transcribe"},{"type":"flash_screen_alerts"},{"type":"boost_haptic_feedback","strength":"strong"},{"type":"enable_captions"}]}

NO explanations. NO thinking tags. ONLY JSON.''';

  /// Initialise the Qwen3 0.6B model
  Future<void> initialise() async {
    if (_isInitialised || _isLoading) return;

    // Require Android - no simulation mode
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'NothFlows requires Android for on-device AI. '
        'The Cactus LLM cannot run on this platform.',
      );
    }

    _isLoading = true;
    try {
      debugPrint('[CactusLLM] Initialising Qwen3 0.6B model...');

      _llm = CactusLM();

      // Download model if not already cached
      debugPrint('[CactusLLM] Downloading model (if needed)...');
      await _llm!.downloadModel(model: 'qwen3-0.6');

      // Initialise the model
      debugPrint('[CactusLLM] Loading model into memory...');
      await _llm!.initializeModel();

      _isInitialised = true;
      debugPrint('[CactusLLM] Model loaded successfully');
    } catch (e) {
      debugPrint('[CactusLLM] CRITICAL: Failed to initialise model: $e');
      _isInitialised = false;
      rethrow; // Don't fall back, fail hard
    } finally {
      _isLoading = false;
    }
  }

  /// Check if model is ready
  bool get isReady => _isInitialised;

  /// Check if model is currently loading
  bool get isLoading => _isLoading;

  /// Generate multi-step accessibility plan with context reasoning
  Future<FlowDSL?> generatePlan({
    required String userRequest,
    String? userContext, // "I have low vision", "I have hand tremors"
    Map<String, dynamic>? sensorData,
    List<FlowDSL>? existingFlows,
  }) async {
    if (!isReady) await initialise();

    if (_llm == null) {
      throw Exception('Cactus LLM is required. Model not loaded.');
    }

    try {
      // Build context-aware prompt
      final contextInfo = StringBuffer();
      if (userContext != null) {
        contextInfo.writeln('User context: $userContext');
      }
      if (sensorData != null && sensorData.isNotEmpty) {
        contextInfo.writeln('Sensor data: ${jsonEncode(sensorData)}');
      }
      if (existingFlows != null && existingFlows.isNotEmpty) {
        contextInfo.writeln('Existing flows: ${existingFlows.length}');
      }

      final messages = [
        ChatMessage(role: 'system', content: systemPrompt),
        ChatMessage(
          role: 'user',
          content: '''${contextInfo.toString()}
Request: $userRequest

Generate accessibility automation JSON:''',
        ),
      ];

      debugPrint('[CactusLLM] Generating plan for: $userRequest');
      final result = await _llm!.generateCompletion(messages: messages);

      if (!result.success) {
        throw Exception('LLM generation failed: ${result.response}');
      }

      debugPrint('[CactusLLM] Raw response: ${result.response}');
      debugPrint('[CactusLLM] Tokens/sec: ${result.tokensPerSecond}');

      // Extract and clean JSON
      String jsonText = result.response.trim();
      jsonText = jsonText.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
      jsonText = jsonText.replaceAll(RegExp(r'<\|.*?\|>'), '');
      jsonText = jsonText.trim();

      final startIdx = jsonText.indexOf('{');
      final endIdx = jsonText.lastIndexOf('}');

      if (startIdx == -1 || endIdx == -1) {
        throw Exception('No valid JSON found in response');
      }

      jsonText = jsonText.substring(startIdx, endIdx + 1);
      jsonText = _sanitizeJson(jsonText);

      debugPrint('[CactusLLM] Sanitized JSON: $jsonText');

      final dsl = FlowDSL.fromJsonString(jsonText);

      if (!dsl.isValid()) {
        throw Exception('Generated invalid DSL');
      }

      debugPrint('[CactusLLM] Generated plan: ${dsl.trigger} with ${dsl.actions.length} actions');
      return dsl;
    } catch (e) {
      debugPrint('[CactusLLM] Error generating plan: $e');
      throw Exception('Failed to generate accessibility plan: $e');
    }
  }

  /// Infer disability category from user request
  String inferDisabilityContext(String request) {
    final lower = request.toLowerCase();

    if (lower.contains('see') ||
        lower.contains('eyes') ||
        lower.contains('vision') ||
        lower.contains('read') ||
        lower.contains('bright') ||
        lower.contains('blind') ||
        lower.contains('blurry')) {
      return 'vision';
    }
    if (lower.contains('hear') ||
        lower.contains('sound') ||
        lower.contains('loud') ||
        lower.contains('notification') ||
        lower.contains('deaf') ||
        lower.contains('noise')) {
      return 'hearing';
    }
    if (lower.contains('tap') ||
        lower.contains('hand') ||
        lower.contains('finger') ||
        lower.contains('gesture') ||
        lower.contains('tremor') ||
        lower.contains('shake') ||
        lower.contains('motor')) {
      return 'motor';
    }
    if (lower.contains('anxiety') ||
        lower.contains('overwhelm') ||
        lower.contains('calm') ||
        lower.contains('stress') ||
        lower.contains('distract') ||
        lower.contains('panic')) {
      return 'calm';
    }
    if (lower.contains('focus') ||
        lower.contains('adhd') ||
        lower.contains('autism') ||
        lower.contains('concentrate') ||
        lower.contains('attention')) {
      return 'neurodivergent';
    }
    if (lower.contains('sleep') ||
        lower.contains('night') ||
        lower.contains('bed') ||
        lower.contains('rest')) {
      return 'sleep';
    }

    return 'custom';
  }

  /// Parse natural language instruction into FlowDSL
  /// Now uses generatePlan internally for multi-step planning
  Future<FlowDSL?> parseInstruction({
    required String instruction,
    required String mode,
  }) async {
    // Infer context from instruction
    final inferredContext = inferDisabilityContext(instruction);

    // Use generatePlan method for multi-step planning
    return await generatePlan(
      userRequest: instruction,
      userContext: 'Mode: $mode, Inferred: $inferredContext',
    );
  }

  /// Merge multiple flows intelligently (deduplicate, combine)
  FlowDSL? mergeFlows(List<FlowDSL> flows) {
    if (flows.isEmpty) return null;
    if (flows.length == 1) return flows.first;

    // Combine all actions, removing duplicates
    final allActions = <FlowAction>[];
    final seenTypes = <String>{};

    for (final flow in flows) {
      for (final action in flow.actions) {
        if (!seenTypes.contains(action.type)) {
          allActions.add(action);
          seenTypes.add(action.type);
        }
      }
    }

    // Use first flow's trigger and conditions
    return FlowDSL(
      trigger: flows.first.trigger,
      conditions: flows.first.conditions,
      actions: allActions,
    );
  }

  /// Batch parse multiple instructions
  Future<List<FlowDSL>> parseBatch({
    required List<String> instructions,
    required String mode,
  }) async {
    final results = <FlowDSL>[];

    for (final instruction in instructions) {
      try {
        final dsl = await parseInstruction(
          instruction: instruction,
          mode: mode,
        );
        if (dsl != null) {
          results.add(dsl);
        }
      } catch (e) {
        debugPrint('[CactusLLM] Error parsing instruction "$instruction": $e');
      }
    }

    return results;
  }

  /// Get model information
  Future<Map<String, dynamic>> getModelInfo() async {
    if (!isReady) {
      return {'status': 'not_initialised'};
    }

    if (_llm == null) {
      return {'status': 'error', 'message': 'Model not loaded'};
    }

    return {
      'status': 'ready',
      'model_name': 'qwen3-0.6',
      'local_only': true,
      'size': '~400MB',
      'supports_accessibility': true,
      'multi_step_planning': true,
    };
  }

  /// Warm up the model with a test inference
  Future<void> warmUp() async {
    if (!isReady) {
      await initialise();
    }

    debugPrint('[CactusLLM] Warming up model...');
    try {
      await generatePlan(
        userRequest: 'test accessibility setup',
        userContext: 'warmup',
      );
      debugPrint('[CactusLLM] Warm-up complete');
    } catch (e) {
      debugPrint('[CactusLLM] Warm-up failed (non-critical): $e');
    }
  }

  /// Sanitize JSON output from LLM to fix common formatting issues
  String _sanitizeJson(String json) {
    // Fix incorrectly escaped quotes
    json = json.replaceAll(RegExp(r'@([a-zA-Z_][a-zA-Z0-9_]*)\\"'), r'$1"');

    // Fix common hallucinations where LLM uses "param" instead of proper parameter names
    json = json.replaceAll(RegExp(r'"param"\s*:\s*\[\s*(\d+)\s*\]'), r'"to": $1');

    // Fix unquoted property names
    json = json.replaceAllMapped(
      RegExp(r'([\[{,]\s*)([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*', multiLine: true),
      (match) => '${match.group(1)}"${match.group(2)}": ',
    );

    // Fix single quotes to double quotes for strings
    json = json.replaceAll("'", '"');

    // Remove any trailing commas before closing braces/brackets
    json = json.replaceAll(RegExp(r',\s*([}\]])'), r'$1');

    // Remove any comments
    json = json.replaceAll(RegExp(r'//.*?$', multiLine: true), '');
    json = json.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

    return json.trim();
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_llm != null) {
      _llm!.unload();
      _llm = null;
    }
    _isInitialised = false;
    debugPrint('[CactusLLM] Resources disposed');
  }
}

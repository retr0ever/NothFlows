import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import '../models/flow_dsl.dart';

/// Service for interacting with Cactus LLM for on-device inference
class CactusLLMService {
  static final CactusLLMService _instance = CactusLLMService._internal();
  factory CactusLLMService() => _instance;
  CactusLLMService._internal();

  CactusLM? _llm;
  bool _isInitialised = false;
  bool _isLoading = false;

  /// System prompt that enforces DSL output format
  static const String systemPrompt = '''Convert accessibility instructions to JSON DSL. Output ONLY the JSON, nothing else.

Schema: {"trigger": "mode.on:MODE", "actions": [{"type": "TYPE", "param": value}]}

Modes: vision, motor, neurodivergent, calm, hearing, custom, sleep, focus

Actions by Category:

VISION (5):
- increase_text_size: to (small/medium/large/max)
- increase_contrast: (no params)
- enable_high_visibility: (no params)
- enable_screen_reader: (no params)
- boost_brightness: to (0-100)

MOTOR (4):
- reduce_gesture_sensitivity: (no params)
- enable_voice_typing: (no params)
- enable_one_handed_mode: (no params)
- increase_touch_targets: (no params)

COGNITIVE/NEURODIVERGENT (4):
- reduce_animation: (no params)
- simplify_home_screen: (no params)
- mute_distraction_apps: (no params)
- highlight_focus_apps: (no params)

HEARING (4):
- enable_live_transcribe: (no params)
- enable_captions: (no params)
- flash_screen_alerts: (no params)
- boost_haptic_feedback: strength (light/medium/strong)

SYSTEM (11):
- lower_brightness: to (0-100)
- set_volume: level (0-100)
- enable_dnd: (no params)
- disable_wifi: (no params)
- disable_bluetooth: (no params)
- clean_screenshots: older_than_days (number)
- clean_downloads: older_than_days (number)
- mute_apps: apps (array of strings)
- launch_app: app (string)
- launch_care_app: (no params)

Examples:
Input: "Make text large and boost brightness"
Output: {"trigger": "mode.on:vision", "actions": [{"type": "increase_text_size", "to": "large"}, {"type": "boost_brightness", "to": 100}]}

Input: "Enable voice typing and reduce sensitivity"
Output: {"trigger": "mode.on:motor", "actions": [{"type": "enable_voice_typing"}, {"type": "reduce_gesture_sensitivity"}]}

Input: "Mute Instagram and TikTok, reduce animations"
Output: {"trigger": "mode.on:neurodivergent", "actions": [{"type": "mute_apps", "apps": ["Instagram", "TikTok"]}, {"type": "reduce_animation"}]}

NO explanations. NO thinking. NO markdown. ONLY JSON.''';

  /// Initialise the Qwen3 0.6B model
  Future<void> initialise() async {
    if (_isInitialised || _isLoading) return;

    // Simulation mode for non-Android platforms
    if (!Platform.isAndroid) {
      debugPrint('[CactusLLM] Non-Android platform detected. Starting in SIMULATION mode.');
      _isInitialised = true;
      return;
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
      debugPrint('[CactusLLM] Failed to initialise model: $e');
      // Fallback to simulation if model fails to load
      if (kDebugMode) {
        debugPrint('[CactusLLM] Falling back to simulation mode due to error.');
        _isInitialised = true;
      } else {
        rethrow;
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Check if model is ready
  bool get isReady => _isInitialised;

  /// Parse natural language instruction into FlowDSL
  Future<FlowDSL?> parseInstruction({
    required String instruction,
    required String mode,
  }) async {
    // Always try to initialize if not ready
    if (!isReady) {
      try {
        await initialise();
      } catch (e) {
        debugPrint('[CactusLLM] Initialization failed, using simulation mode: $e');
      }
    }

    // Use simulation parser if no LLM instance (Desktop or fallback)
    if (_llm == null) {
      debugPrint('[CactusLLM] Using simulation mode (no LLM instance)');
      return _simulateParse(instruction, mode);
    }

    try {
      debugPrint('[CactusLLM] Parsing instruction with real LLM: $instruction');

      // Build the messages
      final messages = [
        ChatMessage(role: 'system', content: systemPrompt),
        ChatMessage(role: 'user', content: '''Mode: $mode
Instruction: $instruction

Generate the DSL JSON:'''),
      ];

      // Run inference
      final result = await _llm!.generateCompletion(messages: messages);

      if (!result.success) {
        debugPrint('[CactusLLM] Inference failed: ${result.response}');
        return null;
      }

      debugPrint('[CactusLLM] Raw response: ${result.response}');

      // Extract and clean JSON from response
      String jsonText = result.response.trim();

      // First, remove think tags and their content
      jsonText = jsonText.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');

      // Remove trailing tokens like <|im_end|>
      jsonText = jsonText.replaceAll(RegExp(r'<\|.*?\|>'), '');

      // Trim again after removing tags
      jsonText = jsonText.trim();

      // Find JSON boundaries - look for the outermost braces
      final startIdx = jsonText.indexOf('{');
      final endIdx = jsonText.lastIndexOf('}');

      if (startIdx == -1 || endIdx == -1) {
        debugPrint('[CactusLLM] No valid JSON found in response');
        return null;
      }

      jsonText = jsonText.substring(startIdx, endIdx + 1);

      // Sanitize JSON - fix common LLM mistakes
      jsonText = _sanitizeJson(jsonText);
      debugPrint('[CactusLLM] Sanitized JSON: $jsonText');

      // Parse the DSL
      final dsl = FlowDSL.fromJsonString(jsonText);

      // Validate
      if (!dsl.isValid()) {
        debugPrint('[CactusLLM] Generated invalid DSL');
        return null;
      }

      debugPrint('[CactusLLM] Successfully parsed DSL: ${dsl.trigger}');
      return dsl;
    } catch (e) {
      debugPrint('[CactusLLM] Error parsing with LLM: $e, falling back to simulation');
      // Fall back to simulation mode if LLM parsing fails
      return _simulateParse(instruction, mode);
    }
  }

  /// Simple keyword-based parser for simulation mode
  Future<FlowDSL?> _simulateParse(String instruction, String mode) async {
    debugPrint('[CactusLLM] Simulating parse for: $instruction');
    // await Future.delayed(const Duration(milliseconds: 300)); // Simulate latency

    final lower = instruction.toLowerCase();
    final actions = <Map<String, dynamic>>[];

    // Extract numbers from instruction
    final numberMatch = RegExp(r'(\d+)').firstMatch(instruction);
    final extractedNumber = numberMatch != null ? int.parse(numberMatch.group(1)!) : null;

    // VISION ACTIONS
    if (lower.contains('text size') || lower.contains('text large') || lower.contains('text huge')) {
      final size = lower.contains('huge') || lower.contains('max') ? 'max' : 'large';
      actions.add({'type': 'increase_text_size', 'to': size});
    }
    if (lower.contains('contrast')) {
      actions.add({'type': 'increase_contrast'});
    }
    if (lower.contains('visibility') || lower.contains('high visibility')) {
      actions.add({'type': 'enable_high_visibility'});
    }
    if (lower.contains('screen reader') || lower.contains('talkback')) {
      actions.add({'type': 'enable_screen_reader'});
    }
    if (lower.contains('boost brightness') || lower.contains('increase brightness')) {
      final level = extractedNumber ?? 100;
      actions.add({'type': 'boost_brightness', 'to': level});
    }

    // MOTOR ACTIONS
    if (lower.contains('gesture') || lower.contains('sensitivity')) {
      actions.add({'type': 'reduce_gesture_sensitivity'});
    }
    if (lower.contains('voice typing') || lower.contains('voice input')) {
      actions.add({'type': 'enable_voice_typing'});
    }
    if (lower.contains('one hand') || lower.contains('one-handed')) {
      actions.add({'type': 'enable_one_handed_mode'});
    }
    if (lower.contains('touch target') || lower.contains('bigger buttons')) {
      actions.add({'type': 'increase_touch_targets'});
    }

    // COGNITIVE/NEURODIVERGENT ACTIONS
    if (lower.contains('animation') || lower.contains('reduce motion')) {
      actions.add({'type': 'reduce_animation'});
    }
    if (lower.contains('simplify') || lower.contains('home screen')) {
      actions.add({'type': 'simplify_home_screen'});
    }
    if (lower.contains('distraction') || (lower.contains('mute') && lower.contains('app'))) {
      actions.add({'type': 'mute_distraction_apps'});
    }
    if (lower.contains('focus app') || lower.contains('highlight')) {
      actions.add({'type': 'highlight_focus_apps'});
    }

    // HEARING ACTIONS
    if (lower.contains('transcribe') || lower.contains('live transcribe')) {
      actions.add({'type': 'enable_live_transcribe'});
    }
    if (lower.contains('caption')) {
      actions.add({'type': 'enable_captions'});
    }
    if (lower.contains('flash') || lower.contains('screen alert')) {
      actions.add({'type': 'flash_screen_alerts'});
    }
    if (lower.contains('haptic') || lower.contains('vibrat')) {
      final strength = lower.contains('strong') ? 'strong' : 'medium';
      actions.add({'type': 'boost_haptic_feedback', 'strength': strength});
    }

    // SYSTEM ACTIONS
    if (lower.contains('screenshot')) {
      final days = extractedNumber ?? 30;
      actions.add({'type': 'clean_screenshots', 'older_than_days': days});
    }
    if (lower.contains('download')) {
      final days = extractedNumber ?? 30;
      actions.add({'type': 'clean_downloads', 'older_than_days': days});
    }
    if (lower.contains('mute') && !lower.contains('distraction') && !lower.contains('app')) {
      actions.add({'type': 'mute_apps', 'apps': ['Instagram', 'TikTok']});
    }
    if (lower.contains('lower brightness') || (lower.contains('brightness') && !lower.contains('boost'))) {
      final level = extractedNumber ?? 20;
      actions.add({'type': 'lower_brightness', 'to': level});
    }
    if (lower.contains('volume')) {
      final level = extractedNumber ?? 30;
      actions.add({'type': 'set_volume', 'level': level});
    }
    if (lower.contains('dnd') || lower.contains('disturb') || lower.contains('do not disturb')) {
      actions.add({'type': 'enable_dnd'});
    }
    if (lower.contains('wifi')) {
      actions.add({'type': 'disable_wifi'});
    }
    if (lower.contains('bluetooth')) {
      actions.add({'type': 'disable_bluetooth'});
    }
    if (lower.contains('care app') || lower.contains('emergency')) {
      actions.add({'type': 'launch_care_app'});
    }
    if (lower.contains('launch') || lower.contains('open')) {
      final parts = lower.split(' ');
      String app = 'App';
      if (parts.length > 1) {
        app = parts.last;
      }
      actions.add({'type': 'launch_app', 'app': app});
    }

    // Default to mode-appropriate action if nothing matched
    if (actions.isEmpty) {
      switch (mode) {
        case 'vision':
          actions.add({'type': 'increase_text_size', 'to': 'large'});
          break;
        case 'motor':
          actions.add({'type': 'enable_voice_typing'});
          break;
        case 'hearing':
          actions.add({'type': 'enable_captions'});
          break;
        case 'calm':
          actions.add({'type': 'enable_dnd'});
          break;
        case 'neurodivergent':
          actions.add({'type': 'reduce_animation'});
          break;
        default:
          actions.add({'type': 'clean_screenshots', 'older_than_days': 7});
      }
    }

    final jsonMap = {
      'trigger': 'mode.on:$mode',
      'actions': actions,
    };

    return FlowDSL.fromJson(jsonMap);
  }

  /// Batch parse multiple instructions
  Future<List<FlowDSL>> parseBatch({
    required List<String> instructions,
    required String mode,
  }) async {
    final results = <FlowDSL>[];

    for (final instruction in instructions) {
      final dsl = await parseInstruction(
        instruction: instruction,
        mode: mode,
      );
      if (dsl != null) {
        results.add(dsl);
      }
    }

    return results;
  }

  /// Infer accessibility category from check-in text
  /// Returns one of: VISION, MOTOR, HEARING, CALM, NEURODIVERGENT, CUSTOM
  Future<String> inferCategoryFromCheckin(String checkinText) async {
    final lower = checkinText.toLowerCase();

    // Vision-related keywords
    if (lower.contains('see') ||
        lower.contains('eyes') ||
        lower.contains('vision') ||
        lower.contains('read') ||
        lower.contains('text') ||
        lower.contains('screen') ||
        lower.contains('bright') ||
        lower.contains('contrast') ||
        lower.contains('blur')) {
      return 'VISION';
    }

    // Motor-related keywords
    if (lower.contains('hand') ||
        lower.contains('tremor') ||
        lower.contains('shake') ||
        lower.contains('shaking') ||
        lower.contains('tap') ||
        lower.contains('touch') ||
        lower.contains('gesture') ||
        lower.contains('motor') ||
        lower.contains('finger') ||
        lower.contains('arthritis') ||
        lower.contains('coordination')) {
      return 'MOTOR';
    }

    // Hearing-related keywords
    if (lower.contains('hear') ||
        lower.contains('sound') ||
        lower.contains('loud') ||
        lower.contains('audio') ||
        lower.contains('noise') ||
        lower.contains('deaf') ||
        lower.contains('caption') ||
        lower.contains('listening')) {
      return 'HEARING';
    }

    // Calm/anxiety keywords
    if (lower.contains('anxious') ||
        lower.contains('anxiety') ||
        lower.contains('overwhelm') ||
        lower.contains('stress') ||
        lower.contains('calm') ||
        lower.contains('relax') ||
        lower.contains('panic') ||
        lower.contains('worry') ||
        lower.contains('tense')) {
      return 'CALM';
    }

    // Neurodivergent/focus keywords
    if (lower.contains('focus') ||
        lower.contains('adhd') ||
        lower.contains('distract') ||
        lower.contains('attention') ||
        lower.contains('concentrate') ||
        lower.contains('autism') ||
        lower.contains('overstimulat') ||
        lower.contains('sensory')) {
      return 'NEURODIVERGENT';
    }

    // Default to custom
    return 'CUSTOM';
  }

  /// Get model information
  Future<Map<String, dynamic>> getModelInfo() async {
    if (!isReady) {
      return {'status': 'not_initialised'};
    }

    if (_llm == null) {
      return {
        'status': 'ready (simulated)',
        'model_name': 'Simulation Mode',
        'local_only': true,
        'size': '0MB',
      };
    }

    return {
      'status': 'ready',
      'model_name': 'Qwen3 0.6B (Q4_0)',
      'local_only': true,
      'size': '~500MB',
      'context_length': 2048,
      'threads': 4,
    };
  }

  /// Warm up the model with a test inference
  Future<void> warmUp() async {
    if (!isReady) {
      await initialise();
    }

    debugPrint('[CactusLLM] Warming up model...');
    await parseInstruction(
      instruction: 'Clean screenshots',
      mode: 'custom',
    );
    debugPrint('[CactusLLM] Warm-up complete');
  }

  /// Sanitize JSON output from LLM to fix common formatting issues
  String _sanitizeJson(String json) {
    // Fix incorrectly escaped quotes (e.g., "@param\" -> "param")
    json = json.replaceAll(RegExp(r'@([a-zA-Z_][a-zA-Z0-9_]*)\\"'), r'$1"');

    // Fix common hallucinations where LLM uses "param" instead of proper parameter names
    // For lower_brightness, the parameter should be "to", not "param"
    json = json.replaceAll(RegExp(r'"param"\s*:\s*\[\s*(\d+)\s*\]'), r'"to": $1');

    // Fix unquoted property names (e.g., to: 50 -> "to": 50)
    // Only match at start of line or after comma/brace, to avoid matching colons in string values
    json = json.replaceAllMapped(
      RegExp(r'([\[{,]\s*)([a-zA-Z_][a-zA-Z0-9_]*)\s*:\s*', multiLine: true),
      (match) => '${match.group(1)}"${match.group(2)}": ',
    );

    // Fix single quotes to double quotes for strings
    json = json.replaceAll("'", '"');

    // Remove any trailing commas before closing braces/brackets
    json = json.replaceAll(RegExp(r',\s*([}\]])'), r'$1');

    // Remove any comments (// or /* */)
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
  }
}

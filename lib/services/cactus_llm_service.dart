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
  static const String systemPrompt = '''Convert to JSON. Output ONLY the JSON, nothing else.

Schema: {"trigger": "mode.on:MODE", "actions": [{"type": "TYPE", "param": value}]}

Actions:
- clean_screenshots: older_than_days
- clean_downloads: older_than_days
- mute_apps: apps
- lower_brightness: to
- set_volume: level
- enable_dnd: (no params)
- disable_wifi: (no params)
- disable_bluetooth: (no params)
- set_wallpaper: path
- launch_app: app

Example: "lower brightness to 20"
Output: {"trigger": "mode.on:custom", "actions": [{"type": "lower_brightness", "to": 20}]}

NO explanations. NO thinking. ONLY JSON.''';

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

    // Heuristic matching for common actions
    if (lower.contains('screenshot')) {
      final days = extractedNumber ?? 30;
      actions.add({'type': 'clean_screenshots', 'older_than_days': days});
    }
    if (lower.contains('download')) {
      final days = extractedNumber ?? 30;
      actions.add({'type': 'clean_downloads', 'older_than_days': days});
    }
    if (lower.contains('mute')) {
      actions.add({'type': 'mute_apps', 'apps': ['Instagram', 'TikTok']});
    }
    if (lower.contains('brightness')) {
      final level = extractedNumber ?? 20;
      actions.add({'type': 'lower_brightness', 'to': level});
    }
    if (lower.contains('volume')) {
      final level = extractedNumber ?? 30;
      actions.add({'type': 'set_volume', 'level': level});
    }
    if (lower.contains('dnd') || lower.contains('disturb')) {
      actions.add({'type': 'enable_dnd'});
    }
    if (lower.contains('wifi')) {
      actions.add({'type': 'disable_wifi'});
    }
    if (lower.contains('bluetooth')) {
      actions.add({'type': 'disable_bluetooth'});
    }
    if (lower.contains('wallpaper')) {
      actions.add({'type': 'set_wallpaper', 'path': 'assets/wallpapers/minimal.jpg'});
    }
    if (lower.contains('launch') || lower.contains('open')) {
      // Extract potential app name
      final parts = lower.split(' ');
      String app = 'App';
      if (parts.length > 1) {
        app = parts.last;
      }
      actions.add({'type': 'launch_app', 'app': app});
    }

    // Default to mock action if nothing matched
    if (actions.isEmpty) {
       actions.add({'type': 'clean_screenshots', 'older_than_days': 7});
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
      'model_name': 'qwen3-0.6',
      'local_only': true,
      'size': '~400MB',
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

  /// Infer disability context from natural language request
  /// Returns one of: 'vision' | 'hearing' | 'motor' | 'calm' | 'neurodivergent' | 'custom'
  String inferDisabilityContext(String request) {
    final lower = request.toLowerCase();

    // Vision-related keywords
    if (lower.contains('see') ||
        lower.contains('eyes') ||
        lower.contains('vision') ||
        lower.contains('read') ||
        lower.contains('text') ||
        lower.contains('screen') ||
        lower.contains('bright') ||
        lower.contains('contrast')) {
      return 'vision';
    }

    // Hearing-related keywords
    if (lower.contains('hear') ||
        lower.contains('sound') ||
        lower.contains('loud') ||
        lower.contains('audio') ||
        lower.contains('noise') ||
        lower.contains('deaf') ||
        lower.contains('caption')) {
      return 'hearing';
    }

    // Motor-related keywords
    if (lower.contains('tap') ||
        lower.contains('hand') ||
        lower.contains('tremor') ||
        lower.contains('touch') ||
        lower.contains('gesture') ||
        lower.contains('motor') ||
        lower.contains('finger') ||
        lower.contains('click')) {
      return 'motor';
    }

    // Calm/anxiety keywords
    if (lower.contains('anxious') ||
        lower.contains('overwhelm') ||
        lower.contains('stress') ||
        lower.contains('calm') ||
        lower.contains('relax') ||
        lower.contains('panic')) {
      return 'calm';
    }

    // Neurodivergent/focus keywords
    if (lower.contains('focus') ||
        lower.contains('adhd') ||
        lower.contains('distract') ||
        lower.contains('attention') ||
        lower.contains('concentrate')) {
      return 'neurodivergent';
    }

    // Default to custom if no keywords match
    return 'custom';
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

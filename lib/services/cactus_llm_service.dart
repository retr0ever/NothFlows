import 'dart:async';
import 'dart:convert';
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
  static const String systemPrompt = '''You are a JSON DSL generator for mobile automation.
Your ONLY job is to convert natural language instructions into valid JSON.

DSL Schema:
{
  "trigger": "mode.on:<mode_name>",
  "actions": [
    { "type": "<action_type>", "<param>": <value> }
  ]
}

Valid modes: sleep, focus, custom
Valid action types and their parameters:
- clean_screenshots: older_than_days (number)
- clean_downloads: older_than_days (number)
- mute_apps: apps (array of strings)
- lower_brightness: to (number 0-100)
- set_volume: level (number 0-100)
- enable_dnd: (no params)
- disable_wifi: (no params)
- disable_bluetooth: (no params)
- set_wallpaper: path (string)
- launch_app: app (string)

CRITICAL RULES:
1. Output ONLY valid JSON, no explanations
2. Always include "trigger" and "actions"
3. Use only the action types listed above
4. Return empty actions array if unclear: {"trigger": "mode.on:custom", "actions": []}

Example input: "When sleep mode is on, clean old screenshots and lower brightness to 20"
Example output:
{
  "trigger": "mode.on:sleep",
  "actions": [
    { "type": "clean_screenshots", "older_than_days": 30 },
    { "type": "lower_brightness", "to": 20 }
  ]
}''';

  /// Initialise the Qwen3 0.6B model
  Future<void> initialise() async {
    if (_isInitialised || _isLoading) return;

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
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Check if model is ready
  bool get isReady => _isInitialised && _llm != null;

  /// Parse natural language instruction into FlowDSL
  Future<FlowDSL?> parseInstruction({
    required String instruction,
    required String mode,
  }) async {
    if (!isReady) {
      await initialise();
    }

    try {
      debugPrint('[CactusLLM] Parsing instruction: $instruction');

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

      // Find JSON boundaries
      final startIdx = jsonText.indexOf('{');
      final endIdx = jsonText.lastIndexOf('}');

      if (startIdx == -1 || endIdx == -1) {
        debugPrint('[CactusLLM] No valid JSON found in response');
        return null;
      }

      jsonText = jsonText.substring(startIdx, endIdx + 1);

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
      debugPrint('[CactusLLM] Error parsing instruction: $e');
      return null;
    }
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

  /// Dispose resources
  Future<void> dispose() async {
    if (_llm != null) {
      _llm!.unload();
      _llm = null;
      _isInitialised = false;
    }
  }
}

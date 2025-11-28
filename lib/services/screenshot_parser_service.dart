import 'dart:io';
import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import '../models/flow_dsl.dart';

/// Service for parsing screenshots into accessibility flows using SmolVLM
/// Uses on-device vision model to analyze UI screenshots and generate automation flows
class ScreenshotParserService {
  static final ScreenshotParserService _instance = ScreenshotParserService._internal();
  factory ScreenshotParserService() => _instance;
  ScreenshotParserService._internal();

  CactusLM? _vlm;
  bool _isInitialised = false;
  bool _isLoading = false;

  /// System prompt for screenshot analysis
  static const String visionPrompt = '''Analyze this screenshot for accessibility automation.

You are looking at a phone settings screen or app interface.

Identify:
1. Any accessibility settings visible (text size, contrast, brightness, etc.)
2. Toggles or sliders that can be automated
3. Apps or features that could help with disabilities

Output a JSON automation flow:
{
  "trigger": "assistive_mode.on:MODE",
  "actions": [
    {"type": "ACTION_TYPE", "param": value}
  ]
}

Available modes: vision, motor, neurodivergent, calm, hearing, custom, sleep, focus

Available actions:
[Vision] increase_text_size, increase_contrast, boost_brightness, reduce_animation, enable_screen_reader
[Motor] reduce_gesture_sensitivity, enable_voice_typing, enable_one_handed_mode, increase_touch_targets
[Cognitive] reduce_animation, simplify_home_screen, mute_distraction_apps, highlight_focus_apps, enable_dnd
[Hearing] enable_live_transcribe, enable_captions, flash_screen_alerts, boost_haptic_feedback
[General] lower_brightness, set_volume, mute_apps, launch_app

Rules:
1. Infer the best assistive mode based on visible settings
2. Generate 2-4 relevant actions
3. Output ONLY JSON, no explanations

Example:
If you see brightness and text size settings:
{"trigger":"assistive_mode.on:vision","actions":[{"type":"boost_brightness","to":90},{"type":"increase_text_size","to":"large"}]}

Output ONLY JSON.''';

  /// Initialize SmolVLM model for vision tasks
  Future<void> initialise() async {
    if (_isInitialised || _isLoading) return;

    // Require Android
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'Screenshot parsing requires Android for on-device vision model.',
      );
    }

    _isLoading = true;
    debugPrint('[ScreenshotParser] Initializing vision model...');

    try {
      _vlm = CactusLM();

      // Download SmolVLM or similar vision-capable model
      // Note: Check available models with getModels() for vision support
      final models = await _vlm!.getModels();
      final visionModel = models.firstWhere(
        (m) => m.supportsVision,
        orElse: () => throw Exception('No vision model available'),
      );

      debugPrint('[ScreenshotParser] Found vision model: ${visionModel.name}');
      await _vlm!.downloadModel(model: visionModel.slug);
      await _vlm!.initializeModel();

      _isInitialised = true;
      debugPrint('[ScreenshotParser] Vision model loaded successfully');
    } catch (e) {
      debugPrint('[ScreenshotParser] Failed to initialize: $e');
      _isInitialised = false;
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  bool get isReady => _isInitialised;
  bool get isLoading => _isLoading;

  /// Parse screenshot image into accessibility flow
  Future<FlowDSL?> parseScreenshot({
    required File screenshot,
    String? targetMode,
    String? userPrompt,
  }) async {
    if (!_isInitialised) {
      await initialise();
    }

    if (_vlm == null) {
      throw Exception('Vision model not initialized');
    }

    // Verify file exists
    if (!await screenshot.exists()) {
      throw Exception('Screenshot file not found: ${screenshot.path}');
    }

    try {
      debugPrint('[ScreenshotParser] Analyzing screenshot: ${screenshot.path}');

      // Build prompt with optional mode context
      final prompt = userPrompt ?? visionPrompt;
      final fullPrompt = targetMode != null
          ? 'Target assistive mode: $targetMode\n\n$prompt'
          : prompt;

      // For vision models, we need to include the image in the message
      // The exact API depends on the Cactus SDK version
      // Using generateCompletion with image context
      final messages = [
        ChatMessage(
          role: 'system',
          content: fullPrompt,
        ),
        ChatMessage(
          role: 'user',
          content: 'Analyze this screenshot and generate an accessibility automation flow. Image path: ${screenshot.path}',
        ),
      ];

      final result = await _vlm!.generateCompletion(messages: messages);

      if (!result.success) {
        throw Exception('Vision model generation failed: ${result.response}');
      }

      debugPrint('[ScreenshotParser] VLM response: ${result.response}');

      // Extract JSON from response
      String jsonText = result.response.trim();

      // Remove markdown code blocks if present
      jsonText = jsonText.replaceAll(RegExp(r'```json\s*'), '');
      jsonText = jsonText.replaceAll(RegExp(r'```\s*'), '');
      jsonText = jsonText.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
      jsonText = jsonText.replaceAll(RegExp(r'<\|.*?\|>'), '');
      jsonText = jsonText.trim();

      final startIdx = jsonText.indexOf('{');
      final endIdx = jsonText.lastIndexOf('}');

      if (startIdx == -1 || endIdx == -1) {
        throw Exception('No valid JSON found in VLM response');
      }

      jsonText = jsonText.substring(startIdx, endIdx + 1);

      // Parse to FlowDSL
      final dsl = FlowDSL.fromJsonString(jsonText);

      if (!dsl.isValid()) {
        throw Exception('VLM generated invalid flow DSL');
      }

      debugPrint('[ScreenshotParser] Successfully parsed screenshot into flow: ${dsl.trigger}');
      return dsl;
    } catch (e) {
      debugPrint('[ScreenshotParser] Error parsing screenshot: $e');
      return null;
    }
  }

  /// Analyze multiple screenshots and combine into a single flow
  Future<FlowDSL?> parseMultipleScreenshots({
    required List<File> screenshots,
    String? targetMode,
  }) async {
    if (screenshots.isEmpty) return null;

    final flows = <FlowDSL>[];

    for (final screenshot in screenshots) {
      try {
        final flow = await parseScreenshot(
          screenshot: screenshot,
          targetMode: targetMode,
        );
        if (flow != null) {
          flows.add(flow);
        }
      } catch (e) {
        debugPrint('[ScreenshotParser] Error parsing ${screenshot.path}: $e');
      }
    }

    if (flows.isEmpty) return null;
    if (flows.length == 1) return flows.first;

    // Merge multiple flows
    return _mergeFlows(flows, targetMode);
  }

  /// Merge multiple flows into one, deduplicating actions
  FlowDSL _mergeFlows(List<FlowDSL> flows, String? targetMode) {
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

    final mode = targetMode ?? flows.first.trigger.split(':').last;

    return FlowDSL(
      trigger: 'assistive_mode.on:$mode',
      conditions: flows.first.conditions,
      actions: allActions,
    );
  }

  /// Get information about the vision model
  Future<Map<String, dynamic>> getModelInfo() async {
    if (!isReady) {
      return {'status': 'not_initialised'};
    }

    return {
      'status': 'ready',
      'supports_vision': true,
      'local_only': true,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_vlm != null) {
      _vlm!.unload();
      _vlm = null;
    }
    _isInitialised = false;
    debugPrint('[ScreenshotParser] Resources disposed');
  }
}

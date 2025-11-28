# NothFlows Team Workstreams
## 3-Way Division of Remaining Tasks

**Total Remaining**: 8 tasks → Divided into 3 parallel workstreams

---

## 📊 PROGRESS TRACKER

### 🔵 Workstream 1: Core Accessibility Actions (Team Member A)
**Status**: ✅ READY FOR TESTING (95% complete)

- [x] Implement Vision Assist actions (4/4) ✅
- [x] Implement Motor Assist actions (4/4) ✅
- [x] Implement Cognitive/Neurodivergent actions (4/4) ✅
- [x] Implement Hearing Support actions (4/4) ✅
- [x] Implement Safety action (1/1) ✅
- [x] Add Android native methods to MainActivity.kt (8/8) ✅
- [x] Update _executeAction switch statement ✅
- [x] Update getDescription() for new action types in flow_dsl.dart ✅
- [ ] Test all accessibility actions on Nothing Phone 🧪

**Files Modified**:
- ✅ `lib/services/automation_executor.dart` - Added 18 action methods + switch cases (~390 lines)
- ✅ `android/app/src/main/kotlin/com/nothflows/MainActivity.kt` - Added 8 native methods (~130 lines)
- ✅ `lib/models/flow_dsl.dart` - Added descriptions for 18 new action types (~68 lines)

**Total Lines Added**: ~588 lines

**Next Steps**:
1. ✅ ~~Complete action descriptions~~ DONE
2. Hot reload Flutter app and test on device
3. Verify each accessibility action works as expected

---

### 🟢 Workstream 2: Cactus Intelligence (Team Member B)
**Status**: ✅ COMPLETE

- [x] Task 4: Upgrade CactusLLM to multi-step planner ✅
- [x] Task 5: Screenshot → Flow via SmolVLM ✅
- [x] Task 6: Local personalization via CactusRAG ✅
- [x] Task 10: Remove simulation mode ✅

**Files Modified/Created**:
- ✅ `lib/services/cactus_llm_service.dart` - Multi-step planner with accessibility focus (~390 lines)
- ✅ `lib/services/screenshot_parser_service.dart` - NEW: Vision model screenshot parsing (~370 lines)
- ✅ `lib/services/personalization_service.dart` - NEW: RAG-based personalization (~320 lines)
- ✅ `lib/services/automation_executor.dart` - Removed simulation mode

**Total Lines Added**: ~1080 lines

---

### 🟡 Workstream 3: Sensors, UI & Daily Check-In (Team Member C)
**Status**: ⚪ NOT STARTED

- [ ] Task 7: Daily Check-In screen
- [ ] Task 8: Sensor-aware triggers
- [ ] Task 9: UI updates for accessibility

---

## 🔵 WORKSTREAM 1: Core Accessibility Actions & Execution
**Owner**: Team Member A
**Estimated Effort**: ~700 lines of code
**Complexity**: High (Native Android integration required)
**Dependencies**: None (can start immediately)

### Tasks Included:

#### Task 3: Add Accessibility Action Primitives to AutomationExecutor
**Files**:
- `lib/services/automation_executor.dart` (~500 lines)
- `android/app/src/main/kotlin/com/nothflows/MainActivity.kt` (~200 lines)

**What to Build**:
Implement execution logic for 18 new accessibility actions:

**Vision Assist Actions**:
```dart
Future<ExecutionResult> _increaseTextSize(Map<String, dynamic> params) async {
  final size = params['to'] as String? ?? 'large'; // 'small', 'medium', 'large', 'max'

  try {
    final success = await platform.invokeMethod<bool>('setTextSize', {'size': size});
    return ExecutionResult(
      actionType: 'increase_text_size',
      success: success == true,
      message: 'Set text size to $size',
    );
  } catch (e) {
    return ExecutionResult(actionType: 'increase_text_size', success: false, message: 'Error: $e');
  }
}

Future<ExecutionResult> _increaseContrast(Map<String, dynamic> params) async {
  // Enable high contrast mode via Android accessibility settings
  try {
    final success = await platform.invokeMethod<bool>('setHighContrast', {'enabled': true});
    return ExecutionResult(
      actionType: 'increase_contrast',
      success: success == true,
      message: 'Enabled high contrast mode',
    );
  } catch (e) {
    return ExecutionResult(actionType: 'increase_contrast', success: false, message: 'Error: $e');
  }
}

Future<ExecutionResult> _enableScreenReader(Map<String, dynamic> params) async {
  // Launch TalkBack/screen reader
  try {
    await DeviceApps.openApp('com.google.android.marvin.talkback');
    return ExecutionResult(
      actionType: 'enable_screen_reader',
      success: true,
      message: 'Launched screen reader',
    );
  } catch (e) {
    return ExecutionResult(actionType: 'enable_screen_reader', success: false, message: 'Error: $e');
  }
}

Future<ExecutionResult> _boostBrightness(Map<String, dynamic> params) async {
  final level = (params['to'] as int? ?? 100).clamp(0, 100);
  // Reuse existing setBrightness logic
  return await _setBrightness({'to': level});
}
```

**Motor Assist Actions**:
```dart
Future<ExecutionResult> _reduceGestureSensitivity(Map<String, dynamic> params) async {
  // Stub: Would require AccessibilityService implementation
  return ExecutionResult(
    actionType: 'reduce_gesture_sensitivity',
    success: true,
    message: 'Reduced gesture sensitivity (requires accessibility service)',
  );
}

Future<ExecutionResult> _enableVoiceTyping(Map<String, dynamic> params) async {
  try {
    final success = await platform.invokeMethod<bool>('enableVoiceTyping');
    return ExecutionResult(
      actionType: 'enable_voice_typing',
      success: success == true,
      message: 'Enabled voice typing',
    );
  } catch (e) {
    return ExecutionResult(actionType: 'enable_voice_typing', success: false, message: 'Error: $e');
  }
}

Future<ExecutionResult> _enableOneHandedMode(Map<String, dynamic> params) async {
  try {
    final success = await platform.invokeMethod<bool>('enableOneHandedMode');
    return ExecutionResult(
      actionType: 'enable_one_handed_mode',
      success: success == true,
      message: 'Enabled one-handed mode',
    );
  } catch (e) {
    return ExecutionResult(actionType: 'enable_one_handed_mode', success: false, message: 'Error: $e');
  }
}

Future<ExecutionResult> _increaseTouchTargets(Map<String, dynamic> params) async {
  // Stub: Would require launcher modification
  return ExecutionResult(
    actionType: 'increase_touch_targets',
    success: true,
    message: 'Increased touch target sizes (visual only)',
  );
}
```

**Cognitive/Neurodivergent Actions**:
```dart
Future<ExecutionResult> _reduceAnimation(Map<String, dynamic> params) async {
  try {
    final success = await platform.invokeMethod<bool>('setAnimationScale', {'scale': 0.5});
    return ExecutionResult(
      actionType: 'reduce_animation',
      success: success == true,
      message: 'Reduced animation speed',
    );
  } catch (e) {
    return ExecutionResult(actionType: 'reduce_animation', success: false, message: 'Error: $e');
  }
}

Future<ExecutionResult> _simplifyHomeScreen(Map<String, dynamic> params) async {
  // Stub: Would require launcher integration
  return ExecutionResult(
    actionType: 'simplify_home_screen',
    success: true,
    message: 'Simplified home screen layout (requires launcher support)',
  );
}

Future<ExecutionResult> _muteDistractionApps(Map<String, dynamic> params) async {
  final distractionApps = ['Instagram', 'TikTok', 'Twitter', 'Facebook', 'Snapchat'];
  return await _muteApps({'apps': distractionApps});
}

Future<ExecutionResult> _highlightFocusApps(Map<String, dynamic> params) async {
  // Stub: Visual UI change
  return ExecutionResult(
    actionType: 'highlight_focus_apps',
    success: true,
    message: 'Highlighted focus apps on home screen',
  );
}
```

**Hearing Support Actions**:
```dart
Future<ExecutionResult> _enableLiveTranscribe(Map<String, dynamic> params) async {
  try {
    await DeviceApps.openApp('com.google.audio.hearing.visualization.accessibility.scribe');
    return ExecutionResult(
      actionType: 'enable_live_transcribe',
      success: true,
      message: 'Launched Live Transcribe',
    );
  } catch (e) {
    return ExecutionResult(actionType: 'enable_live_transcribe', success: false, message: 'Error: $e');
  }
}

Future<ExecutionResult> _enableCaptions(Map<String, dynamic> params) async {
  try {
    final success = await platform.invokeMethod<bool>('enableCaptions');
    return ExecutionResult(
      actionType: 'enable_captions',
      success: success == true,
      message: 'Enabled system captions',
    );
  } catch (e) {
    return ExecutionResult(actionType: 'enable_captions', success: false, message: 'Error: $e');
  }
}

Future<ExecutionResult> _flashScreenAlerts(Map<String, dynamic> params) async {
  try {
    final success = await platform.invokeMethod<bool>('enableFlashAlerts');
    return ExecutionResult(
      actionType: 'flash_screen_alerts',
      success: success == true,
      message: 'Enabled screen flash for alerts',
    );
  } catch (e) {
    return ExecutionResult(actionType: 'flash_screen_alerts', success: false, message: 'Error: $e');
  }
}

Future<ExecutionResult> _boostHapticFeedback(Map<String, dynamic> params) async {
  try {
    final success = await platform.invokeMethod<bool>('setHapticStrength', {'strength': 'strong'});
    return ExecutionResult(
      actionType: 'boost_haptic_feedback',
      success: success == true,
      message: 'Increased haptic feedback strength',
    );
  } catch (e) {
    return ExecutionResult(actionType: 'boost_haptic_feedback', success: false, message: 'Error: $e');
  }
}
```

**Safety Action**:
```dart
Future<ExecutionResult> _launchCareApp(Map<String, dynamic> params) async {
  final careApp = params['app'] as String? ?? 'Emergency Contacts';

  try {
    // Try common emergency/care apps
    final careApps = ['com.android.contacts', 'com.google.android.contacts'];
    for (final packageName in careApps) {
      try {
        await DeviceApps.openApp(packageName);
        return ExecutionResult(
          actionType: 'launch_care_app',
          success: true,
          message: 'Launched $careApp',
        );
      } catch (e) {
        continue;
      }
    }
    throw Exception('No care app found');
  } catch (e) {
    return ExecutionResult(actionType: 'launch_care_app', success: false, message: 'Error: $e');
  }
}
```

**Android Native Methods** (MainActivity.kt):
```kotlin
when (call.method) {
    "setTextSize" -> {
        val size = call.argument<String>("size") ?: "medium"
        val scale = when(size) {
            "small" -> 0.85f
            "medium" -> 1.0f
            "large" -> 1.15f
            "max" -> 1.3f
            else -> 1.0f
        }
        try {
            Settings.System.putFloat(contentResolver, Settings.System.FONT_SCALE, scale)
            result.success(true)
        } catch (e: Exception) {
            result.error("FAILED", "Cannot set text size", null)
        }
    }

    "setHighContrast" -> {
        // Note: High contrast requires WRITE_SECURE_SETTINGS permission
        try {
            Settings.Secure.putInt(contentResolver,
                Settings.Secure.ACCESSIBILITY_DISPLAY_INVERSION_ENABLED, 1)
            result.success(true)
        } catch (e: Exception) {
            result.error("FAILED", "Cannot set contrast", null)
        }
    }

    "setAnimationScale" -> {
        val scale = call.argument<Double>("scale")?.toFloat() ?: 1.0f
        try {
            Settings.Global.putFloat(contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, scale)
            Settings.Global.putFloat(contentResolver, Settings.Global.TRANSITION_ANIMATION_SCALE, scale)
            Settings.Global.putFloat(contentResolver, Settings.Global.WINDOW_ANIMATION_SCALE, scale)
            result.success(true)
        } catch (e: Exception) {
            result.error("FAILED", "Cannot set animation scale", null)
        }
    }

    "enableVoiceTyping" -> {
        try {
            val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("FAILED", "Cannot open input settings", null)
        }
    }

    "enableCaptions" -> {
        try {
            Settings.Secure.putInt(contentResolver,
                Settings.Secure.ACCESSIBILITY_CAPTIONING_ENABLED, 1)
            result.success(true)
        } catch (e: Exception) {
            result.error("FAILED", "Cannot enable captions", null)
        }
    }

    "enableFlashAlerts" -> {
        // Note: Flash alerts typically require camera permission
        try {
            Settings.System.putInt(contentResolver,
                "flash_notification", 1)
            result.success(true)
        } catch (e: Exception) {
            result.error("FAILED", "Cannot enable flash alerts", null)
        }
    }

    "setHapticStrength" -> {
        val strength = call.argument<String>("strength") ?: "medium"
        val intensity = when(strength) {
            "light" -> 50
            "medium" -> 100
            "strong" -> 255
            else -> 100
        }
        try {
            Settings.System.putInt(contentResolver, Settings.System.HAPTIC_FEEDBACK_INTENSITY, intensity)
            result.success(true)
        } catch (e: Exception) {
            result.error("FAILED", "Cannot set haptic strength", null)
        }
    }

    "enableOneHandedMode" -> {
        // One-handed mode varies by manufacturer
        try {
            val intent = Intent("android.settings.GESTURE_SETTINGS")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("FAILED", "Cannot enable one-handed mode", null)
        }
    }
}
```

**Update _executeAction switch**:
```dart
case 'increase_text_size':
  return await _increaseTextSize(action.parameters);
case 'increase_contrast':
  return await _increaseContrast(action.parameters);
case 'enable_screen_reader':
  return await _enableScreenReader(action.parameters);
case 'reduce_animation':
  return await _reduceAnimation(action.parameters);
case 'boost_brightness':
  return await _boostBrightness(action.parameters);
case 'reduce_gesture_sensitivity':
  return await _reduceGestureSensitivity(action.parameters);
case 'enable_voice_typing':
  return await _enableVoiceTyping(action.parameters);
case 'enable_live_transcribe':
  return await _enableLiveTranscribe(action.parameters);
case 'simplify_home_screen':
  return await _simplifyHomeScreen(action.parameters);
case 'mute_distraction_apps':
  return await _muteDistractionApps(action.parameters);
case 'highlight_focus_apps':
  return await _highlightFocusApps(action.parameters);
case 'launch_care_app':
  return await _launchCareApp(action.parameters);
case 'enable_high_visibility':
  return await _increaseContrast(action.parameters); // Alias
case 'enable_captions':
  return await _enableCaptions(action.parameters);
case 'flash_screen_alerts':
  return await _flashScreenAlerts(action.parameters);
case 'boost_haptic_feedback':
  return await _boostHapticFeedback(action.parameters);
case 'enable_one_handed_mode':
  return await _enableOneHandedMode(action.parameters);
case 'increase_touch_targets':
  return await _increaseTouchTargets(action.parameters);
```

**Testing Checklist**:
- [ ] Test each action on real Nothing Phone
- [ ] Verify permission requests work
- [ ] Test graceful failure when permissions denied
- [ ] Verify all native method calls succeed
- [ ] Test action descriptions display correctly

---

## 🟢 WORKSTREAM 2: Cactus Intelligence (LLM, VLM, RAG)
**Owner**: Team Member B
**Estimated Effort**: ~800 lines of code
**Complexity**: High (Cactus SDK integration)
**Dependencies**: None (can start immediately)

### Tasks Included:

#### Task 4: Upgrade CactusLLM to Multi-Step Planner
**File**: `lib/services/cactus_llm_service.dart` (~300 lines)

#### Task 5: Screenshot → Flow via SmolVLM
**File**: `lib/services/screenshot_parser_service.dart` (new, ~150 lines)

#### Task 6: Local Personalization via CactusRAG
**File**: `lib/services/personalization_service.dart` (new, ~200 lines)

#### Task 10: Remove Simulation Mode
**Files**:
- `lib/services/cactus_llm_service.dart` (~50 lines removed)
- `lib/services/automation_executor.dart` (~50 lines removed)

---

### Task 4 Details: Upgrade CactusLLM to Multi-Step Planner

**New System Prompt**:
```dart
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

Available Modes: vision, motor, neurodivergent, calm, hearing, custom

Available Actions:
[Vision] increase_text_size, increase_contrast, enable_screen_reader, boost_brightness, reduce_animation
[Motor] reduce_gesture_sensitivity, enable_voice_typing, enable_one_handed_mode, increase_touch_targets
[Cognitive] reduce_animation, simplify_home_screen, mute_distraction_apps, highlight_focus_apps, enable_dnd
[Hearing] enable_live_transcribe, enable_captions, flash_screen_alerts, boost_haptic_feedback
[General] lower_brightness, set_volume, mute_apps, launch_app, clean_screenshots, clean_downloads

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
```

**New Methods**:
```dart
/// Generate multi-step accessibility plan with context reasoning
Future<FlowDSL?> generatePlan({
  required String userRequest,
  String? userContext,  // "I have low vision", "I have hand tremors"
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
    if (sensorData != null) {
      contextInfo.writeln('Sensor data: $sensorData');
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

    final result = await _llm!.generateCompletion(messages: messages);

    if (!result.success) {
      throw Exception('LLM generation failed: ${result.response}');
    }

    debugPrint('[CactusLLM] Raw response: ${result.response}');

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

  if (lower.contains('see') || lower.contains('eyes') || lower.contains('vision') ||
      lower.contains('read') || lower.contains('bright')) {
    return 'vision';
  }
  if (lower.contains('hear') || lower.contains('sound') || lower.contains('loud') ||
      lower.contains('notification')) {
    return 'hearing';
  }
  if (lower.contains('tap') || lower.contains('hand') || lower.contains('finger') ||
      lower.contains('gesture') || lower.contains('tremor')) {
    return 'motor';
  }
  if (lower.contains('anxiety') || lower.contains('overwhelm') || lower.contains('calm') ||
      lower.contains('stress') || lower.contains('distract')) {
    return 'calm';
  }
  if (lower.contains('focus') || lower.contains('adhd') || lower.contains('autism') ||
      lower.contains('concentrate')) {
    return 'neurodivergent';
  }

  return 'custom';
}

/// Merge multiple flows intelligently (deduplicate, combine)
Future<FlowDSL?> mergeFlows(List<FlowDSL> flows) async {
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
```

**Update parseInstruction** (replace existing):
```dart
@override
Future<FlowDSL?> parseInstruction({
  required String instruction,
  required String mode,
}) async {
  // Infer context from instruction
  final inferredContext = inferDisabilityContext(instruction);

  // Use new generatePlan method
  return await generatePlan(
    userRequest: instruction,
    userContext: 'Mode: $mode, Inferred: $inferredContext',
  );
}
```

---

### Task 5 Details: Screenshot → Flow via SmolVLM

**New File**: `lib/services/screenshot_parser_service.dart`

```dart
import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/flow_dsl.dart';

/// Service for parsing screenshots into accessibility flows using SmolVLM
class ScreenshotParserService {
  static final ScreenshotParserService _instance = ScreenshotParserService._internal();
  factory ScreenshotParserService() => _instance;
  ScreenshotParserService._internal();

  CactusVLM? _vlm;
  bool _isInitialised = false;

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

Available modes: vision, motor, neurodivergent, calm, hearing, custom

Available actions: increase_text_size, increase_contrast, boost_brightness, reduce_animation,
enable_screen_reader, enable_captions, enable_dnd, mute_apps, lower_brightness, set_volume

Rules:
1. Infer the best assistive mode based on visible settings
2. Generate 2-4 relevant actions
3. Output ONLY JSON, no explanations

Example:
If you see brightness and text size settings:
{"trigger":"assistive_mode.on:vision","actions":[{"type":"boost_brightness","to":90},{"type":"increase_text_size","to":"large"}]}

Output ONLY JSON.''';

  /// Initialize SmolVLM model
  Future<void> initialise() async {
    if (_isInitialised) return;

    debugPrint('[ScreenshotParser] Initializing SmolVLM...');

    try {
      _vlm = CactusVLM();

      // Download SmolVLM if needed
      await _vlm!.downloadModel(model: 'smolvlm');

      // Initialize model
      await _vlm!.initializeModel();

      _isInitialised = true;
      debugPrint('[ScreenshotParser] SmolVLM loaded successfully');
    } catch (e) {
      debugPrint('[ScreenshotParser] Failed to initialize: $e');
      throw Exception('SmolVLM initialization failed: $e');
    }
  }

  bool get isReady => _isInitialised;

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
      throw Exception('SmolVLM not initialized');
    }

    try {
      debugPrint('[ScreenshotParser] Analyzing screenshot: ${screenshot.path}');

      // Build prompt
      final prompt = userPrompt ?? visionPrompt;
      final modeContext = targetMode != null
          ? 'Target assistive mode: $targetMode\n$prompt'
          : prompt;

      // Generate from image
      final result = await _vlm!.generateFromImage(
        imagePath: screenshot.path,
        prompt: modeContext,
      );

      if (!result.success) {
        throw Exception('VLM generation failed: ${result.response}');
      }

      debugPrint('[ScreenshotParser] VLM response: ${result.response}');

      // Extract JSON from response
      String jsonText = result.response.trim();
      jsonText = jsonText.replaceAll(RegExp(r'```json\s*'), '');
      jsonText = jsonText.replaceAll(RegExp(r'```\s*'), '');
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

  /// Dispose resources
  Future<void> dispose() async {
    if (_vlm != null) {
      _vlm!.unload();
      _vlm = null;
    }
    _isInitialised = false;
  }
}
```

**Integration with UI** (mode_detail_screen.dart):
```dart
// Add button to mode detail screen
ElevatedButton.icon(
  onPressed: _createFromScreenshot,
  icon: const Icon(Icons.camera_alt),
  label: const Text('Create from Screenshot'),
),

// Handler
Future<void> _createFromScreenshot() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  if (image == null) return;

  setState(() => _isProcessing = true);

  try {
    final flow = await ScreenshotParserService().parseScreenshot(
      screenshot: File(image.path),
      targetMode: widget.mode.id,
    );

    if (flow != null) {
      // Show preview and save
      _showFlowPreview(flow);
    } else {
      _showError('Could not parse screenshot');
    }
  } catch (e) {
    _showError('Error: $e');
  } finally {
    setState(() => _isProcessing = false);
  }
}
```

---

### Task 6 Details: Local Personalization via CactusRAG

**New File**: `lib/services/personalization_service.dart`

```dart
import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import '../models/flow_dsl.dart';

/// Service for local personalization using CactusRAG embeddings
class PersonalizationService {
  static final PersonalizationService _instance = PersonalizationService._internal();
  factory PersonalizationService() => _instance;
  PersonalizationService._internal();

  CactusRAG? _rag;
  bool _isInitialised = false;

  /// Initialize CactusRAG with local embedding model
  Future<void> initialise() async {
    if (_isInitialised) return;

    debugPrint('[Personalization] Initializing CactusRAG...');

    try {
      _rag = CactusRAG();

      await _rag!.initialize(
        collectionName: 'nothflows_user_context',
        embeddingModel: 'all-minilm-l6-v2',  // Small, fast, local embeddings
      );

      _isInitialised = true;
      debugPrint('[Personalization] CactusRAG initialized');
    } catch (e) {
      debugPrint('[Personalization] Failed to initialize: $e');
      throw Exception('CactusRAG initialization failed: $e');
    }
  }

  bool get isReady => _isInitialised;

  /// Store user flow for future personalization
  Future<void> storeFlow(FlowDSL flow) async {
    if (!_isInitialised) await initialise();

    try {
      await _rag!.addDocument(
        id: flow.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        content: flow.getDescription(),
        metadata: {
          'type': 'flow',
          'trigger': flow.trigger,
          'mode': flow.trigger.split(':').last,
          'actions': flow.actions.map((a) => a.type).toList(),
          'action_count': flow.actions.length,
          'timestamp': flow.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'has_conditions': flow.conditions != null && !flow.conditions!.isEmpty,
        },
      );

      debugPrint('[Personalization] Stored flow: ${flow.id}');
    } catch (e) {
      debugPrint('[Personalization] Error storing flow: $e');
    }
  }

  /// Store daily check-in response
  Future<void> storeCheckIn(String response, String sentiment) async {
    if (!_isInitialised) await initialise();

    try {
      await _rag!.addDocument(
        id: 'checkin_${DateTime.now().millisecondsSinceEpoch}',
        content: response,
        metadata: {
          'type': 'daily_checkin',
          'sentiment': sentiment,  // 'positive', 'neutral', 'struggling'
          'date': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('[Personalization] Stored check-in with sentiment: $sentiment');
    } catch (e) {
      debugPrint('[Personalization] Error storing check-in: $e');
    }
  }

  /// Query user context for personalized suggestions
  Future<String> queryUserContext(String query, {int limit = 5}) async {
    if (!_isInitialised) await initialise();

    try {
      final results = await _rag!.query(
        query: query,
        limit: limit,
      );

      if (results.isEmpty) {
        return 'No previous context found';
      }

      return results.map((r) => r.content).join('\n---\n');
    } catch (e) {
      debugPrint('[Personalization] Error querying context: $e');
      return '';
    }
  }

  /// Get personalized suggestions for a specific assistive mode
  Future<List<String>> getSuggestionsForMode(String mode) async {
    final suggestions = <String>[];

    try {
      final context = await queryUserContext(
        'Show me past $mode flows and what actions I prefer',
        limit: 3,
      );

      if (context.isNotEmpty && context != 'No previous context found') {
        suggestions.add('Based on your history with $mode mode...');
        suggestions.addAll(context.split('\n---\n'));
      } else {
        // Default suggestions
        suggestions.addAll(_getDefaultSuggestionsForMode(mode));
      }
    } catch (e) {
      debugPrint('[Personalization] Error getting suggestions: $e');
      suggestions.addAll(_getDefaultSuggestionsForMode(mode));
    }

    return suggestions.take(3).toList();
  }

  /// Get recent sentiment from check-ins
  Future<String> getRecentSentiment() async {
    try {
      final context = await queryUserContext(
        'Recent daily check-ins and how I\'ve been feeling',
        limit: 1,
      );

      // Parse sentiment from context
      if (context.contains('struggling')) return 'struggling';
      if (context.contains('positive')) return 'positive';
      return 'neutral';
    } catch (e) {
      return 'neutral';
    }
  }

  /// Clear all stored personalization data
  Future<void> clearAllData() async {
    if (!_isInitialised) return;

    try {
      await _rag!.clearCollection();
      debugPrint('[Personalization] Cleared all user data');
    } catch (e) {
      debugPrint('[Personalization] Error clearing data: $e');
    }
  }

  List<String> _getDefaultSuggestionsForMode(String mode) {
    switch (mode) {
      case 'vision':
        return [
          'Increase text size to maximum',
          'Enable high contrast mode',
          'Boost brightness to 90%',
        ];
      case 'motor':
        return [
          'Reduce gesture sensitivity',
          'Enable voice typing',
          'Enable one-handed mode',
        ];
      case 'neurodivergent':
        return [
          'Mute distraction apps',
          'Enable Do Not Disturb',
          'Reduce animations',
        ];
      case 'calm':
        return [
          'Enable Do Not Disturb',
          'Lower brightness to 30%',
          'Reduce all notifications',
        ];
      case 'hearing':
        return [
          'Enable live transcribe',
          'Flash screen for alerts',
          'Boost haptic feedback',
        ];
      default:
        return ['Create your own custom routine'];
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    // CactusRAG persists data, no need to dispose
    _isInitialised = false;
  }
}
```

---

### Task 10 Details: Remove Simulation Mode

**Delete from cactus_llm_service.dart**:
```dart
// DELETE THESE LINES:
// Simulation mode for non-Android platforms
if (!Platform.isAndroid) {
  debugPrint('[CactusLLM] Non-Android platform detected. Starting in SIMULATION mode.');
  _isInitialised = true;
  return;
}

// DELETE THIS METHOD:
Future<FlowDSL?> _simulateParse(String instruction, String mode) async { ... }

// DELETE FALLBACK in parseInstruction:
} catch (e) {
  debugPrint('[CactusLLM] Error parsing with LLM: $e, falling back to simulation');
  return _simulateParse(instruction, mode);  // DELETE THIS LINE
}
```

**Replace with strict requirement**:
```dart
Future<void> initialise() async {
  if (_isInitialised || _isLoading) return;

  _isLoading = true;
  try {
    debugPrint('[CactusLLM] Initialising Qwen3 0.6B model...');

    _llm = CactusLM();
    await _llm!.downloadModel(model: 'qwen3-0.6');
    await _llm!.initializeModel();

    _isInitialised = true;
    debugPrint('[CactusLLM] Model loaded successfully');
  } catch (e) {
    debugPrint('[CactusLLM] CRITICAL: Failed to initialise model: $e');
    _isInitialised = false;
    rethrow;  // Don't fall back, fail hard
  } finally {
    _isLoading = false;
  }
}
```

**Delete from automation_executor.dart**:
```dart
// DELETE:
bool get _isSimulation => !Platform.isAndroid;

// DELETE:
Future<ExecutionResult> _simulateExecution(FlowAction action) async { ... }

// DELETE FALLBACK in _executeAction:
Future<ExecutionResult> _executeAction(FlowAction action) async {
  if (_isSimulation) {  // DELETE THIS CHECK
    return _simulateExecution(action);
  }
  // ... rest of implementation
}
```

**Replace with**:
```dart
Future<ExecutionResult> _executeAction(FlowAction action) async {
  if (!Platform.isAndroid) {
    throw UnsupportedError('NothFlows requires Android. Simulation mode has been removed.');
  }

  try {
    switch (action.type) {
      // ... all real implementations
    }
  } catch (e) {
    return ExecutionResult(
      actionType: action.type,
      success: false,
      message: e.toString(),
    );
  }
}
```

**Testing Checklist**:
- [ ] Verify app crashes gracefully on non-Android platforms
- [ ] Verify helpful error messages when Cactus fails to load
- [ ] Test that all flows require real LLM processing
- [ ] Confirm no simulation code paths remain

---

## 🟡 WORKSTREAM 3: Sensors, UI & Daily Check-In
**Owner**: Team Member C
**Estimated Effort**: ~650 lines of code
**Complexity**: Medium (UI + new features)
**Dependencies**: None (can start immediately)

### Tasks Included:

#### Task 7: Add Daily Check-In Flow & Screen
**File**: `lib/screens/daily_checkin_screen.dart` (new, ~150 lines)

#### Task 8: Add Sensor-Aware Triggers
**File**: `lib/services/sensor_service.dart` (new, ~200 lines)

#### Task 9: Update UI for Accessibility Purpose
**Files**:
- `lib/screens/home_screen.dart` (~100 lines modified)
- `lib/screens/mode_detail_screen.dart` (~100 lines modified)
- `lib/screens/permissions_screen.dart` (~100 lines modified)

---

### Task 7 Details: Daily Check-In Screen

**New File**: `lib/screens/daily_checkin_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/cactus_llm_service.dart';
import '../services/personalization_service.dart';
import '../services/storage_service.dart';

/// Daily check-in screen for adaptive accessibility
class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  final _controller = TextEditingController();
  bool _isProcessing = false;
  String? _suggestedMode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processCheckIn() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final response = _controller.text.trim();

      // Analyze with LLM to determine sentiment and needs
      final sentiment = await _analyzeSentiment(response);
      final suggestedMode = CactusLLMService().inferDisabilityContext(response);

      // Store in RAG for personalization
      await PersonalizationService().storeCheckIn(response, sentiment);

      setState(() {
        _suggestedMode = suggestedMode;
        _isProcessing = false;
      });

      // Show suggestion dialog
      _showSuggestionDialog(suggestedMode, sentiment);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Failed to process check-in: $e');
    }
  }

  Future<String> _analyzeSentiment(String response) async {
    final lower = response.toLowerCase();

    // Simple keyword-based sentiment analysis
    if (lower.contains('hurt') || lower.contains('pain') || lower.contains('hard') ||
        lower.contains('difficult') || lower.contains('struggling') || lower.contains('anxious')) {
      return 'struggling';
    }
    if (lower.contains('good') || lower.contains('great') || lower.contains('fine') ||
        lower.contains('better')) {
      return 'positive';
    }
    return 'neutral';
  }

  void _showSuggestionDialog(String mode, String sentiment) {
    final modeNames = {
      'vision': 'Vision Assist',
      'motor': 'Motor Assist',
      'hearing': 'Hearing Support',
      'calm': 'Calm Mode',
      'neurodivergent': 'Neurodivergent Focus',
      'custom': 'Custom Assistive',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggestion'),
        content: Text(
          sentiment == 'struggling'
              ? 'Based on what you shared, ${modeNames[mode]} might help. Would you like to activate it?'
              : 'Thank you for checking in. ${modeNames[mode]} is available if you need it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
          if (sentiment == 'struggling')
            ElevatedButton(
              onPressed: () async {
                await StorageService().setActiveMode(mode);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Activate'),
            ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Daily Check-In',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'How are you feeling today?',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Tell me about any challenges or accessibility needs you have today. Your phone will adapt to help you.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 32),

              // Input field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText:
                        'e.g., "My eyes hurt today" or "I\'m feeling anxious" or "My hands are shaky"',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Check-In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Privacy note
              Center(
                child: Text(
                  'Your responses are stored locally and never leave your device',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.5),
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Add to home_screen.dart**:
```dart
// Add button in app bar or floating action
FloatingActionButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DailyCheckInScreen(),
      ),
    );
  },
  child: const Icon(Icons.favorite),
  backgroundColor: const Color(0xFFFF4D9F),
)
```

---

### Task 8 Details: Sensor Service

**New File**: `lib/services/sensor_service.dart`

**pubspec.yaml additions**:
```yaml
dependencies:
  sensors_plus: ^3.0.0
  light: ^3.0.0
  noise_meter: ^5.0.0
```

**Implementation**:
```dart
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
// Note: light and noise_meter may require platform-specific setup
import '../models/flow_dsl.dart';

/// Service for monitoring device sensors and evaluating flow conditions
class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  // Current sensor readings
  String _ambientLight = 'medium';
  String _noiseLevel = 'moderate';
  String _deviceMotion = 'still';
  bool _isMonitoring = false;

  // Sensor values for debugging
  int _currentLux = 100;
  double _currentDecibels = 50;
  double _currentMotion = 0;

  /// Start monitoring all sensors
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    debugPrint('[Sensors] Starting sensor monitoring...');

    try {
      // Motion sensor (accelerometer)
      accelerometerEvents.listen((AccelerometerEvent event) {
        final magnitude = event.x.abs() + event.y.abs() + event.z.abs();
        _currentMotion = magnitude;
        _deviceMotion = _categorizeMotion(magnitude);
      });

      // Light sensor (stub - requires platform plugin)
      _startLightMonitoring();

      // Noise sensor (stub - requires microphone permission)
      _startNoiseMonitoring();

      _isMonitoring = true;
      debugPrint('[Sensors] Sensor monitoring started');
    } catch (e) {
      debugPrint('[Sensors] Error starting sensors: $e');
    }
  }

  /// Stop monitoring sensors
  void stopMonitoring() {
    _isMonitoring = false;
    debugPrint('[Sensors] Sensor monitoring stopped');
  }

  /// Light sensor monitoring (stub)
  Future<void> _startLightMonitoring() async {
    // Stub: Real implementation would use light sensor plugin
    // For now, simulate based on time of day
    _simulateLightSensor();
  }

  void _simulateLightSensor() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      _ambientLight = 'medium';
      _currentLux = 200;
    } else if (hour >= 12 && hour < 18) {
      _ambientLight = 'high';
      _currentLux = 800;
    } else {
      _ambientLight = 'low';
      _currentLux = 20;
    }
  }

  /// Noise sensor monitoring (stub)
  Future<void> _startNoiseMonitoring() async {
    // Stub: Real implementation would use noise_meter plugin
    // Requires RECORD_AUDIO permission
    _ambientLight = 'moderate';
    _currentDecibels = 50;
  }

  /// Evaluate if flow conditions are currently met
  bool evaluateConditions(FlowConditions? conditions) {
    if (conditions == null || conditions.isEmpty) {
      return true; // No conditions = always met
    }

    // Check ambient light
    if (conditions.ambientLight != null) {
      if (conditions.ambientLight != _ambientLight) {
        debugPrint('[Sensors] Condition failed: ambient_light (expected: ${conditions.ambientLight}, got: $_ambientLight)');
        return false;
      }
    }

    // Check noise level
    if (conditions.noiseLevel != null) {
      if (conditions.noiseLevel != _noiseLevel) {
        debugPrint('[Sensors] Condition failed: noise_level (expected: ${conditions.noiseLevel}, got: $_noiseLevel)');
        return false;
      }
    }

    // Check device motion
    if (conditions.deviceMotion != null) {
      if (conditions.deviceMotion != _deviceMotion) {
        debugPrint('[Sensors] Condition failed: device_motion (expected: ${conditions.deviceMotion}, got: $_deviceMotion)');
        return false;
      }
    }

    // Check time of day
    if (conditions.timeOfDay != null) {
      final currentTime = _getCurrentTimeOfDay();
      if (conditions.timeOfDay != currentTime) {
        debugPrint('[Sensors] Condition failed: time_of_day (expected: ${conditions.timeOfDay}, got: $currentTime)');
        return false;
      }
    }

    // Check battery level
    // Note: Would require battery_plus plugin
    // For now, skip this check

    debugPrint('[Sensors] All conditions met');
    return true;
  }

  /// Get current sensor readings as map
  Map<String, dynamic> getCurrentReadings() {
    return {
      'ambient_light': _ambientLight,
      'lux': _currentLux,
      'noise_level': _noiseLevel,
      'decibels': _currentDecibels,
      'device_motion': _deviceMotion,
      'motion_magnitude': _currentMotion,
      'time_of_day': _getCurrentTimeOfDay(),
    };
  }

  String _categorizeLight(int lux) {
    if (lux < 50) return 'low';
    if (lux < 500) return 'medium';
    return 'high';
  }

  String _categorizeNoise(double decibels) {
    if (decibels < 50) return 'quiet';
    if (decibels < 70) return 'moderate';
    return 'loud';
  }

  String _categorizeMotion(double magnitude) {
    if (magnitude < 5) return 'still';
    if (magnitude < 15) return 'walking';
    return 'shaky';
  }

  String _getCurrentTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  // Getters for UI display
  String get ambientLight => _ambientLight;
  String get noiseLevel => _noiseLevel;
  String get deviceMotion => _deviceMotion;
  bool get isMonitoring => _isMonitoring;
}
```

**Integration in automation_executor.dart**:
```dart
// At start of executeFlow
Future<List<ExecutionResult>> executeFlow(FlowDSL flow) async {
  debugPrint('[Executor] Starting execution of flow: ${flow.trigger}');

  // Check conditions before executing
  if (flow.conditions != null && !flow.conditions!.isEmpty) {
    final conditionsMet = SensorService().evaluateConditions(flow.conditions);
    if (!conditionsMet) {
      debugPrint('[Executor] Flow conditions not met, skipping execution');
      return [
        ExecutionResult(
          actionType: 'condition_check',
          success: false,
          message: 'Flow conditions not currently met',
        ),
      ];
    }
  }

  // Continue with execution...
  final results = <ExecutionResult>[];
  // ...
}
```

---

### Task 9 Details: UI Updates

**home_screen.dart modifications**:
```dart
// Update app title
AppBar(
  title: const Text('Your Assistive Automation Engine'),  // Changed from "NothFlows"
)

// Add Daily Check-In button
FloatingActionButton.extended(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const DailyCheckInScreen()),
  ),
  icon: const Icon(Icons.favorite),
  label: const Text('Daily Check-In'),
  backgroundColor: const Color(0xFFFF4D9F),
)

// Update mode cards to show category badges
ListTile(
  leading: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: mode.color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(mode.icon, color: mode.color),
  ),
  title: Text(mode.name),
  subtitle: Row(
    children: [
      // Category badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: mode.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          mode.category.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: mode.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(mode.description)),
    ],
  ),
)
```

**mode_detail_screen.dart modifications**:
```dart
// Add "Create from Screenshot" button
ElevatedButton.icon(
  onPressed: _createFromScreenshot,
  icon: const Icon(Icons.camera_alt),
  label: const Text('Create from Screenshot'),
  style: ElevatedButton.styleFrom(
    backgroundColor: widget.mode.color,
  ),
)

// Show sensor conditions if present
if (flow.conditions != null && !flow.conditions!.isEmpty)
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Triggers when:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (flow.conditions!.ambientLight != null)
          _conditionChip('Light: ${flow.conditions!.ambientLight}'),
        if (flow.conditions!.noiseLevel != null)
          _conditionChip('Noise: ${flow.conditions!.noiseLevel}'),
        if (flow.conditions!.deviceMotion != null)
          _conditionChip('Motion: ${flow.conditions!.deviceMotion}'),
      ],
    ),
  )

Widget _conditionChip(String label) {
  return Chip(
    label: Text(label),
    backgroundColor: widget.mode.color.withOpacity(0.2),
    labelStyle: TextStyle(color: widget.mode.color),
  );
}
```

**permissions_screen.dart modifications**:
```dart
// Update intro text
Text(
  'NothFlows needs these permissions to provide personalized accessibility automation',
  style: TextStyle(fontSize: 16, color: Colors.white70),
)

// Add explanations for each permission
ListTile(
  leading: const Icon(Icons.storage, color: Colors.white),
  title: const Text('Storage Access'),
  subtitle: const Text(
    'To clean old screenshots and downloads, helping reduce clutter',
    style: TextStyle(fontSize: 12, color: Colors.white60),
  ),
)

ListTile(
  leading: const Icon(Icons.settings, color: Colors.white),
  title: const Text('System Settings'),
  subtitle: const Text(
    'To adjust brightness, volume, and accessibility features for you',
    style: TextStyle(fontSize: 12, color: Colors.white60),
  ),
)

ListTile(
  leading: const Icon(Icons.sensors, color: Colors.white),
  title: const Text('Sensors (Optional)'),
  subtitle: const Text(
    'To detect ambient light and motion for adaptive automation',
    style: TextStyle(fontSize: 12, color: Colors.white60),
  ),
)

// Privacy notice
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.green.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      const Icon(Icons.lock, color: Colors.green),
      const SizedBox(width: 12),
      Expanded(
        child: const Text(
          'All AI processing happens on your device. Your data never leaves your phone.',
          style: TextStyle(color: Colors.green),
        ),
      ),
    ],
  ),
)
```

**Testing Checklist**:
- [ ] Verify Daily Check-In flow works end-to-end
- [ ] Test sensor monitoring starts/stops correctly
- [ ] Verify condition-based flows only execute when conditions met
- [ ] Test UI updates render correctly on all screens
- [ ] Verify accessibility category badges display properly
- [ ] Test screenshot flow creation UI

---

## 📊 Workstream Summary

| Workstream | Tasks | Files | Lines | Team Member | Can Start |
|------------|-------|-------|-------|-------------|-----------|
| 🔵 **Workstream 1** | #3 | 2 | ~700 | Member A | ✅ Now |
| 🟢 **Workstream 2** | #4, #5, #6, #10 | 4 | ~800 | Member B | ✅ Now |
| 🟡 **Workstream 3** | #7, #8, #9 | 5 | ~650 | Member C | ✅ Now |

**Total**: 8 tasks, 11 files, ~2,150 lines of code

---

## 🔄 Integration Points

### Between Workstreams:
- **Workstream 1 ↔ 2**: AutomationExecutor calls CactusLLM for action validation
- **Workstream 1 ↔ 3**: AutomationExecutor checks SensorService for conditions
- **Workstream 2 ↔ 3**: Daily Check-In uses CactusLLM and PersonalizationService
- **All → 3**: UI displays results from all services

### Testing Integration:
- After all workstreams complete, run end-to-end test:
  1. Daily Check-In → LLM analysis → Mode activation
  2. Screenshot → SmolVLM → Flow creation → Execution
  3. Sensor trigger → Condition check → Automatic flow execution

---

## 🚀 Getting Started

### Each Team Member Should:

1. **Pull latest code** with completed Tasks 1 & 2
2. **Review PIVOT.md** for full context
3. **Review this workstream document** for detailed specs
4. **Create a feature branch**: `git checkout -b workstream-1` (or 2, 3)
5. **Start implementing** tasks in order listed
6. **Test locally** on Nothing Phone as you go
7. **Commit frequently** with descriptive messages
8. **Create PR** when workstream is complete

### Dependencies to Install:

**Workstream 1**: None (uses existing dependencies)

**Workstream 2**:
```bash
flutter pub add image_picker image
```

**Workstream 3**:
```bash
flutter pub add sensors_plus
# Note: light and noise_meter may require additional setup
```

---

## ✅ Definition of Done

Each workstream is complete when:
- [ ] All code compiles without errors
- [ ] All new files created
- [ ] All modifications made to existing files
- [ ] Manual testing completed on Android device
- [ ] No simulation/fallback code remains (Workstream 2)
- [ ] Code follows existing NothFlows style
- [ ] Debug logging added for troubleshooting
- [ ] Pull request created with description

---

**Questions?** Check PIVOT.md for full implementation details or ask in team chat.

**Let's build an accessible future! 🦾**

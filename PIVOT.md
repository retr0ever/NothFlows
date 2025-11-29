# NothFlows � Assistive Automation Engine
## Complete Accessibility-First Refactor with Full Cactus Dependency

**Date Started**: 28 November 2025
**Objective**: Transform NothFlows from generic automation into an on-device AI-powered accessibility system for disabled users

---

## <� Vision

**NothFlows: Assistive Automation Engine**

A fully offline, privacy-first, on-device AI system that builds accessibility routines for disabled users using:
- Cactus SDK (Qwen3 0.6B + SmolVLM + CactusRAG)
- Sensor-aware triggers
- Screenshot-to-flow generation
- Voice-first interaction
- Personalized assistive routines

**Key Principle**: Make Cactus absolutely required - no cloud fallback, no simulation mode for core features.

---

##  COMPLETED TASKS

### 1.  Replace Modes with Assistive Modes

**File**: `lib/models/mode_model.dart`

**Changes Made**:
- Replaced Sleep/Focus/Custom with 6 accessibility-first modes:
  - **Vision Assist** - Enhance readability and screen clarity (blue theme)
  - **Motor Assist** - Reduce gesture complexity (purple theme)
  - **Neurodivergent Focus** - Minimise distractions (pink theme)
  - **Calm Mode** - Reduce anxiety and overstimulation (teal theme)
  - **Hearing Support** - Enable captions and visual notifications (orange theme)
  - **Custom Assistive** - Build your own routine (green theme)

**New Fields**:
```dart
final String category; // 'vision', 'motor', 'cognitive', 'sensory', 'custom'
```

**Updated Example Flows**:
- Vision: increase text size, contrast, brightness, screen reader
- Motor: reduce gestures, simplify UI, voice typing, one-handed mode
- Neurodivergent: mute distractions, DND, reduce animations
- Calm: DND, low brightness, mute notifications
- Hearing: live transcribe, visual alerts, captions, haptic boost

**Backwards Compatibility**: Preserved `mode.on:sleep/focus/custom` patterns in validation

---

### 2.  Rewrite DSL Schema for Accessibility

**File**: `lib/models/flow_dsl.dart`

**New Class: FlowConditions**

Added sensory and context-based trigger conditions:
```dart
class FlowConditions {
  final String? ambientLight;      // 'low', 'medium', 'high'
  final String? noiseLevel;        // 'quiet', 'moderate', 'loud'
  final String? deviceMotion;      // 'still', 'walking', 'shaky'
  final List<String>? recentUsage; // App names
  final String? timeOfDay;         // 'morning', 'afternoon', 'evening', 'night'
  final int? batteryLevel;         // 0-100
  final bool? isCharging;
}
```

**Enhanced FlowDSL**:
```dart
class FlowDSL {
  final String trigger;
  final FlowConditions? conditions;  // NEW: Optional conditional triggers
  final List<FlowAction> actions;
  // ...
}
```

**Example DSL**:
```json
{
  "trigger": "assistive_mode.on:vision",
  "conditions": {
    "ambient_light": "low",
    "noise_level": "high",
    "recent_usage": ["Facebook", "Mail"]
  },
  "actions": [
    {"type": "increase_text_size", "to": "max"},
    {"type": "increase_contrast"},
    {"type": "boost_brightness", "to": 100}
  ]
}
```

**New Action Types** (18 added):
- `increase_text_size` - Vision accessibility
- `increase_contrast` - Vision accessibility
- `enable_screen_reader` - Vision accessibility
- `reduce_animation` - Sensory/cognitive accessibility
- `boost_brightness` - Vision accessibility
- `reduce_gesture_sensitivity` - Motor accessibility
- `enable_voice_typing` - Motor accessibility
- `enable_live_transcribe` - Hearing accessibility
- `simplify_home_screen` - Cognitive accessibility
- `mute_distraction_apps` - Cognitive accessibility
- `highlight_focus_apps` - Cognitive accessibility
- `launch_care_app` - Emergency/safety
- `enable_high_visibility` - Vision accessibility
- `enable_captions` - Hearing accessibility
- `flash_screen_alerts` - Hearing accessibility
- `boost_haptic_feedback` - Hearing/sensory accessibility
- `enable_one_handed_mode` - Motor accessibility
- `increase_touch_targets` - Motor accessibility

**Updated Validation**:
- Supports both `mode.on:` and `assistive_mode.on:` triggers
- Validates all 28 action types (10 original + 18 new)
- Validates mode names: vision, motor, neurodivergent, calm, hearing, custom (+ legacy sleep/focus)

**JSON Serialization**:
- Conditions are optional in JSON
- Empty conditions are not serialized
- Full backwards compatibility with existing flows

---

## =� IN PROGRESS

### Task 2 Completion: Add Accessibility Action Descriptions

**File**: `lib/models/flow_dsl.dart` (line 194-246)

**Remaining Work**:
- Update `getDescription()` method to include human-readable descriptions for all 18 new action types
- Current implementation only covers original 10 actions

---

## =� REMAINING TASKS

### 3. � Add Accessibility Action Primitives to AutomationExecutor

**File**: `lib/services/automation_executor.dart`

**Requirements**:
- Implement execution logic for 18 new accessibility actions
- Add Android native integration where needed (via MethodChannel)
- Add stubs for actions requiring system permissions
- Update MainActivity.kt for native Android accessibility APIs

**Action Implementations Needed**:
```dart
// Vision Assist
Future<ExecutionResult> _increaseTextSize(Map<String, dynamic> params)
Future<ExecutionResult> _increaseContrast(Map<String, dynamic> params)
Future<ExecutionResult> _enableScreenReader(Map<String, dynamic> params)
Future<ExecutionResult> _boostBrightness(Map<String, dynamic> params)

// Motor Assist
Future<ExecutionResult> _reduceGestureSensitivity(Map<String, dynamic> params)
Future<ExecutionResult> _enableVoiceTyping(Map<String, dynamic> params)
Future<ExecutionResult> _enableOneHandedMode(Map<String, dynamic> params)
Future<ExecutionResult> _increaseTouchTargets(Map<String, dynamic> params)

// Cognitive/Neurodivergent
Future<ExecutionResult> _reduceAnimation(Map<String, dynamic> params)
Future<ExecutionResult> _simplifyHomeScreen(Map<String, dynamic> params)
Future<ExecutionResult> _muteDistractionApps(Map<String, dynamic> params)
Future<ExecutionResult> _highlightFocusApps(Map<String, dynamic> params)

// Hearing Support
Future<ExecutionResult> _enableLiveTranscribe(Map<String, dynamic> params)
Future<ExecutionResult> _enableCaptions(Map<String, dynamic> params)
Future<ExecutionResult> _flashScreenAlerts(Map<String, dynamic> params)
Future<ExecutionResult> _boostHapticFeedback(Map<String, dynamic> params)

// Safety
Future<ExecutionResult> _launchCareApp(Map<String, dynamic> params)
```

**Android Native Extensions Needed**:
- Font scaling APIs
- Accessibility service controls
- Animation duration settings
- TalkBack/screen reader integration
- Vibration pattern control

---

### 4. � Upgrade CactusLLM to Multi-Step Planner

**File**: `lib/services/cactus_llm_service.dart`

**Current State**:
- Parses natural language � single-action DSL
- Falls back to simulation mode if LLM fails
- Simple system prompt

**Required Changes**:

**New System Prompt** (enforce structured planning):
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
[Vision] increase_text_size, increase_contrast, enable_screen_reader, boost_brightness
[Motor] reduce_gesture_sensitivity, enable_voice_typing, enable_one_handed_mode, increase_touch_targets
[Cognitive] reduce_animation, simplify_home_screen, mute_distraction_apps, highlight_focus_apps
[Hearing] enable_live_transcribe, enable_captions, flash_screen_alerts, boost_haptic_feedback
[General] lower_brightness, set_volume, enable_dnd, mute_apps, launch_app, clean_screenshots

Rules:
1. Infer disability context from request
2. Generate multi-step plans (2-5 actions)
3. Add conditions based on context
4. Output ONLY JSON, no explanations
5. Merge similar flows intelligently

Example:
Input: "My eyes hurt, make everything easier to see"
Output: {
  "trigger": "assistive_mode.on:vision",
  "conditions": {"ambient_light": "high"},
  "actions": [
    {"type": "increase_text_size", "to": "max"},
    {"type": "increase_contrast"},
    {"type": "reduce_animation"},
    {"type": "boost_brightness", "to": 80}
  ]
}''';
```

**New Methods**:
```dart
// Generate multi-step plan with context reasoning
Future<FlowDSL?> generatePlan({
  required String userRequest,
  required String userContext,  // "I have low vision", "I have tremors"
  Map<String, dynamic>? sensorData,  // ambient light, noise, etc.
  List<FlowDSL>? existingFlows,  // For merging/deduplication
});

// Merge flows intelligently
Future<FlowDSL?> mergeFlows(List<FlowDSL> flows);

// Infer disability category from request
String inferDisabilityContext(String request);
```

**Remove Simulation Fallback**:
- Delete `_simulateParse()` method
- Make all paths require Cactus model
- Fail gracefully with error message if model unavailable

---

### 5. � Add Screenshot � Flow via SmolVLM

**New File**: `lib/services/screenshot_parser_service.dart`

**Requirements**:
- Integrate SmolVLM model from Cactus SDK
- Accept screenshot image as input
- Interpret settings UI and accessibility options
- Generate FlowDSL from visual analysis

**Implementation**:
```dart
import 'package:cactus/cactus.dart';
import 'dart:io';
import '../models/flow_dsl.dart';

class ScreenshotParserService {
  static final ScreenshotParserService _instance = ScreenshotParserService._internal();
  factory ScreenshotParserService() => _instance;
  ScreenshotParserService._internal();

  CactusVLM? _vlm;
  bool _isInitialised = false;

  /// Initialize SmolVLM model
  Future<void> initialise() async {
    _vlm = CactusVLM();
    await _vlm!.downloadModel(model: 'smolvlm');
    await _vlm!.initializeModel();
    _isInitialised = true;
  }

  /// Parse screenshot into accessibility flow
  Future<FlowDSL?> parseScreenshot({
    required File screenshot,
    required String mode,  // Target assistive mode
    String? userPrompt,  // Optional: "Make this easier to read"
  }) async {
    if (!_isInitialised) await initialise();

    final prompt = userPrompt ?? 'What accessibility settings are shown? Generate automation.';

    final result = await _vlm!.generateFromImage(
      imagePath: screenshot.path,
      prompt: '''Analyze this settings screenshot for accessibility automation.

Identify:
1. Current accessibility settings visible
2. Toggles/sliders that can be automated
3. Relevant actions for "$mode" mode

Output JSON DSL:
{
  "trigger": "assistive_mode.on:$mode",
  "actions": [...]
}

Only output JSON.''',
    );

    // Parse VLM response to FlowDSL
    final dsl = FlowDSL.fromJsonString(result.response);
    return dsl.isValid() ? dsl : null;
  }
}
```

**UI Integration**:
- Add "Create from Screenshot" button in mode detail screen
- Allow users to share screenshot into app
- Show preview of generated flow before saving

---

### 6. � Implement Local Personalization via CactusRAG

**New File**: `lib/services/personalization_service.dart`

**Requirements**:
- Use CactusRAG for local embeddings and retrieval
- Store user preferences, past flows, daily check-ins
- Query context to personalize future flows

**Implementation**:
```dart
import 'package:cactus/cactus.dart';
import '../models/flow_dsl.dart';

class PersonalizationService {
  static final PersonalizationService _instance = PersonalizationService._internal();
  factory PersonalizationService() => _instance;
  PersonalizationService._internal();

  CactusRAG? _rag;
  bool _isInitialised = false;

  /// Initialize CactusRAG with local embeddings
  Future<void> initialise() async {
    _rag = CactusRAG();
    await _rag!.initialize(
      collectionName: 'nothflows_user_context',
      embeddingModel: 'all-minilm-l6-v2',  // Small, fast, local
    );
    _isInitialised = true;
  }

  /// Store user flow for future personalization
  Future<void> storeFlow(FlowDSL flow) async {
    if (!_isInitialised) await initialise();

    await _rag!.addDocument(
      id: flow.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: flow.getDescription(),
      metadata: {
        'trigger': flow.trigger,
        'mode': flow.trigger.split(':').last,
        'actions': flow.actions.map((a) => a.type).toList(),
        'timestamp': flow.createdAt?.toIso8601String(),
      },
    );
  }

  /// Store daily check-in response
  Future<void> storeCheckIn(String response, String sentiment) async {
    if (!_isInitialised) await initialise();

    await _rag!.addDocument(
      id: 'checkin_${DateTime.now().millisecondsSinceEpoch}',
      content: response,
      metadata: {
        'type': 'daily_checkin',
        'sentiment': sentiment,
        'date': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Query user context for personalization
  Future<String> queryUserContext(String query) async {
    if (!_isInitialised) await initialise();

    final results = await _rag!.query(
      query: query,
      limit: 5,
    );

    return results.map((r) => r.content).join('\n');
  }

  /// Get personalized suggestions for a mode
  Future<List<String>> getSuggestionsForMode(String mode) async {
    final context = await queryUserContext(
      'Show me past $mode flows and preferences',
    );

    // Use context to generate suggestions
    return [
      'Based on your history...',
      'You often use...',
    ];
  }
}
```

---

### 7. � Add Daily Check-In Flow

**New File**: `lib/screens/daily_checkin_screen.dart`

**Requirements**:
- Morning prompt: "How are you feeling today?"
- Parse response with CactusLLM
- Adjust active flows based on sentiment
- Store in CactusRAG for personalization

**Implementation**:
```dart
import 'package:flutter/material.dart';
import '../services/cactus_llm_service.dart';
import '../services/personalization_service.dart';
import '../services/storage_service.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  final _controller = TextEditingController();
  bool _isProcessing = false;

  Future<void> _processCheckIn() async {
    setState(() => _isProcessing = true);

    final response = _controller.text;

    // Analyze sentiment and needs with LLM
    final analysis = await CactusLLMService().analyzeCheckIn(response);

    // Store in RAG
    await PersonalizationService().storeCheckIn(response, analysis.sentiment);

    // Adjust flows based on sentiment
    if (analysis.suggestedMode != null) {
      await StorageService().setActiveMode(analysis.suggestedMode!);
    }

    setState(() => _isProcessing = false);

    // Navigate to home
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Check-In')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you feeling today?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tell me about any challenges or needs you have today.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'e.g., "My eyes hurt today" or "I\'m feeling anxious"',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processCheckIn,
                child: _isProcessing
                    ? const CircularProgressIndicator()
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**CactusLLM Integration**:
```dart
// Add to cactus_llm_service.dart
Future<CheckInAnalysis> analyzeCheckIn(String response) async {
  final result = await _llm!.generateCompletion(
    messages: [
      ChatMessage(role: 'system', content: 'Analyze accessibility needs from user check-in.'),
      ChatMessage(role: 'user', content: response),
    ],
  );

  // Parse: {"sentiment": "struggling", "needs": ["vision"], "suggested_mode": "vision"}
  return CheckInAnalysis.fromJson(jsonDecode(result.response));
}
```

---

### 8. � Add Sensor-Aware Triggers

**New File**: `lib/services/sensor_service.dart`

**Requirements**:
- Monitor ambient light sensor
- Monitor noise level (microphone)
- Monitor device motion (accelerometer)
- Evaluate FlowConditions against sensor data
- Trigger flows automatically when conditions match

**Implementation**:
```dart
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:light/light.dart';
import 'package:noise_meter/noise_meter.dart';
import '../models/flow_dsl.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  // Current sensor readings
  String _ambientLight = 'medium';
  String _noiseLevel = 'moderate';
  String _deviceMotion = 'still';

  /// Initialize sensor monitoring
  Future<void> startMonitoring() async {
    // Light sensor
    Light().lightSensorStream.listen((lux) {
      _ambientLight = _categorizeLight(lux);
    });

    // Noise sensor
    NoiseMeter().noiseStream.listen((noise) {
      _noiseLevel = _categorizeNoise(noise.meanDecibel);
    });

    // Motion sensor
    accelerometerEvents.listen((event) {
      final magnitude = event.x.abs() + event.y.abs() + event.z.abs();
      _deviceMotion = _categorizeMotion(magnitude);
    });
  }

  /// Check if flow conditions are met
  bool evaluateConditions(FlowConditions conditions) {
    if (conditions.ambientLight != null && conditions.ambientLight != _ambientLight) {
      return false;
    }
    if (conditions.noiseLevel != null && conditions.noiseLevel != _noiseLevel) {
      return false;
    }
    if (conditions.deviceMotion != null && conditions.deviceMotion != _deviceMotion) {
      return false;
    }
    return true;
  }

  String _categorizeLight(int lux) {
    if (lux < 50) return 'low';
    if (lux < 500) return 'medium';
    return 'high';
  }

  String _categorizeNoise(double db) {
    if (db < 50) return 'quiet';
    if (db < 70) return 'moderate';
    return 'loud';
  }

  String _categorizeMotion(double magnitude) {
    if (magnitude < 5) return 'still';
    if (magnitude < 15) return 'walking';
    return 'shaky';
  }
}
```

**Dependencies to Add** (pubspec.yaml):
```yaml
dependencies:
  sensors_plus: ^3.0.0
  light: ^3.0.0
  noise_meter: ^5.0.0
```

---

### 9. � Update UI for Accessibility Purpose

**Files to Update**:
- `lib/screens/home_screen.dart`
- `lib/screens/mode_detail_screen.dart`
- `lib/screens/permissions_screen.dart`
- `lib/main.dart`

**Changes Needed**:

**Home Screen** (`home_screen.dart`):
- Update header text: "Smart modes for Nothing Phones" → "NothFlows — Personal Automation Engine"
- Add "Daily Check-In" button
- Add "Create from Screenshot" action
- Update mode card styling for accessibility categories

**Mode Detail Screen** (`mode_detail_screen.dart`):
- Add accessibility icon badges
- Update copy: "Add a flow" � "Add an assistive routine"
- Show sensor conditions if present
- Add visual indicators for condition-based flows

**Permissions Screen** (`permissions_screen.dart`):
- Add explanation for why each permission is needed for accessibility
- Request sensor permissions (camera, microphone, light)
- Update copy to emphasize privacy and on-device processing

**Main App** (`main.dart`):
- Update splash screen tagline: "Smart modes for Nothing Phones" � "Help your phone help you"
- Add accessibility disclaimer/introduction

**Onboarding Flow** (new):
- Brief introduction to assistive modes
- Disability category selection (optional)
- Permission setup with explanations

---

### 10. � Remove Simulation Mode Fallback

**File**: `lib/services/cactus_llm_service.dart`

**Changes Required**:

**Delete Simulation Methods**:
```dart
// DELETE THIS:
Future<FlowDSL?> _simulateParse(String instruction, String mode) async { ... }

// DELETE THIS from _executeAction in automation_executor.dart:
Future<ExecutionResult> _simulateExecution(FlowAction action) async { ... }

// DELETE THIS check:
bool get _isSimulation => !Platform.isAndroid;
```

**Make Cactus Required**:
```dart
Future<FlowDSL?> parseInstruction({
  required String instruction,
  required String mode,
}) async {
  if (!isReady) {
    await initialise();
    if (!isReady) {
      throw Exception('Cactus LLM is required for NothFlows. Please ensure model is downloaded.');
    }
  }

  // NO FALLBACK - only real LLM
  final result = await _llm!.generateCompletion(messages: messages);

  if (!result.success) {
    throw Exception('Failed to parse instruction: ${result.response}');
  }

  return FlowDSL.fromJsonString(result.response);
}
```

**Update Executor**:
```dart
Future<ExecutionResult> _executeAction(FlowAction action) async {
  // NO SIMULATION CHECK - fail if not on Android
  if (!Platform.isAndroid) {
    throw UnsupportedError('NothFlows requires Android');
  }

  // Execute real actions only
  switch (action.type) { ... }
}
```

---

## =� Progress Summary

| Task | Status | Files Modified | Lines Changed | Complexity |
|------|--------|----------------|---------------|------------|
| 1. Assistive Modes |  Complete | 1 | ~100 | Low |
| 2. DSL Schema |  Complete | 1 | ~150 | Medium |
| 3. Accessibility Actions | � Pending | 2 | ~500 | High |
| 4. CactusLLM Planner | � Pending | 1 | ~300 | High |
| 5. SmolVLM Screenshot Parser | � Pending | 1 (new) | ~150 | Medium |
| 6. CactusRAG Personalization | � Pending | 1 (new) | ~200 | Medium |
| 7. Daily Check-In | � Pending | 1 (new) | ~150 | Low |
| 8. Sensor Triggers | � Pending | 1 (new) | ~200 | Medium |
| 9. UI Updates | � Pending | 4 | ~300 | Medium |
| 10. Remove Simulation | � Pending | 2 | ~50 | Low |

**Total Estimated Changes**: ~2,000 lines across 10 files (6 new files)

---

## =' Dependencies to Add

**pubspec.yaml additions needed**:
```yaml
dependencies:
  # Existing
  cactus: ^1.0.2  # Already added

  # New for sensors
  sensors_plus: ^3.0.0
  light: ^3.0.0
  noise_meter: ^5.0.0

  # For screenshot handling
  image_picker: ^1.0.0
  image: ^4.0.0
```

---

## <� Design System Updates

**Colour Palette** (Nothing OS inspired):
- Vision Assist: `#4D9FFF` (Blue)
- Motor Assist: `#9F4DFF` (Purple)
- Neurodivergent Focus: `#FF4D9F` (Pink)
- Calm Mode: `#4DFFB8` (Teal)
- Hearing Support: `#FFB84D` (Orange)
- Custom Assistive: `#4DFF88` (Green)

**Typography**:
- Maintain Roboto font family
- Increase minimum text sizes for accessibility
- High contrast mode support

**Icons**:
- Vision: `Icons.visibility`
- Motor: `Icons.touch_app`
- Neurodivergent: `Icons.psychology`
- Calm: `Icons.self_improvement`
- Hearing: `Icons.hearing`
- Custom: `Icons.accessibility_new`

---

## >� Testing Strategy

**Unit Tests Needed**:
- FlowConditions parsing and validation
- New action type validation in FlowDSL
- Sensor categorization logic
- CactusRAG storage and retrieval

**Integration Tests**:
- End-to-end flow creation from screenshot
- Daily check-in � mode activation
- Sensor trigger � automatic flow execution
- CactusLLM multi-step planning

**Manual Testing**:
- Accessibility features on real device
- Screen reader compatibility
- High contrast mode
- Large text support
- Motor gesture alternatives

---

## =� Documentation Updates Needed

- Update README.md with accessibility focus
- Add ACCESSIBILITY.md guide
- Document all new action types
- Add examples for each assistive mode
- Privacy policy for sensor data (all local, none uploaded)

---

## =� Deployment Checklist

- [ ] Complete all 10 tasks
- [ ] Test on Nothing Phone with all assistive modes
- [ ] Verify Cactus models download correctly
- [ ] Test offline functionality
- [ ] Verify no cloud dependencies
- [ ] Accessibility audit with screen readers
- [ ] Performance test with sensor monitoring
- [ ] Battery impact assessment
- [ ] Update app description for accessibility focus
- [ ] Submit to Play Store with accessibility tags

---

## =� Key Principles

1. **Privacy First**: All AI runs on-device, no cloud
2. **Cactus Required**: No simulation fallback for core features
3. **Accessibility First**: Every feature designed for disabled users
4. **Context-Aware**: Sensors and personalization drive automation
5. **Multi-Modal**: Text + Vision + Voice + Sensors
6. **NothingOS Aesthetic**: Maintain visual design language

---

**Next Steps**: Continue with Task 3 (Accessibility Actions in AutomationExecutor)

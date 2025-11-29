# NothFlows

**Your Assistive Automation Engine for Nothing Phone**

NothFlows is an on-device AI-powered accessibility automation platform designed specifically for disabled users on Nothing Phones. It transforms complex accessibility settings into simple, voice-activated automation flows using 100% local AI inference.

![NothFlows logo](assets/branding/logoBanner.png)

Instead of navigating through endless system settings, just describe what you need: "Make text huge and boost brightness" or "Mute distracting apps when I need to focus."

The app runs a local Qwen3 600M model via the Cactus SDK to parse your instructions into executable automation tasks — 100% offline. Privacy-first, no cloud dependencies, no user data leaving your device.


## Key Features

### Six Assistive Modes

NothFlows replaces generic Sleep/Focus modes with six accessibility-focused categories:

| Mode | Purpose | Target Users |
|------|---------|--------------|
| **Vision Assist** | Enhance readability | Low-vision, blind, dyslexic users |
| **Motor Assist** | Simplify interactions | Tremor, arthritis, cerebral palsy users |
| **Neurodivergent Focus** | Minimise distractions | ADHD, autism users |
| **Calm Mode** | Reduce overstimulation | Anxiety, sensory processing disorder |
| **Hearing Support** | Visual accessibility | Deaf, hard-of-hearing users |
| **Custom Assistive** | User-defined | Everyone |

### Core Capabilities

- **Wake Word Activation**: Always-on "North-Flow" wake word detection using Picovoice Porcupine
- **Smart Habit Learning**: Automatically detects usage patterns and suggests modes at the right time
- **Voice-First Interaction**: Hands-free mode activation and control via speech recognition
- **Text-to-Speech Responses**: Voice feedback for all actions and mode changes
- **App Integration**: Screen reading capability from external apps via accessibility service
- **28 Accessibility Actions**: Comprehensive action library covering vision, motor, cognitive, hearing, and system controls
- **Sensor-Aware Automation**: Context-based triggers using ambient light, device motion, and time of day
- **Natural Language Flows**: Add automations by describing what you need in plain English
- **Daily Check-In**: AI-powered wellness tracking with contextual recommendations
- **100% On-Device AI**: All inference happens locally using Cactus SDK (Qwen3 0.6B)
- **LLM Shared Memory**: Knowledge base injection for personalised AI responses
- **Privacy-First**: No cloud fallback, all data stays on your device
- **NothingOS Integration**: Deep Android accessibility service integration

## Recent Updates

### Wake Word Detection (Latest)
**Hands-free activation with custom "North-Flow" wake word:**
- **Always-on listening**: Picovoice Porcupine runs continuously in background
- **Custom wake word**: Trained specifically for "North-Flow" trigger phrase
- **Privacy-first**: All processing happens on-device, no cloud connection
- **Low battery impact**: Optimised for continuous monitoring
- **Voice response**: TTS confirms detection with "Yes?" prompt
- **Auto-启动**: Wake word detection starts automatically on app launch

### Smart Habit Learning
**Automatic pattern detection and intelligent suggestions:**
- **Learns your habits**: Tracks when you use each mode (time of day, day of week)
- **No manual setup**: Patterns detected automatically from usage history
- **Smart suggestions**: Recommends modes based on your habits ("You usually use Vision Assist around this time")
- **Feedback loop**: Learns from accepted/rejected suggestions to improve accuracy
- **Privacy-first**: All habit data stored locally in Hive database
- **LLM-powered context**: Shared knowledge base injected into AI prompts for personalised responses
- **Demo mode**: Settings → "Demo Smart Suggestion" to preview the feature instantly

### Voice Command Support & TTS Responses
**Hands-free mode activation with voice feedback:**
- **Wake word trigger**: Say "North-Flow" to activate voice listening
- **Mode activation**: "Activate Vision mode" / "Deactivate Focus"
- **Direct actions**: "Set brightness to 50", "Enable Do Not Disturb"
- **Speech recognition**: Real-time speech-to-text with confidence scoring
- **Voice responses**: TTS feedback for all actions ("Vision mode activated", "Brightness adjusted")
- **Microphone FAB**: Manual trigger button on home screen with visual feedback

### App Integration & Screen Reading
**Deep integration with external apps via accessibility service:**
- **Screen content reading**: Extracts text from any app using Android Accessibility API
- **App launching by keyword**: "Open my email app" finds and launches Gmail/Outlook
- **Context-aware suggestions**: Reads current app content and provides relevant actions
- **LLM-powered understanding**: Cactus SDK interprets app content for intelligent responses
- **Accessibility permission**: Requires one-time accessibility service enablement

### Sensor-Aware Automation
**Context-based conditional flows:**
- Accelerometer-based device motion detection (still/walking/shaky)
- Ambient light simulation (low/medium/high)
- Noise level awareness (quiet/moderate/loud)
- Flows execute only when sensor conditions match

### Daily Check-In System
**AI-powered wellness tracking:**
- Text input for describing how you're feeling
- Automatic category inference (VISION, MOTOR, HEARING, CALM, NEURODIVERGENT)
- Contextual recommendations based on inferred needs
- Personalisation service for future customisation

### Comprehensive Accessibility Actions
**28 actions across 5 categories:**
- Vision: text size, contrast, screen reader, brightness
- Motor: gesture sensitivity, voice typing, one-handed mode, touch targets
- Cognitive: animation reduction, UI simplification, app muting
- Hearing: live transcribe, captions, flash alerts, haptic feedback
- System: DND, connectivity, volume, file cleaning, app launching

## Project Structure

```
lib/
├── main.dart                           # App entry point with splash screen
├── models/
│   ├── flow_dsl.dart                  # DSL schema with 28 actions + conditions
│   ├── mode_model.dart                # 6 assistive modes with metadata
│   ├── usage_event.dart               # Mode activation tracking
│   ├── habit_pattern.dart             # Detected behaviour patterns
│   ├── user_preference.dart           # Learned preferences
│   ├── suggestion_outcome.dart        # Feedback tracking
│   └── user_knowledge_base.dart       # LLM context aggregation
├── services/
│   ├── cactus_llm_service.dart        # Qwen3 LLM integration
│   ├── wake_word_service.dart         # Porcupine "North-Flow" detection
│   ├── tts_service.dart               # Text-to-speech voice responses
│   ├── voice_command_service.dart     # Speech-to-text recognition
│   ├── app_integration_service.dart   # Screen reading & app launching
│   ├── sensor_service.dart            # Motion/light sensor monitoring
│   ├── habit_tracker_service.dart     # Usage event recording
│   ├── pattern_analyzer_service.dart  # Automatic habit detection
│   ├── recommendation_service.dart    # Smart mode suggestions
│   ├── feedback_service.dart          # Learn from user responses
│   ├── knowledge_base_service.dart    # LLM context injection
│   ├── personalization_service.dart   # Check-in logging
│   ├── storage_service.dart           # Local persistence (Hive + SharedPrefs)
│   ├── automation_executor.dart       # Flow execution with Android integration
│   └── permission_service.dart        # Runtime permission management
├── screens/
│   ├── home_screen.dart               # Dashboard with wake word & voice FAB
│   ├── mode_detail_screen.dart        # Flow management with conditions
│   ├── daily_checkin_screen.dart      # Wellness check-in UI
│   ├── permissions_screen.dart        # Permission request flow
│   ├── splash_screen.dart             # App launch screen
│   ├── flow_preview_sheet.dart        # Flow preview bottom sheet
│   └── results_sheet.dart             # Execution results feedback
├── widgets/
│   ├── noth_card.dart                 # NothingOS mode card
│   ├── noth_chip.dart                 # Category badges
│   ├── noth_button.dart               # Custom buttons
│   ├── noth_toggle.dart               # Mode toggle switches
│   ├── noth_panel.dart                # Glass panel container
│   ├── noth_toast.dart                # Toast notifications
│   ├── suggestion_card.dart           # Smart suggestion UI
│   └── suggestion_indicator.dart      # Visual indicators
└── theme/
    ├── nothflows_colors.dart          # Nothing-inspired colour palette
    ├── nothflows_typography.dart      # Text styles
    ├── nothflows_shapes.dart          # Border radius & shapes
    ├── nothflows_spacing.dart         # Layout spacing
    └── nothflows_theme.dart           # Theme configuration
```

## DSL Schema

The app uses a JSON-based DSL for automation flows with optional sensor conditions:

```json
{
  "trigger": "mode.on:vision",
  "conditions": {
    "ambient_light": "low",
    "device_motion": "still",
    "noise_level": "quiet"
  },
  "actions": [
    { "type": "increase_text_size", "to": "large" },
    { "type": "increase_contrast" },
    { "type": "boost_brightness", "to": 100 }
  ]
}
```

### Supported Actions (28 Total)

#### Vision Accessibility (5 actions)
| Action Type | Parameters | Description |
|------------|------------|-------------|
| `increase_text_size` | `to: small/medium/large/max` | Adjust system text size |
| `increase_contrast` | - | Enable high contrast mode |
| `enable_high_visibility` | - | Enable high visibility features |
| `enable_screen_reader` | - | Activate TalkBack screen reader |
| `boost_brightness` | `to: 0-100` | Set screen brightness |

#### Motor Accessibility (4 actions)
| Action Type | Parameters | Description |
|------------|------------|-------------|
| `reduce_gesture_sensitivity` | - | Lower touch sensitivity for tremors |
| `enable_voice_typing` | - | Activate voice input |
| `enable_one_handed_mode` | - | Shrink UI for one-hand use |
| `increase_touch_targets` | - | Enlarge interactive elements |

#### Cognitive/Neurodivergent (4 actions)
| Action Type | Parameters | Description |
|------------|------------|-------------|
| `reduce_animation` | - | Minimise motion and transitions |
| `simplify_home_screen` | - | Reduce visual complexity |
| `mute_distraction_apps` | - | Disable notifications from distracting apps |
| `highlight_focus_apps` | - | Emphasise productivity apps |

#### Hearing Accessibility (4 actions)
| Action Type | Parameters | Description |
|------------|------------|-------------|
| `enable_live_transcribe` | - | Real-time speech-to-text |
| `enable_captions` | - | System-wide captions |
| `flash_screen_alerts` | - | Visual notifications |
| `boost_haptic_feedback` | `strength: light/medium/strong` | Increase vibration intensity |

#### System Actions (10 actions)
| Action Type | Parameters | Description |
|------------|------------|-------------|
| `lower_brightness` | `to: 0-100` | Reduce screen brightness |
| `set_volume` | `level: 0-100` | Adjust system volume |
| `enable_dnd` | - | Enable Do Not Disturb |
| `disable_wifi` | - | Turn off Wi-Fi |
| `disable_bluetooth` | - | Turn off Bluetooth |
| `clean_screenshots` | `older_than_days` | Delete old screenshots |
| `clean_downloads` | `older_than_days` | Delete old downloads |
| `mute_apps` | `apps: [array]` | Mute specific app notifications |
| `launch_app` | `app: string` | Open an application |
| `launch_care_app` | - | Open emergency contact/care app |

### Sensor Conditions

Flows can include optional conditions that must be met before execution:

| Condition | Values | Description |
|-----------|--------|-------------|
| `ambient_light` | `low/medium/high` | Light level detection |
| `device_motion` | `still/walking/shaky` | Accelerometer-based motion |
| `noise_level` | `quiet/moderate/loud` | Audio environment (future) |
| `time_of_day` | `morning/afternoon/evening/night` | Time-based triggers |
| `battery_level` | `0-100` | Battery percentage threshold |
| `is_charging` | `true/false` | Charging status |

## Smart Habit Learning

NothFlows learns your usage patterns and makes intelligent suggestions without any manual setup.

### How It Works

1. **Usage Tracking**: Every mode activation/deactivation is recorded with context (time, day, ambient conditions)
2. **Pattern Detection**: After 10+ events, the system analyzes your habits:
   - Time-based patterns: "Uses Vision Assist every evening"
   - Day-based patterns: "Uses Focus Mode on weekdays"
   - Sequence patterns: "Uses Calm Mode after Motor Assist"
3. **Smart Suggestions**: When context matches a detected pattern, a suggestion card appears
4. **Feedback Loop**: Accept/dismiss/block responses adjust pattern confidence

### Suggestion Card

When a suggestion appears:
- **Tap to expand** for more details ("Why this suggestion?")
- **Activate**: Accepts suggestion and activates the mode
- **Not now**: Dismisses temporarily (slight confidence decrease)
- **Don't suggest**: Permanently blocks this pattern

### LLM Context Injection

The habit system provides a "shared memory" for the local LLM:
```dart
// Knowledge base generates context like:
// - Frequently uses: Vision mode (12x), Calm mode (8x)
// - Pattern: You often use Vision mode in the evening
// - Prefers reminder-style suggestions
// - Suggestion acceptance rate: 75%
```

This context is injected into LLM prompts for more personalised AI responses.

### Demo Mode

To preview the suggestion UI without waiting for patterns:
1. Open **Settings** (gear icon)
2. Tap **"Demo Smart Suggestion"**
3. A sample suggestion card appears immediately

## Wake Word Detection

NothFlows features always-on wake word detection using Picovoice Porcupine with a custom-trained "North-Flow" wake word.

### How It Works

1. **Background monitoring**: Porcupine runs continuously, listening for the wake word
2. **Wake word detected**: When you say "North-Flow", the app responds with "Yes?" via TTS
3. **Voice command mode**: Microphone activates for 30 seconds to listen for your command
4. **Command execution**: Recognized commands are executed and confirmed with voice feedback

### Privacy & Performance

- **100% on-device**: All wake word detection happens locally using Picovoice Porcupine
- **No cloud connection**: Wake word model stored in assets, never transmitted
- **Low battery impact**: Optimised algorithm runs efficiently in background
- **Custom wake word**: Trained specifically for "North-Flow" for accurate recognition
- **Auto-start**: Wake word detection begins automatically on app launch

### Wake Word Model

The custom wake word model is located at `assets/wake_words/North-Flow_en_android_v3_0_0.ppn` and uses Picovoice's Porcupine v3.0 engine.

## Voice Commands

The app supports hands-free operation via speech recognition:

### Mode Activation Commands
- "Activate Vision mode" / "Switch to Motor mode"
- "Deactivate Focus" / "Turn off Calm mode"
- Recognises keywords: vision, motor, hearing, calm, neurodivergent

### Direct Action Commands
- **Brightness**: "Set brightness to 75"
- **Volume**: "Mute" or "Volume to 50"
- **DND**: "Enable Do Not Disturb" / "Silence"
- **Screenshots**: "Clean old screenshots" / "Delete screenshots 30 days old"
- **Connectivity**: "Turn off Wi-Fi" / "Disable Bluetooth"

### Implementation Details
- **Wake word**: Picovoice Porcupine with custom "North-Flow" model
- **Speech recognition**: `speech_to_text` Flutter plugin
- **TTS responses**: `flutter_tts` for voice feedback
- **Listening timeout**: 30 seconds with 3-second pause detection
- **Real-time display**: Partial results shown during recording
- **Confidence scoring**: Each recognition includes accuracy percentage
- **Manual trigger**: Microphone FAB button on home screen

## App Integration & Screen Reading

NothFlows can read content from external apps and provide intelligent assistance using Android Accessibility Services.

### Capabilities

- **Screen content extraction**: Reads visible text from any app using Accessibility API
- **Smart app launching**: Natural language app search and launch
  - "Open my email app" → Finds and launches Gmail/Outlook
  - "Launch my music app" → Detects Spotify/YouTube Music
- **Context-aware AI**: LLM interprets app content for intelligent responses
- **Cross-app automation**: Trigger flows based on content in external apps

### Setup

1. **Enable accessibility service**: App requests permission on first use
2. **Grant access**: Go to Settings → Accessibility → NothFlows → Enable
3. **Voice integration**: Use wake word or voice commands to interact with apps
4. **Privacy**: All screen content processing happens on-device with Qwen3 LLM

### Example Use Cases

- **Email reading**: "Read my latest email" → Extracts Gmail inbox content
- **Weather check**: "What's the weather?" → Reads weather app information
- **Navigation assist**: "Where am I going?" → Reads Google Maps directions
- **App switching**: "Open calculator" → Launches calculator app

## Cactus SDK Integration

### Model Configuration

- **Language Model**: Qwen3 0.6B (quantised to Q4_0)
- **Download**: One-time from Supabase (~500MB)
- **Storage**: Cached locally on device forever
- **Inference**: 100% on-device, no internet required after download
- **Context Length**: 2048 tokens
- **Threads**: 4 (optimised for Nothing Phone hardware)
- **Temperature**: 0.3 (for consistent JSON output)

**How It Works:**
1. **First Run**: Downloads model from Supabase (requires internet once)
2. **Cached Forever**: Model stored at `/data/user/0/com.nothflows/app_flutter/models/`
3. **Fully Offline**: All subsequent runs use cached model, no internet needed
4. **Privacy-First**: After download, all AI inference happens locally on your device

### Usage Examples

```dart
final llmService = CactusLLMService();

// Initialise the model
await llmService.initialise();

// Parse natural language instruction into DSL
final flow = await llmService.parseInstruction(
  instruction: 'Make text huge and boost brightness when light is low',
  mode: 'vision',
);

// Infer accessibility category from check-in
final category = await llmService.inferCategoryFromCheckin(
  checkinText: 'My hands are shaking today, hard to tap small buttons',
);
// Returns: MOTOR
```

## Running the App

### Android (Real Device / Emulator)

This runs the full app with on-device AI on Nothing Phone or Android emulator.

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Connect device and run**:
   ```bash
   flutter run
   ```

3. **Permissions**:
   The app will request the following permissions on first run:
   - `MANAGE_EXTERNAL_STORAGE` - For cleaning files
   - `WRITE_SETTINGS` - For brightness/system control
   - `RECORD_AUDIO` - For wake word detection & voice commands
   - `ACCESSIBILITY_SERVICE` - For app integration & screen reading
   - `INTERNET` - **Only needed on first run** to download Qwen3 model

4. **First run**:
   - Qwen3 model (~500MB) downloads from Supabase automatically
   - Takes 2-5 minutes depending on connection speed
   - Model cached permanently at `/data/user/0/com.nothflows/app_flutter/models/`
   - After this, **app works 100% offline** - no internet needed!

### Simulation Mode (macOS / Windows)

Test UI and logic without Android device or AI model:

```bash
flutter run -d macos
```

*Note: Voice commands, sensor detection, and Android-specific actions will use mock implementations.*

## User Journeys

### Vision Assist User
1. User opens app → grants storage/settings/microphone/accessibility permissions
2. Says "North-Flow" → Wake word detected, app responds "Yes?"
3. User says: "Make text large and boost brightness"
4. Cactus LLM parses instruction → generates DSL with two actions
5. Automation Executor runs actions on device
6. TTS confirms: "Text size increased. Brightness boosted to maximum."
7. Results shown: ✓ Text size increased, ✓ Brightness boosted to 100%

### Motor Assist User
1. Uses daily check-in: "My hands are shaking today"
2. System infers: MOTOR category
3. Recommends: "Try Motor Assist mode"
4. User activates voice command: "Enable voice typing"
5. Gesture sensitivity reduced, voice typing activated

### Neurodivergent User (ADHD)
1. Creates custom flow: "When I need to focus, mute Instagram and TikTok"
2. Voice command: "Activate Focus mode"
3. Sensor conditions checked: Light is low (afternoon), motion is still
4. If conditions match, flow executes → apps muted
5. Home screen shows focus badge with conditions: "Light: low, Motion: still"

## Architecture Decisions

### 1. Accessibility-First Design

Every feature prioritises disabled users:
- **Voice-first interaction**: Hands-free operation for motor-impaired users
- **Sensor-aware context**: Flows adapt to ambient conditions
- **Six assistive modes**: Targeted support for diverse disabilities
- **28 accessibility actions**: Comprehensive coverage of common needs

### 2. Privacy-First AI

All AI inference happens on-device using Cactus SDK:
- **No cloud fallback**: 100% local processing
- **No data transmission**: Everything stays on device
- **Offline-capable**: Full functionality without internet (after first run)
- **Quantised models**: Q4_0 optimisation for mobile performance

### 3. DSL-Based Flows

JSON DSL with validation:
- **Type-safe definitions**: Validated action schemas
- **Sensor conditions**: Optional context-based triggers
- **Extensible**: Easy to add new actions and conditions
- **Human-readable**: Clear description generation for accessibility

### 4. NothingOS Aesthetic

Design follows Nothing's principles with accessibility enhancements:
- **Roboto font**: Standard typeface for better readability
- **High contrast**: Black (#1A1A1A), White, Nothing Red (#D71921)
- **Minimalist UI**: Reduced visual complexity for cognitive accessibility
- **Large touch targets**: 48x48 dp minimum for motor accessibility
- **Semantic labels**: Full screen reader support

### 5. Service Layer Architecture

Singleton services for consistency:
- **Single LLM instance**: Model loaded once, shared globally
- **Sensor monitoring**: Real-time context awareness
- **Voice recognition**: Persistent speech-to-text service
- **Storage abstraction**: Hive + SharedPreferences for persistence

## Example Flows

### Vision Assist Mode

```
"Make text huge and boost brightness when light is low"
→ {
    trigger: "mode.on:vision",
    conditions: { ambient_light: "low" },
    actions: [
      { type: "increase_text_size", to: "large" },
      { type: "boost_brightness", to: 100 },
      { type: "increase_contrast" }
    ]
  }
```

### Motor Assist Mode

```
"Enable voice typing and reduce sensitivity when hands are shaky"
→ {
    trigger: "mode.on:motor",
    conditions: { device_motion: "shaky" },
    actions: [
      { type: "enable_voice_typing" },
      { type: "reduce_gesture_sensitivity" },
      { type: "increase_touch_targets" }
    ]
  }
```

### Neurodivergent Focus Mode

```
"Mute Instagram and TikTok, reduce animations, launch Notion"
→ {
    trigger: "mode.on:neurodivergent",
    actions: [
      { type: "mute_apps", apps: ["Instagram", "TikTok"] },
      { type: "reduce_animation" },
      { type: "launch_app", app: "Notion" }
    ]
  }
```

### Calm Mode

```
"Lower brightness to 20%, enable DND, reduce volume when it's evening"
→ {
    trigger: "mode.on:calm",
    conditions: { time_of_day: "evening" },
    actions: [
      { type: "lower_brightness", to: 20 },
      { type: "enable_dnd" },
      { type: "set_volume", level: 30 }
    ]
  }
```

## Future Enhancements

### Phase 2: Advanced Automations
- [ ] Time-based triggers (e.g., "9 AM weekdays")
- [ ] Location-based triggers (e.g., "At home")
- [ ] Conditional branching (if/then logic)
- [ ] Flow chaining (flow → triggers another flow)

### Phase 3: Community & Personalisation
- [ ] Flow sharing with other users
- [ ] Community flow marketplace
- [ ] Template library for common disabilities
- [ ] CactusRAG personalisation
- [ ] Local usage analytics (privacy-preserving)

## Development Notes

### Adding New Accessibility Actions

1. **Define action type** in `FlowDSL.isValid()` (`lib/models/flow_dsl.dart`)
2. **Implement execution** in `AutomationExecutor._executeAction()` (`lib/services/automation_executor.dart`)
3. **Add description logic** to `FlowDSL.getDescription()` for screen reader support
4. **Update LLM system prompt** in `CactusLLMService` with new action type
5. **Add Android native method** if required in `MainActivity.kt`

### Testing Voice Commands

```dart
final voiceService = VoiceCommandService();
voiceService.startListening(
  onResult: (command) => print('Recognized: $command'),
  onError: (error) => print('Error: $error'),
);
```

### Testing Sensor Conditions

```dart
final sensorService = SensorService();
await sensorService.initialize();
final conditions = sensorService.getCurrentConditions();
print('Light: ${conditions.ambientLight}, Motion: ${conditions.deviceMotion}');
```

### Debugging Flows

The `FlowDSL` class includes a `getDescription()` method for human-readable output:

```dart
print(flow.getDescription());
// Output:
// When vision mode is activated (Triggers when Light: low, Motion: still):
//   • Increase text size to large
//   • Enable high contrast mode
//   • Boost brightness to 100%
```

### Building APK

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

## Performance Optimisations

1. **Model Caching**: Qwen3 model (~500MB) cached after first download
2. **Lazy Loading**: LLM initialised on first use, not at startup
3. **Low Temperature**: 0.3 for consistent JSON output
4. **Quantisation**: Q4_0 reduces model size from ~700MB to ~200MB
5. **Thread Pool**: 4 threads for optimal inference speed on mobile
6. **Singleton Services**: Single LLM instance shared globally
7. **Sensor Throttling**: Motion/light updates at reasonable intervals

## Technology Stack

- **Framework**: Flutter (Dart)
- **AI/ML**: Cactus SDK (Qwen3 0.6B, quantised to Q4_0)
- **Wake Word Detection**: Picovoice Porcupine v3.0 with custom "North-Flow" model
- **Speech Recognition**: speech_to_text ^7.0.0
- **Text-to-Speech**: flutter_tts ^4.2.0
- **App Integration**: device_apps ^2.2.0 + Android Accessibility Services
- **Sensors**: sensors_plus ^7.0.0
- **Storage**: Hive ^2.2.3 + SharedPreferences ^2.2.2
- **Permissions**: permission_handler ^12.0.1
- **Native Android**: Kotlin 2.0.0 + Android Gradle Plugin 8.5.0

## Known Limitations

1. **First Run**: One-time model download requires internet (~500MB, then fully offline)
2. **Parsing Accuracy**: Complex instructions may need rephrasing
3. **System Permissions**: Some actions require elevated Android permissions (e.g., animation scale)
4. **Android 10+**: Wi-Fi/Bluetooth toggle requires user confirmation
5. **Non-Android Platforms**: Simulation mode only (no real automation)

## Accessibility Compliance

NothFlows is designed with accessibility best practices:

- **WCAG 2.1 AA Compliance**: High contrast ratios, large touch targets
- **Screen Reader Support**: Full TalkBack compatibility with semantic labels
- **Voice-First Design**: Complete hands-free operation capability
- **Keyboard Navigation**: All functions accessible without touch
- **Reduced Motion**: Respects system animation preferences
- **Haptic Feedback**: Tactile confirmation for all interactions

## Credits

Built for Nothing users by **Team Lotus**

**Licence**: MIT

**Privacy Policy**: All data stays on your device. No cloud, no tracking, no telemetry.

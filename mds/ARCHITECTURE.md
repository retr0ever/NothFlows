# NothFlows Architecture

## Complete Project Structure

```
NothFlows/
├── lib/
│   ├── main.dart                       # Entry point & splash screen
│   │
│   ├── models/                         # Data models
│   │   ├── flow_dsl.dart              # DSL schema, validation, parsing
│   │   └── mode_model.dart            # Mode data structure
│   │
│   ├── services/                       # Business logic layer
│   │   ├── cactus_llm_service.dart   # Qwen3 LLM integration
│   │   ├── storage_service.dart       # SharedPreferences persistence
│   │   └── automation_executor.dart   # Flow execution engine
│   │
│   ├── screens/                        # Full-screen views
│   │   ├── home_screen.dart           # Mode cards grid
│   │   ├── mode_detail_screen.dart   # Flow management
│   │   ├── flow_preview_sheet.dart   # Flow confirmation modal
│   │   └── results_sheet.dart         # Execution results modal
│   │
│   └── widgets/                        # Reusable UI components
│       ├── glass_panel.dart           # Glassmorphic container
│       ├── mode_card.dart             # Mode display card
│       └── flow_tile.dart             # Flow list item
│
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml         # Permissions configuration
│
├── assets/
│   ├── icons/                          # App icons (to be added)
│   └── models/                         # Cached LLM models
│
├── pubspec.yaml                        # Dependencies
├── analysis_options.yaml               # Linter rules
├── .gitignore                          # Git exclusions
├── README.md                           # Main documentation
└── ARCHITECTURE.md                     # This file
```

## Layer Architecture

### 1. Presentation Layer (UI)

**Screens**
- `HomeScreen`: Displays mode cards, handles mode toggling
- `ModeDetailScreen`: Manages flows, natural language input
- `FlowPreviewSheet`: Shows parsed DSL before confirmation
- `ResultsSheet`: Displays execution results

**Widgets**
- `GlassPanel`: Reusable glassmorphic container
- `ModeCard`: Mode display with icon, description, toggle
- `FlowTile`: Compact flow representation

### 2. Business Logic Layer (Services)

**CactusLLMService**
- Singleton pattern
- Initialises Qwen3 600M model
- Parses natural language → DSL
- Enforces JSON schema via system prompt

**StorageService**
- Singleton pattern
- SharedPreferences wrapper
- Manages modes and flows
- Handles active mode state

**AutomationExecutor**
- Singleton pattern
- Executes FlowDSL actions
- Returns ExecutionResult for each action
- Handles Android permissions

### 3. Data Layer (Models)

**FlowDSL**
- Immutable data class
- JSON serialisation/deserialisation
- Validation logic
- Human-readable descriptions

**ModeModel**
- Immutable data class
- Predefined Sleep/Focus/Custom modes
- Flow collection
- Activation state tracking

## Data Flow

### Adding a Flow

```
User Input (Natural Language)
    ↓
ModeDetailScreen._addFlow()
    ↓
CactusLLMService.parseInstruction()
    ↓
Qwen3 Model Inference (Local)
    ↓
FlowDSL.fromJsonString()
    ↓
FlowDSL.isValid() → Validation
    ↓
FlowPreviewSheet (User Confirmation)
    ↓
StorageService.addFlowToMode()
    ↓
SharedPreferences.setString()
```

### Toggling a Mode

```
User Taps Toggle Switch
    ↓
HomeScreen._toggleMode()
    ↓
StorageService.toggleMode()
    ↓
if activating:
    ↓
    for each flow in mode.flows:
        ↓
        AutomationExecutor.executeFlow()
        ↓
        for each action in flow.actions:
            ↓
            AutomationExecutor._executeAction()
            ↓
            Platform-Specific Code
            ↓
            ExecutionResult
```

## Key Design Patterns

### 1. Singleton Services

All services use the singleton pattern to ensure:
- Single model instance (expensive to load)
- Consistent storage state
- Shared executor context

```dart
class CactusLLMService {
  static final CactusLLMService _instance = CactusLLMService._internal();
  factory CactusLLMService() => _instance;
  CactusLLMService._internal();
}
```

### 2. Immutable Models

FlowDSL and ModeModel are immutable with copyWith methods:

```dart
ModeModel addFlow(FlowDSL flow) {
  return copyWith(flows: [...flows, flow]);
}
```

### 3. Builder Pattern (UI)

Complex UI built compositionally:

```dart
GlassPanel(
  child: Column(
    children: [
      Header(),
      Content(),
      Actions(),
    ],
  ),
)
```

### 4. Strategy Pattern (Execution)

Different action types handled via switch-case strategy:

```dart
Future<ExecutionResult> _executeAction(FlowAction action) {
  switch (action.type) {
    case 'clean_screenshots': return _cleanScreenshots();
    case 'lower_brightness': return _setBrightness();
    // ...
  }
}
```

## Cactus SDK Integration Details

### Model Configuration

```dart
_llm = await CactusLLM.create(
  modelConfig: ModelConfig(
    modelName: 'qwen3-600m',
    localOnly: true,              // No cloud fallback
    quantisation: QuantisationType.q4_0,
    contextLength: 2048,
    numThreads: 4,                // Optimised for mobile
    useMlock: false,              // Reduce memory pressure
  ),
);
```

### Inference Parameters

```dart
final response = await _llm.generate(
  prompt: userPrompt,
  systemPrompt: systemPrompt,
  maxTokens: 512,
  temperature: 0.3,               // Low for consistent JSON
  stopSequences: ['}'],           // Stop at JSON end
  stream: false,
);
```

### System Prompt Strategy

The system prompt uses:
1. **Role definition**: "You are a JSON DSL generator"
2. **Output format**: Explicit schema with examples
3. **Constraints**: "Output ONLY valid JSON"
4. **Error handling**: "Return empty actions array if unclear"

This enforces reliable JSON output even from a 600M model.

## State Management

### No External State Library

The app uses StatefulWidget for local state because:
- Small app scope (3 screens)
- Simple data flow
- No complex shared state
- Singletons handle global state

### State Sources

1. **UI State**: StatefulWidget (loading, processing)
2. **Persistent State**: StorageService (modes, flows)
3. **Session State**: CactusLLMService (model loaded)
4. **Transient State**: Navigation parameters

## Performance Optimisations

### 1. Lazy Loading

LLM initialised on first use, not at startup:

```dart
Future<void> _initialiseLLM() async {
  if (_llmService.isReady) return;  // Skip if already loaded
  await _llmService.initialise();
}
```

### 2. Model Caching

Qwen3 model cached in app directory after first download:

```dart
cacheDir: null,  // Uses default cache location
```

### 3. Quantisation

Q4_0 quantisation reduces model size:
- Original: ~2GB
- Quantised: ~500MB
- Speed: 3-4x faster on mobile

### 4. Thread Pooling

4 threads optimised for typical mobile processors:

```dart
numThreads: 4,
```

### 5. Efficient UI

- GlassPanel uses BackdropFilter sparingly
- ListView instead of Column for long lists
- const constructors where possible

## Error Handling

### LLM Errors

```dart
try {
  final dsl = await _llmService.parseInstruction(...);
  if (dsl == null) {
    _showSnackBar('Could not parse instruction. Try rephrasing.');
    return;
  }
} catch (e) {
  _showSnackBar('Error adding flow: $e');
}
```

### Storage Errors

```dart
try {
  final modes = await _storage.getModes();
} catch (e) {
  debugPrint('Error loading modes: $e');
  return [];  // Graceful fallback
}
```

### Execution Errors

```dart
return ExecutionResult(
  actionType: action.type,
  success: false,
  message: e.toString(),
);
```

All errors are non-fatal and provide user feedback.

## Testing Strategy

### Unit Tests (To Be Added)

```dart
test('FlowDSL.isValid() validates trigger format', () {
  final validDsl = FlowDSL(
    trigger: 'mode.on:sleep',
    actions: [/* ... */],
  );
  expect(validDsl.isValid(), true);
});
```

### Integration Tests (To Be Added)

```dart
testWidgets('Adding a flow updates mode', (tester) async {
  // Pump ModeDetailScreen
  // Enter natural language text
  // Tap submit
  // Verify flow appears in list
});
```

### Manual Testing

Current testing approach:
1. Install on Nothing Phone
2. Grant all permissions
3. Test each action type
4. Verify LLM parsing accuracy
5. Check UI on dark theme

## Future Extensibility

### Adding New Actions

**Step 1**: Add to validation
```dart
// lib/models/flow_dsl.dart:44
final validActionTypes = {
  'clean_screenshots',
  'your_new_action',  // Add here
};
```

**Step 2**: Implement executor
```dart
// lib/services/automation_executor.dart:51
case 'your_new_action':
  return await _yourNewAction(action.parameters);
```

**Step 3**: Update system prompt
```dart
// lib/services/cactus_llm_service.dart:19
- your_new_action: param_name (type)
```

**Step 4**: Add description
```dart
// lib/models/flow_dsl.dart:83
case 'your_new_action':
  buffer.writeln('Your action description');
```

### Adding SmolVLM

Structure already prepared:

```dart
import 'package:cactus_vlm/cactus_vlm.dart';

class CactusVLMService {
  CactusVLM? _vlm;

  Future<String> analyseScreenshot(String imagePath) async {
    // Extract app names from screenshot
    // Suggest relevant flows
  }
}
```

## Security Considerations

### 1. Local-Only AI

No data transmitted to external servers:
- Model runs entirely on-device
- No API keys required
- No telemetry

### 2. Permission Scoping

Only request permissions when needed:

```dart
final status = await Permission.manageExternalStorage.request();
if (!status.isGranted) {
  return ExecutionResult(success: false, message: 'Permission denied');
}
```

### 3. Input Validation

All FlowDSL validated before execution:

```dart
if (!dsl.isValid()) {
  debugPrint('[CactusLLM] Generated invalid DSL');
  return null;
}
```

### 4. Safe Defaults

Actions fail safely if parameters missing:

```dart
final days = params['older_than_days'] as int? ?? 30;  // Safe default
```

## Deployment Checklist

- [ ] Test on Nothing Phone 2
- [ ] Verify model caching works
- [ ] Test all action types with permissions
- [ ] Optimise release build size
- [ ] Add proper app icon
- [ ] Test dark/light theme
- [ ] Verify LLM parsing accuracy (>80%)
- [ ] Create demo video
- [ ] Write user guide
- [ ] Set up CI/CD for builds

## Known Issues & TODOs

### Current Limitations

1. **Model Download**: First run requires internet (500MB download)
2. **Parsing Accuracy**: Complex instructions may fail (~70-80% success rate)
3. **Android Restrictions**: Some actions require user interaction on Android 10+

### Planned Improvements

1. Bundle quantised model with APK (increase initial size but no download)
2. Add retry mechanism for failed parses with prompt refinement
3. Implement alternative execution paths for restricted actions
4. Add flow templates to bypass LLM entirely
5. Create flow sharing/import feature

## Performance Benchmarks

Target metrics (Nothing Phone 2):

- **Model Load Time**: < 3 seconds
- **Inference Time**: < 2 seconds per flow
- **UI Responsiveness**: 60 FPS
- **App Size**: < 50MB (excluding model)
- **Memory Usage**: < 500MB with model loaded

Actual metrics to be measured after deployment.

---

Last Updated: 2025-01-XX
Version: 1.0.0

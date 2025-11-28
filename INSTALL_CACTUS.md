# Installing Cactus SDK - CORRECT GUIDE

## ✅ Updated for Cactus v1.0.2 (Latest)

### Step 1: Install Dependencies

```bash
cd /Users/selin/Desktop/NothFlows/Code
flutter pub get
```

This will install **Cactus v1.0.2** from pub.dev.

### Step 2: Run the App

```bash
flutter run --release
```

### Step 3: First-Time Model Download

When you create your first flow, Cactus will automatically download the Qwen3-0.6B model.

**What happens:**
1. You type an instruction (e.g., "Clean screenshots")
2. App shows "Loading AI model... This may take a moment."
3. Model downloads (~400MB) - **requires internet**
4. Model caches on device
5. Inference runs (~2-3 seconds)
6. All future uses work **offline**

## 🎯 Correct API Usage

The code now uses the **real Cactus v1.0.2 API**:

### Initialization

```dart
final llm = CactusLM();

// Download model (automatic caching)
await llm.downloadModel(model: 'qwen3-0.6');

// Load into memory
await llm.initializeModel();
```

### Chat Completion

```dart
final messages = [
  ChatMessage(role: 'system', content: 'You are a helpful assistant.'),
  ChatMessage(role: 'user', content: 'What is 2+2?'),
];

final result = await llm.generateCompletion(messages: messages);

if (result.success) {
  print(result.response); // "4"
}
```

### Cleanup

```dart
llm.unload();
```

## 📦 What Changed

| Before (Incorrect) | After (Correct) |
|-------------------|----------------|
| `cactus: ^0.3.0` | `cactus: ^1.0.2` ✅ |
| `CactusLLM.create()` | `CactusLM()` ✅ |
| `.generate()` | `.generateCompletion()` ✅ |
| Model config object | `downloadModel(model: 'qwen3-0.6')` ✅ |
| `.dispose()` | `.unload()` ✅ |

## 🚀 Complete Installation Process

```bash
# 1. Navigate to project
cd /Users/selin/Desktop/NothFlows/Code

# 2. Clean previous builds
flutter clean

# 3. Install dependencies
flutter pub get

# 4. Verify Cactus installed
flutter pub deps | grep cactus
# Should show: |-- cactus 1.0.2

# 5. Run on device
flutter run --release
```

## 🎬 First Run Experience

### Timeline

1. **App launches** (2s)
   - Splash screen
   - Storage initialization

2. **Navigate to mode detail** (tap Sleep Mode)

3. **Type first instruction**
   - "Clean screenshots older than 30 days"
   - Tap submit

4. **Model downloads** (30-60s, first time only)
   - Shows: "Loading AI model... This may take a moment."
   - ~400MB download
   - Cached in app storage

5. **Model loads** (3-5s, first time)
   - Loads into memory

6. **Inference runs** (2-3s)
   - Parses instruction → DSL
   - Shows preview sheet

7. **Subsequent flows** (<1s)
   - No download
   - Fast inference

### Monitor Progress

```bash
# Watch logs
flutter logs | grep -i "cactus"
```

Expected output:
```
[CactusLLM] Initialising Qwen3 0.6B model...
[CactusLLM] Downloading model (if needed)...
[Cactus] Downloading qwen3-0.6...
[CactusLLM] Loading model into memory...
[CactusLLM] Model loaded successfully
[CactusLLM] Parsing instruction: Clean screenshots older than 30 days
[CactusLLM] Raw response: {"trigger":"mode.on:sleep","actions":[...]}
[CactusLLM] Successfully parsed DSL: mode.on:sleep
```

## 🔧 Available Models

Cactus supports these models via `downloadModel()`:

```dart
// Default (recommended for NothFlows)
await llm.downloadModel(model: 'qwen3-0.6');  // ~400MB, fast

// Alternatives
await llm.downloadModel(model: 'qwen3-1.5');  // ~900MB, more accurate
await llm.downloadModel(model: 'gemma-2b');   // ~1.2GB, very accurate
await llm.downloadModel(model: 'phi-2');      // ~1.5GB, excellent quality
```

**Recommendation:** Stick with `qwen3-0.6` for the best speed/size balance.

## ⚠️ Troubleshooting

### Issue: "version solving failed"

**Error:**
```
Because nothflows depends on cactus ^1.0.2 which doesn't match any versions
```

**Solution:**
```bash
flutter pub cache repair
flutter clean
flutter pub get
```

### Issue: Model download fails

**Error in logs:**
```
[Cactus] Download failed: Network error
```

**Solution:**
1. Ensure stable internet connection
2. Try Wi-Fi instead of cellular
3. Check device storage (need 500MB free)
4. Wait and retry - Hugging Face can be slow

### Issue: "Loading AI model..." never completes

**Possible causes:**
- No internet on first run
- Insufficient storage
- Download interrupted

**Solution:**
```bash
# Clear cache and retry
adb shell pm clear com.nothflows
flutter run --release
```

### Issue: Parsing takes >10 seconds

**Solution:**
1. Use release build (not debug): `flutter run --release`
2. First inference is always slower (model warming up)
3. Subsequent parses should be 1-3 seconds

## 📖 Official Resources

- **Package:** https://pub.dev/packages/cactus
- **Docs:** https://cactuscompute.com/docs/flutter
- **GitHub:** https://github.com/cactus-compute/cactus
- **Medium Tutorial:** [How to run private, on-device AI](https://medium.com/@shemet0roman/how-to-run-private-on-device-ai-in-your-flutter-app-using-cactus-adfc561960bf)

## ✅ Quick Test

Test the Cactus installation with this snippet:

```dart
import 'package:cactus/cactus.dart';

Future<void> testCactus() async {
  print('Creating Cactus LLM...');
  final llm = CactusLM();

  print('Downloading model...');
  await llm.downloadModel(model: 'qwen3-0.6');

  print('Initializing...');
  await llm.initializeModel();

  print('Running test inference...');
  final result = await llm.generateCompletion(
    messages: [
      ChatMessage(role: 'user', content: 'What is 2+2?'),
    ],
  );

  if (result.success) {
    print('✅ Success! Response: ${result.response}');
  } else {
    print('❌ Failed: ${result.response}');
  }

  llm.unload();
  print('Done!');
}
```

Add to `lib/main.dart` splash screen to verify installation.

## 🎉 You're Ready!

Now run:

```bash
flutter pub get
flutter run --release
```

And start creating flows with on-device AI! 🚀

---

**Updated:** 2025-01-XX
**Cactus Version:** 1.0.2 (Latest)
**Model:** Qwen3-0.6B (~400MB)

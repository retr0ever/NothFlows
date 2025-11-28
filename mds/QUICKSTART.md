# NothFlows - Quick Start Guide

## 🚀 Getting Started in 5 Minutes

### Prerequisites

- Flutter 3.0+ installed
- Android Studio or VS Code
- Nothing Phone or Android emulator
- USB debugging enabled

### Step 1: Install Dependencies

```bash
cd /Users/selin/Desktop/NothFlows/Code
flutter pub get
```

Expected output:
```
Running "flutter pub get" in Code...
Resolving dependencies... (5.2s)
+ cactus_llm 0.1.0
+ cactus_rag 0.1.0
+ cactus_vlm 0.1.0
+ provider 6.1.1
...
Got dependencies!
```

### Step 2: Connect Device

```bash
# Check connected devices
flutter devices
```

You should see your Nothing Phone:
```
Found 1 device:
  Nothing Phone (2) (mobile) • ABC123DEF456 • android-arm64 • Android 13
```

### Step 3: Run the App

```bash
# Debug build (faster)
flutter run

# Release build (recommended for testing)
flutter run --release
```

First run will take ~2-3 minutes to build.

### Step 4: Grant Permissions

On first launch, the app will request:

1. **Storage Access** - For cleaning screenshots/downloads
2. **Modify Settings** - For brightness control

Tap "Settings" → "Request Permissions" → Grant both.

### Step 5: Test a Flow

1. Tap **"Sleep Mode"** card
2. Type: `"Clean screenshots older than 30 days"`
3. Wait 2-3 seconds for AI to parse (first time is slow)
4. Review the generated flow in the preview
5. Tap **"Add Flow"**
6. Toggle **Sleep Mode ON** to execute

You should see a snackbar: "Sleep mode activated"

## 📱 App Navigation

```
Home Screen
├─ Sleep Mode Card → Tap → Mode Detail Screen
│  ├─ Input field → Type instruction
│  ├─ Example chips → Tap to populate
│  └─ Flow list → Tap to preview
│
├─ Focus Mode Card → Same as above
├─ Custom Mode Card → Same as above
│
└─ Settings FAB → Tap → Settings Sheet
   ├─ Request Permissions
   └─ Reset Data
```

## 🎯 Example Flows to Try

### Sleep Mode

```
"Clean screenshots older than 30 days and lower brightness to 20%"
```

Generates:
```json
{
  "trigger": "mode.on:sleep",
  "actions": [
    { "type": "clean_screenshots", "older_than_days": 30 },
    { "type": "lower_brightness", "to": 20 }
  ]
}
```

### Focus Mode

```
"Mute Instagram and TikTok, enable Do Not Disturb, and launch Notion"
```

Generates:
```json
{
  "trigger": "mode.on:focus",
  "actions": [
    { "type": "mute_apps", "apps": ["Instagram", "TikTok"] },
    { "type": "enable_dnd" },
    { "type": "launch_app", "app": "Notion" }
  ]
}
```

### Custom Mode

```
"Clean downloads older than 7 days and set brightness to 50%"
```

Generates:
```json
{
  "trigger": "mode.on:custom",
  "actions": [
    { "type": "clean_downloads", "older_than_days": 7 },
    { "type": "lower_brightness", "to": 50 }
  ]
}
```

## 🔧 Troubleshooting

### Issue: "Model not found" error

**Cause:** Qwen3 model not downloaded

**Solution:**
1. Ensure internet connection
2. Wait 30-60 seconds on first run
3. Check `/data/data/com.nothflows/files/models/` for `qwen3-600m.gguf`

### Issue: LLM parsing takes >10 seconds

**Cause:** First inference is slow (model loading)

**Solution:**
1. Subsequent parses will be faster (2-3s)
2. Use release build for better performance: `flutter run --release`
3. Check device isn't in battery saver mode

### Issue: "Permission denied" on file cleanup

**Cause:** Storage permission not granted

**Solution:**
1. Tap Settings FAB → Request Permissions
2. Enable "Files and media" in Android settings
3. Some actions require `MANAGE_EXTERNAL_STORAGE`

### Issue: Brightness control doesn't work

**Cause:** Write settings permission not granted

**Solution:**
1. Settings → Apps → NothFlows → Permissions
2. Enable "Modify system settings"
3. Try toggling mode again

### Issue: App names not recognised in "mute_apps"

**Cause:** LLM hallucinating app names

**Solution:**
1. Use exact app names: "Instagram" not "Insta"
2. Check installed apps: Settings → Apps
3. Try alternative phrasing: "Mute Instagram and TikTok"

## 🐛 Debugging

### Enable Debug Logs

```dart
// In lib/services/cactus_llm_service.dart
debugPrint('[CactusLLM] ...');  // Already enabled
```

View logs:
```bash
flutter logs
```

### Check Storage

```bash
# View saved modes
adb shell run-as com.nothflows cat /data/data/com.nothflows/shared_prefs/FlutterSharedPreferences.xml
```

### Inspect Model Cache

```bash
# List cached models
adb shell ls -lh /data/data/com.nothflows/files/models/
```

### Reset App Data

```bash
# Clear all data (WARNING: deletes flows)
flutter run --clear-cache
adb shell pm clear com.nothflows
```

## 📊 Performance Benchmarks

Expected performance on Nothing Phone 2:

| Metric | Target | Typical |
|--------|--------|---------|
| App Launch | < 2s | 1.5s |
| Model Load | < 5s | 3-4s |
| First Parse | < 5s | 3-4s |
| Subsequent Parse | < 3s | 2s |
| Flow Execution | < 1s | 0.5s |

If your device is slower, try:
1. Release build: `flutter run --release`
2. Close background apps
3. Disable battery saver

## 🎨 Customisation

### Change Theme

```dart
// In lib/main.dart:137
themeMode: ThemeMode.dark,  // Change to .light or .system
```

### Add New Mode

```dart
// In lib/models/mode_model.dart:25
static ModeModel get gaming => ModeModel(
  id: 'gaming',
  name: 'Gaming',
  description: 'Optimise for gaming',
  icon: Icons.videogame_asset,
  color: const Color(0xFFFF4DDD),
);

// Add to defaults:
static List<ModeModel> get defaults => [sleep, focus, custom, gaming];
```

### Add New Action Type

See `ARCHITECTURE.md` → "Future Extensibility" → "Adding New Actions"

## 📖 Further Reading

- **README.md** - Full documentation
- **ARCHITECTURE.md** - Technical deep dive
- **DSL_REFERENCE.md** - Complete DSL guide
- **PROJECT_SUMMARY.md** - Project overview

## 🆘 Getting Help

### Common Questions

**Q: Why does the first parse take so long?**
A: The Qwen3 model (500MB) loads into memory on first use. Subsequent parses are 2-3x faster.

**Q: Can I use this without internet?**
A: Yes, after the initial model download. All AI runs 100% offline.

**Q: Why can't I toggle Wi-Fi/Bluetooth?**
A: Android 10+ requires user interaction. Tap the notification to complete.

**Q: How do I share flows with friends?**
A: Not yet supported. Coming in v2.0 with flow export/import.

**Q: Can I edit a flow after adding it?**
A: Currently, you must delete and re-add. Edit feature coming soon.

## 🚢 Deployment

### Build APK

```bash
# Release APK (single file, ~35MB)
flutter build apk --release

# Split APKs (smaller, ~25MB each)
flutter build apk --split-per-abi
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Install on Device

```bash
# Via USB
adb install build/app/outputs/flutter-apk/app-release.apk

# Via file transfer
cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/
# Transfer to phone, open with installer
```

### Share APK

Upload to:
- Google Drive
- Nothing Community Forum
- GitHub Releases
- XDA Developers

**Note:** For Play Store, you need an app bundle:
```bash
flutter build appbundle --release
```

## ✅ Quick Checklist

Before sharing your build:

- [ ] Test all 10 action types
- [ ] Verify permissions work
- [ ] Test on real Nothing Phone
- [ ] Check dark theme rendering
- [ ] Ensure LLM parsing is accurate
- [ ] Test with complex instructions
- [ ] Verify storage persistence
- [ ] Check app size (<50MB)
- [ ] Test offline functionality
- [ ] Review crash logs

## 🎉 Success Metrics

Your build is ready when:

✅ All permissions granted
✅ LLM parses >70% of instructions correctly
✅ Flows execute without errors
✅ UI is responsive (60 FPS)
✅ App launches in <2 seconds
✅ Storage persists after app restart
✅ No crashes in 10 minutes of use

## 📞 Support

Found a bug? See `README.md` for contribution guidelines.

---

**Happy Automating! 🚀**

Built with ❤️ for Nothing Phone users

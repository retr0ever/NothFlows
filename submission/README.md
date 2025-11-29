# NothFlows v1.0 - Release Build

## 📱 Installation Instructions

### Quick Install

1. **Transfer APK to your Android device**
   - Copy `NothFlows-v1.0-release.apk` to your device via USB, email, or file sharing app

2. **Enable installation from unknown sources** (if prompted)
   - Go to Settings → Security → Install unknown apps
   - Select the app you're using to install (e.g., Files, Chrome)
   - Enable "Allow from this source"

3. **Install the APK**
   - Tap `NothFlows-v1.0-release.apk` on your device
   - Follow the installation prompts
   - Tap "Install"

4. **Grant permissions**
   The app will request:
   - **Microphone**: For wake word detection ("North-Flow") and voice commands
   - **Accessibility Service**: For screen reading and app integration
   - **Storage**: For file management actions
   - **Internet**: Only needed once to download Qwen3 model (~500MB)

5. **First run**
   - App downloads Qwen3 model (~500MB) on first launch
   - Takes 2-5 minutes depending on connection
   - Model cached permanently - app works 100% offline after this

### Via ADB (Developer Option)

If you have ADB installed:

```bash
adb install NothFlows-v1.0-release.apk
```

## 📋 Build Specifications

- **Version**: 1.0
- **Package**: com.nothflows
- **Size**: 65 MB
- **Minimum SDK**: Android 7.0 (API 24)
- **Target SDK**: Android 14 (API 34)
- **Architectures**: ARM64, ARMv7, x86_64
- **Build Type**: Release (production-ready)

## 🔧 System Requirements

- **OS**: Android 7.0 (Nougat) or higher
- **RAM**: 2GB+ recommended (for on-device AI)
- **Storage**: 600MB total (65MB app + 500MB model + 35MB cache)
- **Internet**: Required once for model download, then fully offline

## 🚀 Getting Started

1. **Launch NothFlows** from your app drawer
2. **Grant permissions** when prompted
3. **Wait for model download** (~500MB, one-time only)
4. **Say "North-Flow"** to activate voice commands
5. **Try a command**: "Make text huge and boost brightness"

## 📖 Full Documentation

See the main [README.md](../README.md) in the root directory for:
- Detailed feature documentation
- User guides for different disabilities
- Voice command reference
- Architecture and technical details

## 🆘 Troubleshooting

**Model download stuck?**
- Ensure stable internet connection
- App will auto-resume if interrupted

**Voice commands not working?**
- Check microphone permission granted
- Say "North-Flow" clearly to activate
- Speak after hearing "Yes?" confirmation

**Screen reading not working?**
- Enable NothFlows Accessibility Service
- Settings → Accessibility → NothFlows → Turn on

## 📧 Support

For issues or feedback:
- GitHub: [Team Lotus NothFlows Repository]
- Email: [Your team email if available]

---

**Built for Nothing users by Team Lotus**
**Licence**: MIT
**Privacy**: All data stays on your device. No cloud, no tracking, no telemetry.

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service for text-to-speech voice responses
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Pre-defined response templates
  static const Map<String, String> responses = {
    // Mode activations
    'mode.on:vision': 'Vision mode activated',
    'mode.off:vision': 'Vision mode deactivated',
    'mode.on:motor': 'Motor mode activated',
    'mode.off:motor': 'Motor mode deactivated',
    'mode.on:hearing': 'Hearing mode activated',
    'mode.off:hearing': 'Hearing mode deactivated',
    'mode.on:calm': 'Calm mode activated',
    'mode.off:calm': 'Calm mode deactivated',
    'mode.on:neurodivergent': 'Focus mode activated',
    'mode.off:neurodivergent': 'Focus mode deactivated',
    'mode.on:sleep': 'Sleep mode activated',
    'mode.off:sleep': 'Sleep mode deactivated',
    'mode.on:focus': 'Focus mode activated',
    'mode.off:focus': 'Focus mode deactivated',

    // Direct actions
    'lower_brightness': 'Brightness adjusted',
    'set_volume': 'Volume adjusted',
    'enable_dnd': 'Do not disturb enabled',
    'disable_wifi': 'WiFi disabled',
    'disable_bluetooth': 'Bluetooth disabled',
    'clean_screenshots': 'Screenshots cleaned',
    'clean_downloads': 'Downloads cleaned',
    'increase_contrast': 'Contrast increased',
    'set_wallpaper': 'Wallpaper set',
    'launch_app': 'App launched',
    'mute_apps': 'Apps muted',

    // App integration
    'app_read_gmail': 'Reading your email',
    'app_read_weather': 'Checking the weather',

    // Errors
    'error.not_recognized': 'Command not recognized',
    'error.failed': 'Action failed',
    'error.no_speech': 'No speech detected',
  };

  /// Check if TTS is speaking
  bool get isSpeaking => _isSpeaking;

  /// Initialize TTS engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('[TTS] Initializing...');

      // Set language
      await _tts.setLanguage('en-US');

      // Set speech parameters
      await _tts.setSpeechRate(0.5); // Moderate speed
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Enable await speak completion - this makes speak() wait until done
      await _tts.awaitSpeakCompletion(true);

      // Set up callbacks
      _tts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('[TTS] Started speaking');
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('[TTS] Finished speaking');
      });

      _tts.setErrorHandler((message) {
        _isSpeaking = false;
        debugPrint('[TTS] Error: $message');
      });

      _isInitialized = true;
      debugPrint('[TTS] Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('[TTS] Initialization error: $e');
      return false;
    }
  }

  /// Speak text aloud and wait for completion
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('[TTS] Speaking: $text');
      // With awaitSpeakCompletion(true), this will wait until speech finishes
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[TTS] Speak error: $e');
    }
  }

  /// Speak a response for a trigger/action type
  Future<void> speakResponse(String key) async {
    final response = responses[key];
    if (response != null) {
      await speak(response);
    } else {
      debugPrint('[TTS] No response template for: $key');
    }
  }

  /// Speak a mode activation/deactivation response
  Future<void> speakModeChange(String modeId, bool isActivating) async {
    final key = 'mode.${isActivating ? 'on' : 'off'}:$modeId';
    final response = responses[key];
    if (response != null) {
      await speak(response);
    } else {
      // Fallback for unknown modes
      final action = isActivating ? 'activated' : 'deactivated';
      await speak('$modeId mode $action');
    }
  }

  /// Speak an action result
  Future<void> speakActionResult(String actionType, bool success) async {
    if (success) {
      final response = responses[actionType];
      if (response != null) {
        await speak(response);
      } else {
        await speak('Done');
      }
    } else {
      await speak(responses['error.failed']!);
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('[TTS] Stop error: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _tts.stop();
    _isInitialized = false;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Service for wake word detection using Porcupine with custom "North-Flow" wake word
class WakeWordService {
  static final WakeWordService _instance = WakeWordService._internal();
  factory WakeWordService() => _instance;
  WakeWordService._internal();

  PorcupineManager? _porcupineManager;
  bool _isInitialized = false;
  bool _isListening = false;

  /// Custom wake word model file name
  static const String _wakeWordModelFile = 'North-Flow_en_android_v3_0_0.ppn';

  /// Callback when wake word is detected
  Function()? onWakeWordDetected;

  /// Callback for errors
  Function(String error)? onError;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if currently listening for wake word
  bool get isListening => _isListening;

  /// Copy asset to temporary directory and return the path
  Future<String> _copyAssetToTemp(String assetPath) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$_wakeWordModelFile');

    // Copy only if not already copied
    if (!await tempFile.exists()) {
      final data = await rootBundle.load(assetPath);
      await tempFile.writeAsBytes(data.buffer.asUint8List());
      debugPrint('[WakeWord] Copied model to: ${tempFile.path}');
    }

    return tempFile.path;
  }

  /// Initialize the wake word detection with Picovoice AccessKey
  /// Get your free AccessKey at https://console.picovoice.ai/
  Future<bool> initialize(String accessKey) async {
    if (_isInitialized) return true;

    try {
      debugPrint('[WakeWord] Initializing with custom "North-Flow" wake word...');

      // Copy the .ppn file from assets to a readable location
      final modelPath = await _copyAssetToTemp('assets/$_wakeWordModelFile');

      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        accessKey,
        [modelPath], // Custom wake word model
        _onWakeWordDetected,
        errorCallback: _onError,
      );

      _isInitialized = true;
      debugPrint('[WakeWord] Initialized successfully with "North-Flow" wake word');
      return true;
    } on PorcupineException catch (e) {
      debugPrint('[WakeWord] Initialization error: ${e.message}');
      onError?.call('Wake word init failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[WakeWord] Unexpected error: $e');
      onError?.call('Wake word init failed: $e');
      return false;
    }
  }

  void _onWakeWordDetected(int keywordIndex) {
    debugPrint('[WakeWord] "North-Flow" detected! Index: $keywordIndex');
    onWakeWordDetected?.call();
  }

  void _onError(PorcupineException error) {
    debugPrint('[WakeWord] Error: ${error.message}');
    onError?.call(error.message ?? 'Unknown wake word error');
  }

  /// Start listening for wake word
  Future<bool> startListening() async {
    if (!_isInitialized) {
      debugPrint('[WakeWord] Not initialized, cannot start');
      return false;
    }

    if (_isListening) {
      debugPrint('[WakeWord] Already listening');
      return true;
    }

    try {
      debugPrint('[WakeWord] Starting wake word detection...');
      await _porcupineManager?.start();
      _isListening = true;
      debugPrint('[WakeWord] Now listening for "North-Flow"');
      return true;
    } on PorcupineException catch (e) {
      debugPrint('[WakeWord] Start error: ${e.message}');
      onError?.call('Could not start wake word: ${e.message}');
      return false;
    }
  }

  /// Stop listening for wake word
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      debugPrint('[WakeWord] Stopping wake word detection...');
      await _porcupineManager?.stop();
      _isListening = false;
      debugPrint('[WakeWord] Stopped listening');
    } catch (e) {
      debugPrint('[WakeWord] Stop error: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopListening();
    await _porcupineManager?.delete();
    _porcupineManager = null;
    _isInitialized = false;
    debugPrint('[WakeWord] Disposed');
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/flow_dsl.dart';
import 'storage_service.dart';
import 'automation_executor.dart';
import 'tts_service.dart';

/// Result of parsing a voice command
class ParsedCommand {
  final String? trigger;
  final String? modeId;
  final bool isActivating;
  final FlowAction? directAction;
  final String rawText;
  final double confidence;

  ParsedCommand({
    this.trigger,
    this.modeId,
    this.isActivating = true,
    this.directAction,
    required this.rawText,
    this.confidence = 0.0,
  });

  bool get isValid => trigger != null || directAction != null;

  @override
  String toString() =>
      'ParsedCommand(trigger: $trigger, mode: $modeId, action: ${directAction?.type}, raw: $rawText)';
}

/// Service for voice command recognition and execution
class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final SpeechToText _speech = SpeechToText();
  final StorageService _storage = StorageService();
  final AutomationExecutor _executor = AutomationExecutor();
  final TtsService _tts = TtsService();

  bool _isInitialized = false;
  bool _isListening = false;
  String _lastRecognizedText = '';
  double _confidence = 0.0;

  // Callbacks
  Function(String text, bool isFinal)? onResult;
  Function(String error)? onError;
  Function(bool isListening)? onListeningStateChanged;

  /// Check if speech recognition is available
  bool get isAvailable => _isInitialized;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Get last recognized text
  String get lastRecognizedText => _lastRecognizedText;

  /// Get confidence of last recognition
  double get confidence => _confidence;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      debugPrint('[VoiceCommand] Initializing speech recognition...');

      // Check microphone permission
      final micPermission = await Permission.microphone.status;
      if (!micPermission.isGranted) {
        debugPrint('[VoiceCommand] Microphone permission not granted');
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          debugPrint('[VoiceCommand] Microphone permission denied');
          return false;
        }
      }

      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[VoiceCommand] Status: $status');
          _isListening = status == 'listening';
          onListeningStateChanged?.call(_isListening);
        },
        onError: (error) {
          debugPrint('[VoiceCommand] Error: ${error.errorMsg}');
          _isListening = false;
          onError?.call(error.errorMsg);
          onListeningStateChanged?.call(false);
        },
      );

      debugPrint('[VoiceCommand] Initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      debugPrint('[VoiceCommand] Initialization error: $e');
      return false;
    }
  }

  /// Start listening for voice commands
  Future<bool> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    if (_isListening) {
      debugPrint('[VoiceCommand] Already listening');
      return true;
    }

    try {
      debugPrint('[VoiceCommand] Starting to listen...');
      _lastRecognizedText = '';
      _confidence = 0.0;

      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );

      _isListening = true;
      onListeningStateChanged?.call(true);
      return true;
    } catch (e) {
      debugPrint('[VoiceCommand] Error starting listen: $e');
      onError?.call(e.toString());
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      debugPrint('[VoiceCommand] Stopping listen...');
      await _speech.stop();
      _isListening = false;
      onListeningStateChanged?.call(false);
    } catch (e) {
      debugPrint('[VoiceCommand] Error stopping: $e');
    }
  }

  /// Cancel listening without processing
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
      _isListening = false;
      _lastRecognizedText = '';
      onListeningStateChanged?.call(false);
    } catch (e) {
      debugPrint('[VoiceCommand] Error canceling: $e');
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastRecognizedText = result.recognizedWords;
    _confidence = result.confidence;

    debugPrint(
        '[VoiceCommand] Result: $_lastRecognizedText (confidence: $_confidence, final: ${result.finalResult})');

    onResult?.call(_lastRecognizedText, result.finalResult);
  }

  /// Parse spoken text into a command
  ParsedCommand parseCommand(String spokenText) {
    final lower = spokenText.toLowerCase().trim();
    debugPrint('[VoiceCommand] Parsing: $lower');

    // Mode activation patterns
    final modePatterns = {
      'vision': [
        'vision',
        'visual',
        'sight',
        'see',
        'eyes',
        'visibility'
      ],
      'motor': ['motor', 'movement', 'mobility', 'hand', 'hands'],
      'hearing': ['hearing', 'audio', 'sound', 'deaf', 'listen'],
      'calm': ['calm', 'relax', 'anxiety', 'stress', 'peaceful'],
      'neurodivergent': [
        'neurodivergent',
        'adhd',
        'attention',
        'distraction'
      ],
      'sleep': ['sleep', 'night', 'bedtime', 'rest'],
      'focus': ['focus', 'concentrate', 'work', 'study'],
    };

    // Check for mode deactivation keywords
    final isDeactivating = lower.contains('deactivate') ||
        lower.contains('disable') ||
        lower.contains('turn off') ||
        lower.contains('turnoff') ||
        lower.contains('off') ||
        lower.contains('stop');

    debugPrint('[VoiceCommand] isDeactivating: $isDeactivating');

    // Check for mode keywords
    for (final entry in modePatterns.entries) {
      final modeId = entry.key;
      final keywords = entry.value;

      for (final keyword in keywords) {
        if (lower.contains(keyword)) {
          final action = isDeactivating ? 'off' : 'on';
          debugPrint('[VoiceCommand] Matched mode: $modeId ($action)');

          return ParsedCommand(
            trigger: 'mode.$action:$modeId',
            modeId: modeId,
            isActivating: !isDeactivating,
            rawText: spokenText,
            confidence: _confidence,
          );
        }
      }
    }

    // Check for direct actions
    final directAction = _parseDirectAction(lower);
    if (directAction != null) {
      return ParsedCommand(
        directAction: directAction,
        rawText: spokenText,
        confidence: _confidence,
      );
    }

    // No match found
    debugPrint('[VoiceCommand] No command matched for: $lower');
    return ParsedCommand(
      rawText: spokenText,
      confidence: _confidence,
    );
  }

  FlowAction? _parseDirectAction(String lower) {
    // Extract numbers from text
    final numberMatch = RegExp(r'(\d+)').firstMatch(lower);
    final number = numberMatch != null ? int.parse(numberMatch.group(1)!) : null;

    // Brightness
    if (lower.contains('brightness')) {
      final level = number ?? (lower.contains('max') ? 100 : 50);
      return FlowAction(
        type: 'lower_brightness',
        parameters: {'to': level},
      );
    }

    // Volume
    if (lower.contains('volume')) {
      final level = number ?? (lower.contains('mute') ? 0 : 50);
      return FlowAction(
        type: 'set_volume',
        parameters: {'level': level},
      );
    }

    // Do Not Disturb
    if (lower.contains('do not disturb') ||
        lower.contains('dnd') ||
        lower.contains('silence')) {
      return FlowAction(
        type: 'enable_dnd',
        parameters: {},
      );
    }

    // Clean screenshots
    if (lower.contains('clean') && lower.contains('screenshot')) {
      final days = number ?? 30;
      return FlowAction(
        type: 'clean_screenshots',
        parameters: {'older_than_days': days},
      );
    }

    // Clean downloads
    if (lower.contains('clean') && lower.contains('download')) {
      final days = number ?? 30;
      return FlowAction(
        type: 'clean_downloads',
        parameters: {'older_than_days': days},
      );
    }

    // Wifi
    if (lower.contains('wifi') &&
        (lower.contains('off') || lower.contains('disable'))) {
      return FlowAction(
        type: 'disable_wifi',
        parameters: {},
      );
    }

    // Bluetooth
    if (lower.contains('bluetooth') &&
        (lower.contains('off') || lower.contains('disable'))) {
      return FlowAction(
        type: 'disable_bluetooth',
        parameters: {},
      );
    }

    return null;
  }

  /// Execute a parsed voice command
  Future<List<ExecutionResult>> executeCommand(ParsedCommand command) async {
    if (!command.isValid) {
      debugPrint('[VoiceCommand] Invalid command, cannot execute');
      await _tts.speakResponse('error.not_recognized');
      return [
        ExecutionResult(
          actionType: 'voice_command',
          success: false,
          message: 'Could not understand command: "${command.rawText}"',
        )
      ];
    }

    debugPrint('[VoiceCommand] Executing command: $command');

    // If it's a direct action, execute it immediately
    if (command.directAction != null) {
      final flow = FlowDSL(
        trigger: 'mode.on:custom',
        actions: [command.directAction!],
      );
      final results = await _executor.executeFlow(flow);

      // Speak result for direct action
      if (results.isNotEmpty && results.first.success) {
        await _tts.speakActionResult(command.directAction!.type, true);
      } else {
        await _tts.speakResponse('error.failed');
      }

      return results;
    }

    // If it's a mode trigger, find and execute the mode's flows
    if (command.modeId != null) {
      final modes = await _storage.getModes();
      final mode = modes.firstWhere(
        (m) => m.id.toLowerCase() == command.modeId!.toLowerCase(),
        orElse: () => throw Exception('Mode not found: ${command.modeId}'),
      );

      // Set the mode state based on voice command (not toggle)
      debugPrint('[VoiceCommand] Setting mode ${mode.id} to ${command.isActivating ? "ACTIVE" : "INACTIVE"}');
      if (command.isActivating) {
        await _storage.setActiveMode(mode.id);
      } else {
        await _storage.deactivateAllModes();
      }
      debugPrint('[VoiceCommand] Mode state updated');

      // Speak mode change
      await _tts.speakModeChange(command.modeId!, command.isActivating);

      // Get flows for this event
      final flowsForEvent = mode.flows
          .where((f) => f.trigger.toLowerCase() == command.trigger!.toLowerCase())
          .toList();

      if (flowsForEvent.isEmpty) {
        return [
          ExecutionResult(
            actionType: 'voice_command',
            success: true,
            message:
                '${mode.name} ${command.isActivating ? "activated" : "deactivated"} (no flows configured)',
          )
        ];
      }

      // Execute all flows
      final allResults = <ExecutionResult>[];
      for (final flow in flowsForEvent) {
        final results = await _executor.executeFlow(flow);
        allResults.addAll(results);
      }

      return allResults;
    }

    return [
      ExecutionResult(
        actionType: 'voice_command',
        success: false,
        message: 'Unknown command type',
      )
    ];
  }

  /// Listen for a single command and execute it
  Future<List<ExecutionResult>?> listenAndExecute() async {
    final started = await startListening();
    if (!started) {
      return [
        ExecutionResult(
          actionType: 'voice_command',
          success: false,
          message: 'Could not start speech recognition',
        )
      ];
    }

    // Wait for final result
    final completer = Completer<String>();
    final originalCallback = onResult;

    onResult = (text, isFinal) {
      originalCallback?.call(text, isFinal);
      if (isFinal && !completer.isCompleted) {
        completer.complete(text);
      }
    };

    try {
      final text = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          stopListening();
          return _lastRecognizedText;
        },
      );

      await stopListening();

      if (text.isEmpty) {
        await _tts.speakResponse('error.no_speech');
        return [
          ExecutionResult(
            actionType: 'voice_command',
            success: false,
            message: 'No speech detected',
          )
        ];
      }

      final command = parseCommand(text);
      return await executeCommand(command);
    } finally {
      onResult = originalCallback;
    }
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Dispose resources
  void dispose() {
    _speech.cancel();
    _isInitialized = false;
    _isListening = false;
  }
}

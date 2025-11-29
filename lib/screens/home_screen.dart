import 'dart:io';
import 'package:flutter/material.dart';
import '../models/mode_model.dart';
import '../models/flow_dsl.dart';
import '../services/storage_service.dart';
import '../services/automation_executor.dart';
import '../services/voice_command_service.dart';
import '../services/tts_service.dart';
import '../services/wake_word_service.dart';
import '../widgets/mode_card.dart';
import 'mode_detail_screen.dart';
import 'daily_checkin_screen.dart';

/// Home screen showing all available modes
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  final _executor = AutomationExecutor();
  final _voiceService = VoiceCommandService();
  final _tts = TtsService();
  final _wakeWordService = WakeWordService();

  // Picovoice AccessKey from https://console.picovoice.ai/
  static const String _picovoiceAccessKey = '33oGpjjBGWvnbysyfus5jNiYPQYgs4sTcO51pYU8kXmiA+Rj35dXNg==';

  List<ModeModel> _modes = [];
  bool _isLoading = true;
  final bool _isSimulation = !Platform.isAndroid;

  // Voice command state
  bool _isListening = false;
  String _recognizedText = '';

  // Wake word state
  bool _isWakeWordEnabled = false;
  bool _isWakeWordListening = false;
  int _wakeWordRetryCount = 0;
  static const int _maxWakeWordRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadModes();
    _initVoiceService();
    
    // Auto-start wake word
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enableWakeWord();
    });
  }

  @override
  void dispose() {
    _wakeWordService.dispose();
    _tts.dispose();
    super.dispose();
  }

  Future<void> _initVoiceService() async {
    _voiceService.onResult = (text, isFinal) {
      setState(() => _recognizedText = text);
      if (isFinal && text.isNotEmpty) {
        _processVoiceCommand(text);
      }
    };

    _voiceService.onListeningStateChanged = (isListening) {
      if (mounted) {
        setState(() => _isListening = isListening);
      }
    };

    _voiceService.onError = (error) {
      debugPrint('[HomeScreen] Voice error: $error');
      if (mounted) {
        _showSnackBar('Voice error: $error');
      }
    };

    // Set up wake word callbacks
    _wakeWordService.onWakeWordDetected = _onWakeWordDetected;
    _wakeWordService.onError = (error) {
      debugPrint('[HomeScreen] Wake word error: $error');
      _handleWakeWordError(error);
    };
  }

  Future<void> _handleWakeWordError(String error) async {
    if (!mounted) return;
    
    // Only retry if enabled and under limit
    if (_isWakeWordEnabled && _wakeWordRetryCount < _maxWakeWordRetries) {
      _wakeWordRetryCount++;
      debugPrint('[HomeScreen] Retrying wake word (Attempt $_wakeWordRetryCount/$_maxWakeWordRetries)...');
      
      // Wait a bit before retrying to avoid tight loops
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted && _isWakeWordEnabled) {
        // Try to restart
        try {
          await _wakeWordService.stopListening(); // Ensure clean state
          await _resumeWakeWordIfEnabled();
        } catch (e) {
          debugPrint('[HomeScreen] Retry failed: $e');
        }
      }
    } else if (_wakeWordRetryCount >= _maxWakeWordRetries) {
      // Give up
      setState(() {
        _isWakeWordEnabled = false;
        _isWakeWordListening = false;
      });
      _showSnackBar('Wake word disabled: $error');
      _wakeWordRetryCount = 0;
    }
  }

  Future<void> _onWakeWordDetected() async {
    debugPrint('[HomeScreen] Wake word detected! Starting voice command...');

    // Pause wake word detection
    await _wakeWordService.stopListening();
    setState(() => _isWakeWordListening = false);

    // Play a sound/speak to indicate we heard the wake word
    await _tts.speak('Yes?');

    // Start voice command listening
    await _toggleVoiceListening();
  }

  Future<void> _enableWakeWord() async {
    if (_isWakeWordEnabled) return;

    // Enable wake word - first initialize if needed
    if (!_wakeWordService.isInitialized) {
      if (_picovoiceAccessKey == 'YOUR_ACCESS_KEY_HERE') {
        _showSnackBar('ERROR: Picovoice AccessKey is missing!');
        return;
      }
      
      try {
        final initialized = await _wakeWordService.initialize(_picovoiceAccessKey);
        if (!initialized) {
          _showSnackBar('ERROR: Could not initialize wake word engine');
          return;
        }
      } catch (e) {
         _showSnackBar('EXCEPTION: Wake word init crashed: $e');
         return;
      }
    }

    try {
      final started = await _wakeWordService.startListening();
      if (started) {
        setState(() {
          _isWakeWordEnabled = true;
          _isWakeWordListening = true;
        });
        _wakeWordRetryCount = 0; // Reset retries on success
        _showSnackBar('Wake word ACTIVE. Say "North-Flow"');
      } else {
        _handleWakeWordError('Could not start microphone');
      }
    } catch (e) {
      _handleWakeWordError('Start crashed: $e');
    }
  }

  Future<void> _toggleWakeWord() async {
    if (_isWakeWordEnabled) {
      // Disable wake word
      await _wakeWordService.stopListening();
      setState(() {
        _isWakeWordEnabled = false;
        _isWakeWordListening = false;
      });
      _showSnackBar('Wake word disabled');
    } else {
      await _enableWakeWord();
    }
  }

  Future<void> _processVoiceCommand(String text) async {
    final command = _voiceService.parseCommand(text);

    if (!command.isValid) {
      _showSnackBar('Command not recognized: "$text"');
      await _resumeWakeWordIfEnabled();
      return;
    }

    // Show what we're doing
    if (command.modeId != null) {
      _showSnackBar(
        '${command.isActivating ? "Activating" : "Deactivating"} ${command.modeId} mode...',
      );
    } else if (command.directAction != null) {
      _showSnackBar('Executing: ${command.directAction!.type}...');
    }

    // Execute the command
    final results = await _voiceService.executeCommand(command);

    // Reload modes to reflect any changes
    await _loadModes();

    // Show results
    if (results.isNotEmpty && mounted) {
      final successCount = results.where((r) => r.success).length;
      if (successCount == results.length) {
        _showSnackBar('Command completed successfully');
      } else {
        _showSnackBar('Completed with ${results.length - successCount} errors');
      }
    }

    // Resume wake word listening if it was enabled
    await _resumeWakeWordIfEnabled();
  }

  Future<void> _resumeWakeWordIfEnabled() async {
    if (_isWakeWordEnabled && !_isWakeWordListening) {
      try {
        final started = await _wakeWordService.startListening();
        if (started && mounted) {
          setState(() => _isWakeWordListening = true);
          _wakeWordRetryCount = 0; // Reset retries on success
          debugPrint('[HomeScreen] Resumed wake word listening');
        } else {
          _handleWakeWordError('Failed to resume listening');
        }
      } catch (e) {
        _handleWakeWordError('Resume crashed: $e');
      }
    }
  }

  Future<void> _toggleVoiceListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
        _recognizedText = '';
      });
    } else {
      // Check permission first
      final hasPermission = await _voiceService.hasMicrophonePermission();
      if (!hasPermission) {
        final granted = await _voiceService.requestMicrophonePermission();
        if (!granted) {
          _showSnackBar('Microphone permission required for voice commands');
          return;
        }
      }

      final started = await _voiceService.startListening();
      if (!started) {
        _showSnackBar('Could not start voice recognition');
      }
    }
  }

  Future<void> _loadModes() async {
    setState(() => _isLoading = true);

    try {
      final modes = await _storage.getModes();
      setState(() {
        _modes = modes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading modes: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMode(ModeModel mode) async {
    try {
      final isActivating = !mode.isActive;
      final flowsForEvent = _getFlowsForEvent(mode, isActivating: isActivating);

      // Toggle the mode
      await _storage.toggleMode(mode.id);

      // Speak mode change
      await _tts.speakModeChange(mode.id, isActivating);

      // If activating/deactivating, execute relevant flows for that event
      if (flowsForEvent.isNotEmpty) {
        final allResults = <ExecutionResult>[];

        // Request any missing permissions before running
        await _executor.requestPermissions();

        for (final flow in flowsForEvent) {
          final results = await _executor.executeFlow(flow);
          allResults.addAll(results);
        }

        if (mounted && allResults.isNotEmpty) {
          _showExecutionResults(
            mode,
            allResults,
            isActivating: isActivating,
          );
        }
      } else {
        _showSnackBar(
          'No flows set for turning ${isActivating ? "on" : "off"} ${mode.name}',
        );
      }

      _showSnackBar(
        isActivating
            ? '${mode.name} mode activated'
            : '${mode.name} mode deactivated',
      );

      // Reload modes to reflect changes
      await _loadModes();
    } catch (e) {
      _showSnackBar('Error toggling mode: $e');
    }
  }

  List<FlowDSL> _getFlowsForEvent(
    ModeModel mode, {
    required bool isActivating,
  }) {
    final expectedTrigger = 'mode.${isActivating ? "on" : "off"}:${mode.id}';
    return mode.flows
        .where((flow) => flow.trigger.toLowerCase() == expectedTrigger)
        .toList();
  }

  void _showExecutionResults(
    ModeModel mode,
    List<ExecutionResult> results, {
    required bool isActivating,
  }) {
    if (!mounted) return;

    final successCount = results.where((r) => r.success).length;
    final failureCount = results.length - successCount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final sheetColor = Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${mode.name} ${isActivating ? "on" : "off"}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (failureCount > 0
                                ? Colors.red
                                : Colors.green)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$successCount/${results.length} actions',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: failureCount > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isSimulation)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Simulation mode: actions are logged but device changes are not applied.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: (results.length * 68).clamp(180, 360).toDouble(),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.08),
                    ),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          result.success ? Icons.check_circle : Icons.error,
                          color: result.success ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          result.actionType,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        subtitle: result.message != null
                            ? Text(
                                result.message!,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openModeDetail(ModeModel mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModeDetailScreen(mode: mode),
      ),
    ).then((_) => _loadModes());
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF000000)
          : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadModes,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // App bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'NothFlows',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.5,
                                  ),
                                ),
                                if (_isSimulation) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange),
                                    ),
                                    child: const Text(
                                      'SIMULATION',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your Assistive Automation Engine',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.6),
                                letterSpacing: 0,
                              ),
                            ),
                            // Wake word indicator
                            if (_isWakeWordListening) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5B4DFF).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF5B4DFF).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF5B4DFF),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Listening for "North-Flow"',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF5B4DFF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Mode cards
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final mode = _modes[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ModeCard(
                                mode: mode,
                                onTap: () => _openModeDetail(mode),
                                onToggle: () => _toggleMode(mode),
                              ),
                            );
                          },
                          childCount: _modes.length,
                        ),
                      ),
                    ),

                    // Bottom spacing
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                ),
              ),
      ),

      // FAB buttons with voice command
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice command button
          FloatingActionButton(
            onPressed: _toggleVoiceListening,
            backgroundColor: _isListening
                ? Colors.red
                : const Color(0xFF5B4DFF),
            foregroundColor: Colors.white,
            heroTag: 'voice_command',
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                key: ValueKey(_isListening),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Daily Check-In button
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DailyCheckInScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFF5B4DFF),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.favorite_border),
            label: const Text(
              'Daily Check-In',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            heroTag: 'daily_checkin',
          ),
          const SizedBox(height: 12),
          // Settings button
          FloatingActionButton(
            onPressed: () => _showSettingsSheet(),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            heroTag: 'settings',
            child: Icon(
              Icons.settings,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ],
      ),
    );

    // Wrap in Stack to show voice listening overlay
    return Stack(
      children: [
        scaffold,
        // Voice listening overlay
        if (_isListening)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleVoiceListening,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated microphone
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 1.3),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.mic,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          );
                        },
                        onEnd: () {
                          // This creates the pulsing effect
                          if (mounted && _isListening) {
                            setState(() {});
                          }
                        },
                      ),

                      const SizedBox(height: 32),

                      // Listening text
                      const Text(
                        'Listening...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Recognized text
                      if (_recognizedText.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '"$_recognizedText"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Hint text
                      Text(
                        'Say "Activate vision assist" or "Set brightness to 50"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tap to cancel
                      Text(
                        'Tap anywhere to cancel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 24),

            // Request permissions
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Request Permissions'),
              subtitle: const Text('Grant necessary permissions'),
              onTap: () async {
                final results = await _executor.requestPermissions();
                final granted = results.values.where((v) => v).length;
                final total = results.length;

                if (context.mounted) {
                  Navigator.pop(context);
                  _showSnackBar('Granted $granted/$total permissions');
                }
              },
            ),

            // Wake word toggle
            StatefulBuilder(
              builder: (context, setSheetState) {
                return SwitchListTile(
                  secondary: Icon(
                    _isWakeWordEnabled ? Icons.hearing : Icons.hearing_disabled,
                    color: _isWakeWordEnabled ? const Color(0xFF5B4DFF) : null,
                  ),
                  title: const Text('Always-on Voice'),
                  subtitle: Text(
                    _isWakeWordEnabled
                        ? 'Say "North-Flow" to activate'
                        : 'Enable hands-free voice commands',
                  ),
                  value: _isWakeWordEnabled,
                  onChanged: (value) async {
                    Navigator.pop(context);
                    await _toggleWakeWord();
                  },
                );
              },
            ),

            // Reset data
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset Data'),
              subtitle: const Text('Clear all modes and flows'),
              onTap: () async {
                await _storage.clearAll();
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadModes();
                  _showSnackBar('Data reset successfully');
                }
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

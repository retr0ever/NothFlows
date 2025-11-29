import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/mode_model.dart';
import '../models/flow_dsl.dart';
import '../services/storage_service.dart';
import '../services/automation_executor.dart';
import '../services/voice_command_service.dart';
import '../services/tts_service.dart';
import '../services/recommendation_service.dart';
import '../services/feedback_service.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';
import '../widgets/noth_card.dart';
import '../widgets/noth_button.dart';
import '../widgets/noth_panel.dart';
import '../widgets/noth_list_tile.dart';
import '../widgets/noth_toast.dart';
import '../widgets/noth_bottom_sheet.dart';
import '../widgets/noth_toggle.dart';
import '../widgets/suggestion_card.dart';
import '../services/wake_word_service.dart';
import 'mode_detail_screen.dart';
import 'daily_checkin_screen.dart';
import 'permissions_screen.dart';

/// Home screen showing all available modes with Nothing-style design
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
  final _recommendationService = RecommendationService();
  final _feedbackService = FeedbackService();

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

  // Suggestion state
  Recommendation? _currentRecommendation;
  bool _suggestionExpanded = false;

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
        NothToast.error(context, 'Voice error: $error');
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
      NothToast.error(context, 'Wake word disabled: $error');
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
        NothToast.error(context, 'ERROR: Picovoice AccessKey is missing!');
        return;
      }
      
      try {
        final initialized = await _wakeWordService.initialize(_picovoiceAccessKey);
        if (!initialized) {
          NothToast.error(context, 'ERROR: Could not initialize wake word engine');
          return;
        }
      } catch (e) {
         NothToast.error(context, 'EXCEPTION: Wake word init crashed: $e');
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
        NothToast.success(context, 'Wake word ACTIVE. Say "North-Flow"');
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
      NothToast.info(context, 'Wake word disabled');
    } else {
      await _enableWakeWord();
    }
  }

  Future<void> _processVoiceCommand(String text) async {
    final command = _voiceService.parseCommand(text);

    if (!command.isValid) {
      NothToast.warning(context, 'Command not recognized: "$text"');
      await _resumeWakeWordIfEnabled();
      return;
    }

    // Show what we're doing
    if (command.modeId != null) {
      NothToast.info(
        context,
        '${command.isActivating ? "Activating" : "Deactivating"} ${command.modeId} mode...',
      );
    } else if (command.directAction != null) {
      NothToast.info(context, 'Executing: ${command.directAction!.type}...');
    }

    // Execute the command
    final results = await _voiceService.executeCommand(command);

    // Reload modes to reflect any changes
    await _loadModes();

    // Show results
    if (results.isNotEmpty && mounted) {
      final successCount = results.where((r) => r.success).length;
      if (successCount == results.length) {
        NothToast.success(context, 'Command completed successfully');
      } else {
        NothToast.warning(
          context,
          'Completed with ${results.length - successCount} errors',
        );
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
          NothToast.error(
            context,
            'Microphone permission required for voice commands',
          );
          return;
        }
      }

      final started = await _voiceService.startListening();
      if (!started) {
        NothToast.error(context, 'Could not start voice recognition');
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

      // Check for recommendations after loading modes
      await _checkForRecommendations();
    } catch (e) {
      debugPrint('Error loading modes: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkForRecommendations() async {
    try {
      final recommendation = await _recommendationService.getCurrentRecommendation();
      if (mounted) {
        setState(() {
          _currentRecommendation = recommendation;
        });
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error checking recommendations: $e');
    }
  }

  Future<void> _onSuggestionAccepted(Recommendation recommendation) async {
    // Record feedback
    await _feedbackService.onSuggestionAccepted(recommendation);

    // Find and activate the mode
    final mode = _modes.firstWhere(
      (m) => m.id == recommendation.modeId,
      orElse: () => throw Exception('Mode not found'),
    );

    // Remove the suggestion
    setState(() {
      _currentRecommendation = null;
      _suggestionExpanded = false;
    });

    // Activate the mode
    await _toggleMode(mode);
  }

  Future<void> _onSuggestionDismissed(Recommendation recommendation) async {
    // Record feedback
    await _feedbackService.onSuggestionRejected(recommendation);

    // Remove the suggestion
    setState(() {
      _currentRecommendation = null;
      _suggestionExpanded = false;
    });

    if (mounted) {
      NothToast.info(context, 'Suggestion dismissed');
    }
  }

  Future<void> _onSuggestionBlocked(Recommendation recommendation) async {
    // Record feedback
    await _feedbackService.onSuggestionBlocked(recommendation);

    // Remove the suggestion
    setState(() {
      _currentRecommendation = null;
      _suggestionExpanded = false;
    });

    if (mounted) {
      NothToast.info(context, "Won't suggest this again");
    }
  }

  /// Show a demo suggestion for presentation purposes
  void _showDemoSuggestion() {
    final demo = _recommendationService.createDemoRecommendation(
      modeId: 'vision',
    );
    setState(() {
      _currentRecommendation = demo;
      _suggestionExpanded = false;
    });
    NothToast.success(context, 'Demo suggestion shown!');
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
        NothToast.info(
          context,
          'No flows set for turning ${isActivating ? "on" : "off"} ${mode.name}',
        );
      }

      NothToast.success(
        context,
        isActivating
            ? '${mode.name} mode activated'
            : '${mode.name} mode deactivated',
      );

      // Reload modes to reflect changes
      await _loadModes();
    } catch (e) {
      NothToast.error(context, 'Error toggling mode: $e');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    NothBottomSheet.show(
      context: context,
      title: '${mode.name} ${isActivating ? "ON" : "OFF"}',
      subtitle: '$successCount/${results.length} actions completed',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Simulation mode notice
          if (_isSimulation)
            NothPanel(
              padding: const EdgeInsets.all(12),
              backgroundColor: NothFlowsColors.warning.withOpacity(0.1),
              borderColor: NothFlowsColors.warning.withOpacity(0.3),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: isDark
                        ? NothFlowsColors.textSecondary
                        : NothFlowsColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Simulation mode: actions are logged but device changes are not applied.',
                      style: NothFlowsTypography.caption.copyWith(
                        color: isDark
                            ? NothFlowsColors.textSecondary
                            : NothFlowsColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Results list
          ...results.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: result.success
                          ? NothFlowsColors.success.withOpacity(0.15)
                          : NothFlowsColors.error.withOpacity(0.15),
                      borderRadius: NothFlowsShapes.borderRadiusSm,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: NothFlowsTypography.labelSmall.copyWith(
                          color: result.success
                              ? NothFlowsColors.success
                              : NothFlowsColors.error,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    result.success ? Icons.check_circle : Icons.error,
                    color: result.success
                        ? NothFlowsColors.success
                        : NothFlowsColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.actionType,
                          style: NothFlowsTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? NothFlowsColors.textPrimary
                                : NothFlowsColors.textPrimaryLight,
                          ),
                        ),
                        if (result.message != null)
                          Text(
                            result.message!,
                            style: NothFlowsTypography.caption.copyWith(
                              color: isDark
                                  ? NothFlowsColors.textSecondary
                                  : NothFlowsColors.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      actions: [
        NothButton.primary(
          label: 'Done',
          onPressed: () => Navigator.pop(context),
        ),
      ],
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

  void _showSettingsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    NothBottomSheet.show(
      context: context,
      title: 'Settings',
      showDivider: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Permissions
          NothListTile.navigation(
            title: 'Permissions',
            subtitle: 'Manage app permissions',
            leadingIcon: Icons.shield_outlined,
            leadingIconColor: NothFlowsColors.info,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PermissionsScreen(),
                ),
              );
            },
          ),

          const Divider(height: 1),

          // Wake Word Toggle
          StatefulBuilder(
            builder: (context, setSheetState) {
              return NothListTile(
                title: 'Always-on Voice',
                subtitle: _isWakeWordEnabled
                    ? 'Say "North-Flow" to activate'
                    : 'Enable hands-free voice commands',
                leadingIcon: _isWakeWordEnabled ? Icons.hearing : Icons.hearing_disabled,
                leadingIconColor: _isWakeWordEnabled ? const Color(0xFF5B4DFF) : null,
                trailing: NothToggle(
                  value: _isWakeWordEnabled,
                  onChanged: (value) async {
                    Navigator.pop(context);
                    await _toggleWakeWord();
                  },
                ),
              );
            },
          ),

          const Divider(height: 1),

          // Demo Suggestion (for presentations)
          NothListTile(
            title: 'Demo Smart Suggestion',
            subtitle: 'Show a sample habit suggestion',
            leadingIcon: Icons.lightbulb_outline,
            leadingIconColor: NothFlowsColors.info,
            onTap: () {
              Navigator.pop(context);
              _showDemoSuggestion();
            },
          ),

          const Divider(height: 1),

          // Reset Data
          NothListTile.destructive(
            title: 'Reset Data',
            subtitle: 'Clear all modes and flows',
            leadingIcon: Icons.delete_outline,
            onTap: () async {
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Data?'),
                  content: const Text(
                    'This will clear all modes and flows. This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Reset',
                        style: TextStyle(color: NothFlowsColors.error),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                await _storage.clearAll();
                _loadModes();
                NothToast.success(context, 'Data reset successfully');
              }
            },
          ),

          const SizedBox(height: 24),

          // App info
          Text(
            'NothFlows v1.0.0',
            style: NothFlowsTypography.caption.copyWith(
              color: isDark
                  ? NothFlowsColors.textTertiary
                  : NothFlowsColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Made with care for accessibility',
            style: NothFlowsTypography.caption.copyWith(
              color: isDark
                  ? NothFlowsColors.textDisabled
                  : NothFlowsColors.textDisabledLight,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffold = Scaffold(
      backgroundColor:
          isDark ? NothFlowsColors.nothingBlack : NothFlowsColors.surfaceLight,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: NothFlowsColors.nothingRed,
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadModes,
                color: NothFlowsColors.nothingRed,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header with logo
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo and title
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Logo
                                      SvgPicture.asset(
                                        'assets/icons/nothflows_logo.svg',
                                        width: 32,
                                        height: 32,
                                        colorFilter: ColorFilter.mode(
                                          isDark
                                              ? NothFlowsColors.nothingWhite
                                              : NothFlowsColors.nothingBlack,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'NothFlows',
                                          style: NothFlowsTypography.displaySmall
                                              .copyWith(
                                            color: isDark
                                                ? NothFlowsColors.textPrimary
                                                : NothFlowsColors.textPrimaryLight,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      if (_isSimulation) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: NothFlowsColors.warning
                                                .withOpacity(0.15),
                                            borderRadius: NothFlowsShapes
                                                .borderRadiusXs,
                                            border: Border.all(
                                              color: NothFlowsColors.warning,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            'SIM',
                                            style: NothFlowsTypography.labelSmall
                                                .copyWith(
                                              color: NothFlowsColors.warning,
                                              fontSize: 8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your Assistive Flows',
                                    style:
                                        NothFlowsTypography.bodyMedium.copyWith(
                                      color: isDark
                                          ? NothFlowsColors.textSecondary
                                          : NothFlowsColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Settings button
                            IconButton(
                              onPressed: _showSettingsSheet,
                              icon: Icon(
                                Icons.settings_outlined,
                                color: isDark
                                    ? NothFlowsColors.textSecondary
                                    : NothFlowsColors.textSecondaryLight,
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

                    // Smart suggestions
                    if (_currentRecommendation != null)
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Show the current recommendation as a card
                            SuggestionCard(
                              recommendation: _currentRecommendation!,
                              onAccept: () =>
                                  _onSuggestionAccepted(_currentRecommendation!),
                              onDismiss: () =>
                                  _onSuggestionDismissed(_currentRecommendation!),
                              onBlock: () =>
                                  _onSuggestionBlocked(_currentRecommendation!),
                              isExpanded: _suggestionExpanded,
                              onToggleExpand: () {
                                setState(() {
                                  _suggestionExpanded = !_suggestionExpanded;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
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
                              padding: const EdgeInsets.only(bottom: 12),
                              child: NothModeCard(
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

                    // Bottom spacing for action bar
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ),
      ),

      // Bottom action bar
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          decoration: BoxDecoration(
            color: isDark
                ? NothFlowsColors.surfaceDark
                : NothFlowsColors.surfaceLightAlt,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? NothFlowsColors.borderDark
                    : NothFlowsColors.borderLight,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Voice command button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleVoiceListening,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? NothFlowsColors.error
                          : NothFlowsColors.nothingRed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: NothFlowsColors.nothingWhite,
                      size: 24,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Daily Check-In button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DailyCheckInScreen(),
                        ),
                      );
                    },
                    borderRadius: NothFlowsShapes.borderRadiusFull,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? NothFlowsColors.surfaceDarkAlt
                            : NothFlowsColors.surfaceLight,
                        borderRadius: NothFlowsShapes.borderRadiusFull,
                        border: Border.all(
                          color: isDark
                              ? NothFlowsColors.borderDark
                              : NothFlowsColors.borderLight,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_outline,
                            color: NothFlowsColors.nothingRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Daily Check-In',
                            style: NothFlowsTypography.buttonMedium.copyWith(
                              color: isDark
                                  ? NothFlowsColors.textPrimary
                                  : NothFlowsColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap in Stack for voice listening overlay
    return Stack(
      children: [
        scaffold,
        // Voice listening overlay
        if (_isListening)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleVoiceListening,
              child: Container(
                color: NothFlowsColors.nothingBlack.withOpacity(0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated microphone
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 1.2),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: NothFlowsColors.nothingRed,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        NothFlowsColors.nothingRed.withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.mic,
                                color: NothFlowsColors.nothingWhite,
                                size: 48,
                              ),
                            ),
                          );
                        },
                        onEnd: () {
                          if (mounted && _isListening) {
                            setState(() {});
                          }
                        },
                      ),

                      const SizedBox(height: 32),

                      // Listening text
                      Text(
                        'Listening...',
                        style: NothFlowsTypography.displaySmall.copyWith(
                          color: NothFlowsColors.nothingWhite,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Recognized text
                      if (_recognizedText.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: NothFlowsColors.surfaceDark,
                            borderRadius: NothFlowsShapes.borderRadiusMd,
                            border: Border.all(
                              color: NothFlowsColors.borderDark,
                            ),
                          ),
                          child: Text(
                            '"$_recognizedText"',
                            textAlign: TextAlign.center,
                            style: NothFlowsTypography.bodyLarge.copyWith(
                              color: NothFlowsColors.textPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Hint text
                      Text(
                        'Say "Activate vision assist" or "Set brightness to 50"',
                        textAlign: TextAlign.center,
                        style: NothFlowsTypography.bodyMedium.copyWith(
                          color: NothFlowsColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tap to cancel
                      Text(
                        'Tap anywhere to cancel',
                        style: NothFlowsTypography.caption.copyWith(
                          color: NothFlowsColors.textTertiary,
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
}

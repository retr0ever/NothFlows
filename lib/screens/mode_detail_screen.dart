import 'package:flutter/material.dart';
import '../models/mode_model.dart';
import '../models/flow_dsl.dart';
import '../services/cactus_llm_service.dart';
import '../services/storage_service.dart';
import '../widgets/glass_panel.dart';
import '../widgets/flow_tile.dart';
import '../widgets/debug_banner.dart';
import 'flow_preview_sheet.dart';

/// Detail screen for managing flows in a mode
class ModeDetailScreen extends StatefulWidget {
  final ModeModel mode;

  const ModeDetailScreen({
    super.key,
    required this.mode,
  });

  @override
  State<ModeDetailScreen> createState() => _ModeDetailScreenState();
}

class _ModeDetailScreenState extends State<ModeDetailScreen> {
  final _llmService = CactusLLMService();
  final _storage = StorageService();
  final _inputController = TextEditingController();

  late ModeModel _mode;
  bool _isProcessing = false;
  bool _isInitialisingLLM = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _initialiseLLM();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _initialiseLLM() async {
    if (_llmService.isReady) return;

    setState(() => _isInitialisingLLM = true);

    try {
      await _llmService.initialise();
      if (mounted) {
        setState(() => _isInitialisingLLM = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialisingLLM = false);
        _showSnackBar('Error initialising AI: $e');
      }
    }
  }

  Future<void> _addFlow(String instruction) async {
    if (instruction.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      debugPrint('[ModeDetail] Parsing instruction: $instruction');

      // Parse instruction using Cactus LLM
      final dsl = await _llmService.parseInstruction(
        instruction: instruction,
        mode: _mode.id,
      );

      debugPrint('[ModeDetail] Parse result: ${dsl?.toJson()}');

      if (dsl == null) {
        final errorMsg = 'Could not parse instruction. Try rephrasing.\n\nInstruction: "$instruction"';
        debugPrint('[ModeDetail] ERROR: $errorMsg');
        _showSnackBar(errorMsg);
        if (mounted) {
          DebugSnackbar.showError(context, 'LLM parsing failed - check debug output');
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Show preview sheet
      if (mounted) {
        final confirmed = await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => FlowPreviewSheet(flow: dsl),
        );

        if (confirmed == true) {
          // Save flow
          await _storage.addFlowToMode(_mode.id, dsl);

          // Reload mode
          final updatedMode = await _storage.getMode(_mode.id);
          if (updatedMode != null && mounted) {
            setState(() => _mode = updatedMode);
          }

          _inputController.clear();
          _showSnackBar('Flow added successfully');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[ModeDetail] ERROR adding flow: $e');
      debugPrint('[ModeDetail] Stack trace: $stackTrace');
      _showSnackBar('Error adding flow: $e');
      if (mounted) {
        DebugSnackbar.showError(
          context,
          'Exception: ${e.toString()}\n\nCheck console for stack trace',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _deleteFlow(String flowId) async {
    await _storage.removeFlowFromMode(_mode.id, flowId);

    final updatedMode = await _storage.getMode(_mode.id);
    if (updatedMode != null && mounted) {
      setState(() => _mode = updatedMode);
      _showSnackBar('Flow removed');
    }
  }

  void _addExampleFlow(String example) {
    _inputController.text = example;
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
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF000000)
          : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),

                  const SizedBox(width: 8),

                  // Mode icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _mode.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _mode.icon,
                      color: _mode.color,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Mode info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mode.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${_mode.flows.length} ${_mode.flows.length == 1 ? 'flow' : 'flows'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Add flow input
                  GlassPanel(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add a flow',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Input field
                        TextField(
                          controller: _inputController,
                          decoration: InputDecoration(
                            hintText: 'Describe what you want to happen...',
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.4),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color!
                                    .withOpacity(0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color!
                                    .withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _mode.color,
                                width: 2,
                              ),
                            ),
                            suffixIcon: _isProcessing || _isInitialisingLLM
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.arrow_forward),
                                    onPressed: () =>
                                        _addFlow(_inputController.text),
                                  ),
                          ),
                          onSubmitted: _addFlow,
                          maxLines: null,
                          textInputAction: TextInputAction.done,
                        ),

                        if (_isInitialisingLLM) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Loading AI model... This may take a moment.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Example flows
                  const Text(
                    'Examples',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _mode.exampleFlows.map((example) {
                      return InkWell(
                        onTap: () => _addExampleFlow(example),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .color!
                                  .withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            example,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Active flows
                  if (_mode.flows.isNotEmpty) ...[
                    const Text(
                      'Active flows',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ..._mode.flows.map((flow) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FlowTile(
                          flow: flow,
                          onTap: () async {
                            await showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) =>
                                  FlowPreviewSheet(flow: flow, isEditing: true),
                            );
                          },
                          onDelete: () => _deleteFlow(flow.id!),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

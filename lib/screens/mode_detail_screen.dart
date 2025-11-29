import 'package:flutter/material.dart';
import '../models/mode_model.dart';
import '../models/flow_dsl.dart';
import '../services/cactus_llm_service.dart';
import '../services/storage_service.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';
import '../theme/nothflows_spacing.dart';
import '../widgets/noth_panel.dart';
import '../widgets/noth_text_field.dart';
import '../widgets/noth_chip.dart';
import '../widgets/noth_toast.dart';
import '../widgets/flow_tile.dart';
import 'flow_preview_sheet.dart';

/// Detail screen for managing flows in a mode with Nothing-style design
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
  bool _isInitializingLLM = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _initializeLLM();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _initializeLLM() async {
    if (_llmService.isReady) return;

    setState(() => _isInitializingLLM = true);

    try {
      await _llmService.initialise();
      if (mounted) {
        setState(() => _isInitializingLLM = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitializingLLM = false);
        NothToast.error(context, 'Error initializing AI: $e');
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
        NothToast.error(
          context,
          'Could not parse instruction. Try rephrasing.',
        );
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
          NothToast.success(context, 'Flow added successfully');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[ModeDetail] ERROR adding flow: $e');
      debugPrint('[ModeDetail] Stack trace: $stackTrace');
      NothToast.error(context, 'Error adding flow');
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
      NothToast.info(context, 'Flow removed');
    }
  }

  void _addExampleFlow(String example) {
    _inputController.text = example;
  }

  String _buildConditionsText(FlowConditions conditions) {
    final parts = <String>[];

    if (conditions.ambientLight != null) {
      parts.add('Light: ${conditions.ambientLight}');
    }
    if (conditions.noiseLevel != null) {
      parts.add('Noise: ${conditions.noiseLevel}');
    }
    if (conditions.deviceMotion != null) {
      parts.add('Motion: ${conditions.deviceMotion}');
    }
    if (conditions.timeOfDay != null) {
      parts.add('Time: ${conditions.timeOfDay}');
    }
    if (conditions.batteryLevel != null) {
      parts.add('Battery: ${conditions.batteryLevel}%');
    }

    return parts.isEmpty
        ? 'No conditions'
        : 'Triggers when ${parts.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 400 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor:
          isDark ? NothFlowsColors.nothingBlack : NothFlowsColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                NothFlowsSpacing.md,
                horizontalPadding,
                NothFlowsSpacing.md,
              ),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark
                          ? NothFlowsColors.textPrimary
                          : NothFlowsColors.textPrimaryLight,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  const SizedBox(width: 12),

                  // Mode icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _mode.color.withOpacity(0.15),
                      borderRadius: NothFlowsShapes.borderRadiusMd,
                    ),
                    child: Icon(
                      _mode.icon,
                      color: _mode.color,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Mode info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mode.name,
                          style: NothFlowsTypography.headingLarge.copyWith(
                            color: isDark
                                ? NothFlowsColors.textPrimary
                                : NothFlowsColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          '${_mode.flows.length} ${_mode.flows.length == 1 ? 'flow' : 'flows'}',
                          style: NothFlowsTypography.bodySmall.copyWith(
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
            ),

            // Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                children: [
                  // Add flow input
                  NothPanel(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add a new flow',
                          style: NothFlowsTypography.headingSmall.copyWith(
                            color: isDark
                                ? NothFlowsColors.textPrimary
                                : NothFlowsColors.textPrimaryLight,
                          ),
                        ),

                        const SizedBox(height: NothFlowsSpacing.sm),

                        // Input field
                        NothTextField(
                          controller: _inputController,
                          hintText: 'Describe what should happen...',
                          focusColor: _mode.color,
                          textInputAction: TextInputAction.done,
                          onSubmitted: _addFlow,
                          suffixIcon: _isProcessing || _isInitializingLLM
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _mode.color,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(
                                    Icons.arrow_forward,
                                    color: _mode.color,
                                  ),
                                  onPressed: () =>
                                      _addFlow(_inputController.text),
                                ),
                        ),

                        if (_isInitializingLLM) ...[
                          const SizedBox(height: NothFlowsSpacing.sm),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_outlined,
                                size: 14,
                                color: isDark
                                    ? NothFlowsColors.textTertiary
                                    : NothFlowsColors.textTertiaryLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Loading AI model...',
                                style: NothFlowsTypography.caption.copyWith(
                                  color: isDark
                                      ? NothFlowsColors.textTertiary
                                      : NothFlowsColors.textTertiaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: NothFlowsSpacing.lg),

                  // Example flows
                  Text(
                    'Try an example',
                    style: NothFlowsTypography.labelMedium.copyWith(
                      color: isDark
                          ? NothFlowsColors.textSecondary
                          : NothFlowsColors.textSecondaryLight,
                    ),
                  ),

                  const SizedBox(height: NothFlowsSpacing.sm),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _mode.exampleFlows.map((example) {
                      return NothChip(
                        label: example,
                        onTap: () => _addExampleFlow(example),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: NothFlowsSpacing.xl),

                  // Active flows
                  if (_mode.flows.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          'Active flows',
                          style: NothFlowsTypography.labelMedium.copyWith(
                            color: isDark
                                ? NothFlowsColors.textSecondary
                                : NothFlowsColors.textSecondaryLight,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _mode.color.withOpacity(0.15),
                            borderRadius: NothFlowsShapes.borderRadiusSm,
                          ),
                          child: Text(
                            '${_mode.flows.length}',
                            style: NothFlowsTypography.labelSmall.copyWith(
                              color: _mode.color,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: NothFlowsSpacing.sm),

                    ..._mode.flows.map((flow) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FlowTile(
                              flow: flow,
                              onTap: () async {
                                await showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (context) => FlowPreviewSheet(
                                    flow: flow,
                                    isEditing: true,
                                  ),
                                );
                              },
                              onDelete: () => _deleteFlow(flow.id!),
                            ),
                            // Show conditions if present
                            if (flow.conditions != null &&
                                !flow.conditions!.isEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _mode.color.withOpacity(0.05),
                                  borderRadius: NothFlowsShapes.borderRadiusSm,
                                  border: Border.all(
                                    color: _mode.color.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.sensors_outlined,
                                      size: 16,
                                      color: _mode.color,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _buildConditionsText(flow.conditions!),
                                        style:
                                            NothFlowsTypography.caption.copyWith(
                                          color: isDark
                                              ? NothFlowsColors.textSecondary
                                              : NothFlowsColors.textSecondaryLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],

                  // Empty state
                  if (_mode.flows.isEmpty) ...[
                    const SizedBox(height: NothFlowsSpacing.xl),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 48,
                            color: isDark
                                ? NothFlowsColors.textDisabled
                                : NothFlowsColors.textDisabledLight,
                          ),
                          const SizedBox(height: NothFlowsSpacing.md),
                          Text(
                            'No flows yet',
                            style: NothFlowsTypography.headingSmall.copyWith(
                              color: isDark
                                  ? NothFlowsColors.textSecondary
                                  : NothFlowsColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: NothFlowsSpacing.xs),
                          Text(
                            'Add a flow above to get started',
                            style: NothFlowsTypography.bodySmall.copyWith(
                              color: isDark
                                  ? NothFlowsColors.textTertiary
                                  : NothFlowsColors.textTertiaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: NothFlowsSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

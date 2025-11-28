import 'dart:io';
import 'package:flutter/material.dart';
import '../models/mode_model.dart';
import '../models/flow_dsl.dart';
import '../services/storage_service.dart';
import '../services/automation_executor.dart';
import '../widgets/mode_card.dart';
import 'mode_detail_screen.dart';

/// Home screen showing all available modes
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  final _executor = AutomationExecutor();

  List<ModeModel> _modes = [];
  bool _isLoading = true;
  final bool _isSimulation = !Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    _loadModes();
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
    return Scaffold(
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
                              'Smart modes for your Nothing Phone',
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

      // Settings button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSettingsSheet(),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        child: Icon(
          Icons.settings,
          color: Theme.of(context).iconTheme.color,
        ),
      ),
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

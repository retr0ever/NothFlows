import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mode_model.dart';
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
      // Toggle the mode
      await _storage.toggleMode(mode.id);

      // If activating, execute all flows
      if (!mode.isActive) {
        for (final flow in mode.flows) {
          await _executor.executeFlow(flow);
        }

        _showSnackBar('${mode.name} mode activated');
      } else {
        _showSnackBar('${mode.name} mode deactivated');
      }

      // Reload modes to reflect changes
      await _loadModes();
    } catch (e) {
      _showSnackBar('Error toggling mode: $e');
    }
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
                            const Text(
                              'NothFlows',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.5,
                              ),
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

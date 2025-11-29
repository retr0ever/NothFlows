import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';
import '../theme/nothflows_spacing.dart';
import '../widgets/noth_button.dart';
import '../widgets/noth_panel.dart';
import 'home_screen.dart';

/// Screen for requesting all necessary permissions with Nothing-style design
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _permissionService = PermissionService();
  bool _isRequesting = false;
  Map<String, bool> _permissionStatus = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final status = await _permissionService.checkAllPermissions();
      setState(() {
        _permissionStatus = status;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error checking permissions: $e';
      });
      debugPrint('[Permissions] Error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isRequesting = true;
      _error = null;
    });

    try {
      final results = await _permissionService.requestAllPermissions();

      // Check if any critical permissions were denied
      final deniedPermissions = results.entries
          .where((entry) => entry.value != PermissionStatus.granted)
          .map((entry) => entry.key.toString())
          .toList();

      if (deniedPermissions.isNotEmpty) {
        setState(() {
          _error =
              'Some permissions were denied. You can grant them later in settings.';
        });
      }

      // Refresh status
      await _checkPermissions();

      // If storage permission granted, navigate to home
      if (_permissionStatus['Storage'] == true ||
          _permissionStatus['Manage External Storage'] == true) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error requesting permissions: $e';
      });
      debugPrint('[Permissions] Error: $e');
    } finally {
      setState(() {
        _isRequesting = false;
      });
    }
  }

  Future<void> _skipPermissions() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NothFlowsColors.surfaceDarkAlt,
        shape: RoundedRectangleBorder(
          borderRadius: NothFlowsShapes.borderRadiusXl,
        ),
        title: Text(
          'Skip Permissions?',
          style: NothFlowsTypography.headingMedium.copyWith(
            color: NothFlowsColors.textPrimary,
          ),
        ),
        content: Text(
          'Some features may not work without the required permissions. You can grant them later in the app settings.',
          style: NothFlowsTypography.bodyMedium.copyWith(
            color: NothFlowsColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: NothFlowsColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Skip',
              style: TextStyle(color: NothFlowsColors.nothingRed),
            ),
          ),
        ],
      ),
    );

    if (proceed == true && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grantedCount = _permissionStatus.values.where((v) => v).length;
    final totalCount = _permissionStatus.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 400 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor:
          isDark ? NothFlowsColors.nothingBlack : NothFlowsColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: NothFlowsSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: NothFlowsSpacing.lg),

                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: NothFlowsColors.nothingRed.withOpacity(0.1),
                        borderRadius: NothFlowsShapes.borderRadiusLg,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: NothFlowsColors.nothingRed,
                        size: 28,
                      ),
                    ),

                    const SizedBox(height: NothFlowsSpacing.lg),

                    // Title
                    Text(
                      'Permissions',
                      style: NothFlowsTypography.displaySmall.copyWith(
                        color: isDark
                            ? NothFlowsColors.textPrimary
                            : NothFlowsColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Required',
                      style: NothFlowsTypography.displaySmall.copyWith(
                        color: isDark
                            ? NothFlowsColors.textPrimary
                            : NothFlowsColors.textPrimaryLight,
                      ),
                    ),

                    const SizedBox(height: NothFlowsSpacing.sm),

                    // Description
                    Text(
                      'NothFlows needs access to automate your device settings and files.',
                      style: NothFlowsTypography.bodyMedium.copyWith(
                        color: isDark
                            ? NothFlowsColors.textSecondary
                            : NothFlowsColors.textSecondaryLight,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: NothFlowsSpacing.xl),

                    // Error message
                    if (_error != null) ...[
                      NothPanel(
                        padding: const EdgeInsets.all(14),
                        backgroundColor: NothFlowsColors.warning.withOpacity(0.1),
                        borderColor: NothFlowsColors.warning.withOpacity(0.3),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_outlined,
                              color: NothFlowsColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: NothFlowsTypography.bodySmall.copyWith(
                                  color: NothFlowsColors.warning,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: NothFlowsColors.warning,
                              ),
                              onPressed: () => setState(() => _error = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: NothFlowsSpacing.lg),
                    ],

                    // Permission explanations
                    NothPanel(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildPermissionExplanation(
                            icon: Icons.folder_outlined,
                            title: 'Storage',
                            subtitle:
                                'Clean screenshots and downloads automatically',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            color: isDark
                                ? NothFlowsColors.borderDark
                                : NothFlowsColors.borderLight,
                          ),
                          const SizedBox(height: 16),
                          _buildPermissionExplanation(
                            icon: Icons.settings_outlined,
                            title: 'System Settings',
                            subtitle: 'Adjust brightness, volume, and other settings',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            color: isDark
                                ? NothFlowsColors.borderDark
                                : NothFlowsColors.borderLight,
                          ),
                          const SizedBox(height: 16),
                          _buildPermissionExplanation(
                            icon: Icons.sensors_outlined,
                            title: 'Sensors',
                            subtitle:
                                'Context-aware automation using light and motion',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: NothFlowsSpacing.md),

                    // Permission status
                    if (_permissionStatus.isNotEmpty) ...[
                      NothPanel(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Status',
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
                                    color: (grantedCount == totalCount
                                            ? NothFlowsColors.success
                                            : NothFlowsColors.warning)
                                        .withOpacity(0.15),
                                    borderRadius: NothFlowsShapes.borderRadiusSm,
                                  ),
                                  child: Text(
                                    '$grantedCount/$totalCount',
                                    style: NothFlowsTypography.labelSmall.copyWith(
                                      color: grantedCount == totalCount
                                          ? NothFlowsColors.success
                                          : NothFlowsColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._permissionStatus.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: entry.value
                                            ? NothFlowsColors.success
                                            : NothFlowsColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style:
                                            NothFlowsTypography.bodySmall.copyWith(
                                          color: isDark
                                              ? NothFlowsColors.textPrimary
                                              : NothFlowsColors.textPrimaryLight,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      entry.value
                                          ? Icons.check_circle_outline
                                          : Icons.cancel_outlined,
                                      color: entry.value
                                          ? NothFlowsColors.success
                                          : NothFlowsColors.error,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: NothFlowsSpacing.lg),
                  ],
                ),
              ),
            ),

            // Fixed bottom buttons
            Container(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                NothFlowsSpacing.md,
                horizontalPadding,
                NothFlowsSpacing.lg + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? NothFlowsColors.nothingBlack
                    : NothFlowsColors.surfaceLight,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? NothFlowsColors.borderDark
                        : NothFlowsColors.borderLight,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NothButton.primary(
                    label: 'Grant Permissions',
                    onPressed: _isRequesting ? null : _requestPermissions,
                    isLoading: _isRequesting,
                  ),
                  const SizedBox(height: NothFlowsSpacing.sm),
                  NothButton.ghost(
                    label: 'Skip for now',
                    onPressed: _isRequesting ? null : _skipPermissions,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionExplanation({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: NothFlowsColors.nothingRed.withOpacity(0.1),
            borderRadius: NothFlowsShapes.borderRadiusSm,
          ),
          child: Icon(
            icon,
            color: NothFlowsColors.nothingRed,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: NothFlowsTypography.bodyMedium.copyWith(
                  color: isDark
                      ? NothFlowsColors.textPrimary
                      : NothFlowsColors.textPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
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
    );
  }
}

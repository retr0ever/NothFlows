import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';
import '../widgets/debug_banner.dart';
import 'home_screen.dart';

/// Screen for requesting all necessary permissions
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
          .where((entry) => !entry.value.isGranted)
          .map((entry) => entry.key.toString())
          .toList();

      if (deniedPermissions.isNotEmpty) {
        setState(() {
          _error = 'Some permissions were denied: ${deniedPermissions.join(', ')}';
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
    // Show warning
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Permissions?'),
        content: const Text(
          'Some features may not work without the required permissions. '
          'You can grant them later in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Skip'),
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
    final grantedCount = _permissionStatus.values.where((v) => v).length;
    final totalCount = _permissionStatus.length;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4DFF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF5B4DFF),
                  size: 32,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'Permissions Required',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'NothFlows needs certain permissions to automate your device. '
                'This is a test build, so errors will be displayed for debugging.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Error banner
              if (_error != null)
                DebugBanner(
                  error: _error,
                  onDismiss: () => setState(() => _error = null),
                ),

              const SizedBox(height: 16),

              // Permission status
              if (_permissionStatus.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Permission Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$grantedCount/$totalCount granted',
                            style: TextStyle(
                              fontSize: 12,
                              color: grantedCount == totalCount
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._permissionStatus.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                entry.value
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: entry.value ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Grant button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B4DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Grant Permissions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Skip button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: _isRequesting ? null : _skipPermissions,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Debug info
              Text(
                'Debug Mode: Errors will be shown as banners',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

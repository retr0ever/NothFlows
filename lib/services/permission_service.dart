import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing runtime permissions
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Check if all required permissions are granted
  Future<Map<String, bool>> checkAllPermissions() async {
    final results = <String, bool>{};

    // Storage permissions
    results['Storage'] = await Permission.storage.isGranted;
    results['Manage External Storage'] = await Permission.manageExternalStorage.isGranted;

    // Media permissions (Android 13+)
    results['Photos'] = await Permission.photos.isGranted;
    results['Videos'] = await Permission.videos.isGranted;
    results['Audio'] = await Permission.audio.isGranted;

    // System permissions
    results['Notification Policy'] = await Permission.accessNotificationPolicy.isGranted;
    results['Bluetooth'] = await Permission.bluetooth.isGranted;
    results['Bluetooth Connect'] = await Permission.bluetoothConnect.isGranted;

    // Voice command permissions
    results['Microphone'] = await Permission.microphone.isGranted;

    return results;
  }

  /// Request all necessary permissions
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    debugPrint('[Permissions] Requesting all permissions...');

    final permissions = [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
      Permission.accessNotificationPolicy,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.microphone,
    ];

    final results = await permissions.request();

    // Log results
    results.forEach((permission, status) {
      debugPrint('[Permissions] ${permission.toString()}: ${status.toString()}');
    });

    return results;
  }

  /// Request storage permissions specifically
  Future<bool> requestStoragePermissions() async {
    debugPrint('[Permissions] Requesting storage permissions...');

    // Request MANAGE_EXTERNAL_STORAGE for Android 11+
    final manageStatus = await Permission.manageExternalStorage.request();
    debugPrint('[Permissions] Manage External Storage: $manageStatus');

    if (manageStatus.isGranted) {
      return true;
    }

    // Fallback to regular storage permission
    final storageStatus = await Permission.storage.request();
    debugPrint('[Permissions] Storage: $storageStatus');

    return storageStatus.isGranted;
  }

  /// Request notification policy permission (for DND)
  Future<bool> requestNotificationPolicyPermission() async {
    debugPrint('[Permissions] Requesting notification policy permission...');
    final status = await Permission.accessNotificationPolicy.request();
    debugPrint('[Permissions] Notification Policy: $status');
    return status.isGranted;
  }

  /// Request bluetooth permissions
  Future<bool> requestBluetoothPermissions() async {
    debugPrint('[Permissions] Requesting bluetooth permissions...');

    final bluetooth = await Permission.bluetooth.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();

    debugPrint('[Permissions] Bluetooth: $bluetooth');
    debugPrint('[Permissions] Bluetooth Connect: $bluetoothConnect');

    return bluetooth.isGranted && bluetoothConnect.isGranted;
  }

  /// Get permission status summary
  Future<String> getPermissionSummary() async {
    final results = await checkAllPermissions();
    final granted = results.values.where((v) => v).length;
    final total = results.length;

    return '$granted/$total permissions granted';
  }

  /// Show permission rationale dialog
  Future<bool?> showPermissionRationale(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Grant'),
          ),
        ],
      ),
    );
  }

  /// Open app settings
  Future<void> launchAppSettings() async {
    debugPrint('[Permissions] Opening app settings...');
    await openAppSettings();
  }
}

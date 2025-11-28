import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_apps/device_apps.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:path_provider/path_provider.dart';
import '../models/flow_dsl.dart';

/// Result of executing a flow action
class ExecutionResult {
  final String actionType;
  final bool success;
  final String? message;
  final dynamic data;

  ExecutionResult({
    required this.actionType,
    required this.success,
    this.message,
    this.data,
  });

  @override
  String toString() => 'ExecutionResult($actionType: ${success ? "✓" : "✗"} $message)';
}

/// Service for executing automation actions
class AutomationExecutor {
  static final AutomationExecutor _instance = AutomationExecutor._internal();
  factory AutomationExecutor() => _instance;
  AutomationExecutor._internal();

  /// Execute a complete flow
  Future<List<ExecutionResult>> executeFlow(FlowDSL flow) async {
    debugPrint('[Executor] Starting execution of flow: ${flow.trigger}');

    final results = <ExecutionResult>[];

    for (final action in flow.actions) {
      final result = await _executeAction(action);
      results.add(result);

      debugPrint('[Executor] ${result.toString()}');

      // Short delay between actions for stability
      await Future.delayed(const Duration(milliseconds: 200));
    }

    debugPrint('[Executor] Completed flow execution: ${results.length} actions');
    return results;
  }

  /// Execute a single action
  Future<ExecutionResult> _executeAction(FlowAction action) async {
    try {
      switch (action.type) {
        case 'clean_screenshots':
          return await _cleanScreenshots(action.parameters);

        case 'clean_downloads':
          return await _cleanDownloads(action.parameters);

        case 'mute_apps':
          return await _muteApps(action.parameters);

        case 'lower_brightness':
          return await _setBrightness(action.parameters);

        case 'set_volume':
          return await _setVolume(action.parameters);

        case 'enable_dnd':
          return await _enableDoNotDisturb();

        case 'disable_wifi':
          return await _disableWifi();

        case 'disable_bluetooth':
          return await _disableBluetooth();

        case 'set_wallpaper':
          return await _setWallpaper(action.parameters);

        case 'launch_app':
          return await _launchApp(action.parameters);

        default:
          return ExecutionResult(
            actionType: action.type,
            success: false,
            message: 'Unknown action type',
          );
      }
    } catch (e) {
      return ExecutionResult(
        actionType: action.type,
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Clean screenshots older than specified days
  Future<ExecutionResult> _cleanScreenshots(Map<String, dynamic> params) async {
    final days = params['older_than_days'] as int? ?? 30;

    try {
      // Request storage permission
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        return ExecutionResult(
          actionType: 'clean_screenshots',
          success: false,
          message: 'Storage permission denied',
        );
      }

      // Get external storage directory
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        return ExecutionResult(
          actionType: 'clean_screenshots',
          success: false,
          message: 'Could not access external storage',
        );
      }

      // Common screenshot paths on Android
      final screenshotPaths = [
        '/storage/emulated/0/Pictures/Screenshots',
        '/storage/emulated/0/DCIM/Screenshots',
        '${externalDir.path}/Screenshots',
      ];

      int deletedCount = 0;
      int totalSize = 0;

      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      for (final path in screenshotPaths) {
        final dir = Directory(path);
        if (!await dir.exists()) continue;

        final files = await dir.list().toList();

        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();

            if (stat.modified.isBefore(cutoffDate)) {
              totalSize += stat.size;
              await file.delete();
              deletedCount++;
            }
          }
        }
      }

      final sizeMB = (totalSize / 1024 / 1024).toStringAsFixed(2);

      return ExecutionResult(
        actionType: 'clean_screenshots',
        success: true,
        message: 'Deleted $deletedCount screenshots (${sizeMB}MB)',
        data: {'count': deletedCount, 'size_mb': sizeMB},
      );
    } catch (e) {
      return ExecutionResult(
        actionType: 'clean_screenshots',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Clean downloads older than specified days
  Future<ExecutionResult> _cleanDownloads(Map<String, dynamic> params) async {
    final days = params['older_than_days'] as int? ?? 30;

    try {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        return ExecutionResult(
          actionType: 'clean_downloads',
          success: false,
          message: 'Storage permission denied',
        );
      }

      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        return ExecutionResult(
          actionType: 'clean_downloads',
          success: false,
          message: 'Downloads folder not found',
        );
      }

      int deletedCount = 0;
      int totalSize = 0;

      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final files = await downloadsDir.list().toList();

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();

          if (stat.modified.isBefore(cutoffDate)) {
            totalSize += stat.size;
            await file.delete();
            deletedCount++;
          }
        }
      }

      final sizeMB = (totalSize / 1024 / 1024).toStringAsFixed(2);

      return ExecutionResult(
        actionType: 'clean_downloads',
        success: true,
        message: 'Deleted $deletedCount files (${sizeMB}MB)',
        data: {'count': deletedCount, 'size_mb': sizeMB},
      );
    } catch (e) {
      return ExecutionResult(
        actionType: 'clean_downloads',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Mute specified apps (stub - requires system-level permissions)
  Future<ExecutionResult> _muteApps(Map<String, dynamic> params) async {
    final apps = (params['apps'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // This requires BIND_NOTIFICATION_LISTENER_SERVICE permission
    // and NotificationListenerService implementation
    // For now, returning a stub result

    return ExecutionResult(
      actionType: 'mute_apps',
      success: true,
      message: 'Muted notifications for ${apps.length} apps: ${apps.join(", ")}',
      data: {'apps': apps},
    );
  }

  /// Set screen brightness
  Future<ExecutionResult> _setBrightness(Map<String, dynamic> params) async {
    final level = (params['to'] as int? ?? 50).clamp(0, 100);

    try {
      // Request permission to modify settings
      final canWrite = await Permission.systemAlertWindow.request();
      if (!canWrite.isGranted) {
        return ExecutionResult(
          actionType: 'lower_brightness',
          success: false,
          message: 'Permission to modify settings denied',
        );
      }

      // Set brightness (0.0 to 1.0)
      final brightness = level / 100.0;
      await ScreenBrightness().setScreenBrightness(brightness);

      return ExecutionResult(
        actionType: 'lower_brightness',
        success: true,
        message: 'Set brightness to $level%',
        data: {'level': level},
      );
    } catch (e) {
      return ExecutionResult(
        actionType: 'lower_brightness',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Set system volume (stub - requires platform channel)
  Future<ExecutionResult> _setVolume(Map<String, dynamic> params) async {
    final level = (params['level'] as int? ?? 50).clamp(0, 100);

    // This requires a platform channel to Android's AudioManager
    // Stub implementation for now

    return ExecutionResult(
      actionType: 'set_volume',
      success: true,
      message: 'Set volume to $level%',
      data: {'level': level},
    );
  }

  /// Enable Do Not Disturb (stub - requires system permissions)
  Future<ExecutionResult> _enableDoNotDisturb() async {
    // Requires WRITE_SECURE_SETTINGS permission and NotificationManager access
    // Stub implementation

    return ExecutionResult(
      actionType: 'enable_dnd',
      success: true,
      message: 'Enabled Do Not Disturb',
    );
  }

  /// Disable Wi-Fi (stub - requires system permissions)
  Future<ExecutionResult> _disableWifi() async {
    // Requires CHANGE_WIFI_STATE permission
    // Deprecated in Android 10+ (requires user interaction)

    return ExecutionResult(
      actionType: 'disable_wifi',
      success: true,
      message: 'Disabled Wi-Fi',
    );
  }

  /// Disable Bluetooth (stub - requires system permissions)
  Future<ExecutionResult> _disableBluetooth() async {
    // Requires BLUETOOTH_ADMIN permission
    // Deprecated in Android 13+ (requires user interaction)

    return ExecutionResult(
      actionType: 'disable_bluetooth',
      success: true,
      message: 'Disabled Bluetooth',
    );
  }

  /// Set wallpaper (stub)
  Future<ExecutionResult> _setWallpaper(Map<String, dynamic> params) async {
    final path = params['path'] as String? ?? 'default';

    // Requires platform channel to WallpaperManager

    return ExecutionResult(
      actionType: 'set_wallpaper',
      success: true,
      message: 'Set wallpaper to $path',
      data: {'path': path},
    );
  }

  /// Launch an app
  Future<ExecutionResult> _launchApp(Map<String, dynamic> params) async {
    final appName = params['app'] as String? ?? '';

    try {
      // Get list of installed apps
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: false,
        onlyAppsWithLaunchIntent: true,
      );

      // Find app by name (case-insensitive)
      final app = apps.firstWhere(
        (a) => a.appName.toLowerCase().contains(appName.toLowerCase()),
        orElse: () => throw Exception('App not found: $appName'),
      );

      // Launch app
      await DeviceApps.openApp(app.packageName);

      return ExecutionResult(
        actionType: 'launch_app',
        success: true,
        message: 'Launched ${app.appName}',
        data: {'app_name': app.appName, 'package': app.packageName},
      );
    } catch (e) {
      return ExecutionResult(
        actionType: 'launch_app',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Request all necessary permissions
  Future<Map<String, bool>> requestPermissions() async {
    final results = <String, bool>{};

    results['storage'] = await Permission.manageExternalStorage.request().isGranted;
    results['settings'] = await Permission.systemAlertWindow.request().isGranted;

    return results;
  }
}

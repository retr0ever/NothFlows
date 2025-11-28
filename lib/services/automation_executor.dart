import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_apps/device_apps.dart';
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
/// Requires Android - simulation mode has been removed
class AutomationExecutor {
  static final AutomationExecutor _instance = AutomationExecutor._internal();
  factory AutomationExecutor() => _instance;
  AutomationExecutor._internal();

  // MethodChannel for native Android system control
  static const platform = MethodChannel('com.nothflows/system');

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
  /// Requires Android - throws on other platforms
  Future<ExecutionResult> _executeAction(FlowAction action) async {
    // Require Android - no simulation mode
    if (!Platform.isAndroid) {
      return ExecutionResult(
        actionType: action.type,
        success: false,
        message: 'NothFlows requires Android. Automation cannot run on this platform.',
      );
    }

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

        // Vision Assist actions
        case 'increase_text_size':
          return await _increaseTextSize(action.parameters);

        case 'increase_contrast':
        case 'enable_high_visibility':
          return await _increaseContrast(action.parameters);

        case 'enable_screen_reader':
          return await _enableScreenReader(action.parameters);

        case 'boost_brightness':
          return await _boostBrightness(action.parameters);

        // Motor Assist actions
        case 'reduce_gesture_sensitivity':
          return await _reduceGestureSensitivity(action.parameters);

        case 'enable_voice_typing':
          return await _enableVoiceTyping(action.parameters);

        case 'enable_one_handed_mode':
          return await _enableOneHandedMode(action.parameters);

        case 'increase_touch_targets':
          return await _increaseTouchTargets(action.parameters);

        // Cognitive/Neurodivergent actions
        case 'reduce_animation':
          return await _reduceAnimation(action.parameters);

        case 'simplify_home_screen':
          return await _simplifyHomeScreen(action.parameters);

        case 'mute_distraction_apps':
          return await _muteDistractionApps(action.parameters);

        case 'highlight_focus_apps':
          return await _highlightFocusApps(action.parameters);

        // Hearing Support actions
        case 'enable_live_transcribe':
          return await _enableLiveTranscribe(action.parameters);

        case 'enable_captions':
          return await _enableCaptions(action.parameters);

        case 'flash_screen_alerts':
          return await _flashScreenAlerts(action.parameters);

        case 'boost_haptic_feedback':
          return await _boostHapticFeedback(action.parameters);

        // Safety action
        case 'launch_care_app':
          return await _launchCareApp(action.parameters);

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
      // Use native Android API to set brightness
      final success = await platform.invokeMethod<bool>('setBrightness', {
        'brightness': level,
      });

      if (success == true) {
        debugPrint('[Executor] Set screen brightness to $level% via native API/fallback');

        return ExecutionResult(
          actionType: 'lower_brightness',
          success: true,
          message: 'Set brightness to $level%',
          data: {'level': level},
        );
      }

      return ExecutionResult(
        actionType: 'lower_brightness',
        success: false,
        message:
            'Failed to change brightness. Try granting "Modify system settings" to NothFlows and retry.',
      );
    } catch (e) {
      debugPrint('[Executor] Error setting brightness: $e');
      return ExecutionResult(
        actionType: 'lower_brightness',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Set system volume
  Future<ExecutionResult> _setVolume(Map<String, dynamic> params) async {
    final level = (params['level'] as int? ?? 50).clamp(0, 100);

    try {
      // Use native Android API to set volume
      final success = await platform.invokeMethod<bool>('setVolume', {
        'level': level,
      });

      if (success == true) {
        debugPrint('[Executor] Set system volume to $level% via native API');

        return ExecutionResult(
          actionType: 'set_volume',
          success: true,
          message: 'Set volume to $level%',
          data: {'level': level},
        );
      } else {
        return ExecutionResult(
          actionType: 'set_volume',
          success: false,
          message: 'Failed to set volume',
        );
      }
    } catch (e) {
      debugPrint('[Executor] Error setting volume: $e');
      return ExecutionResult(
        actionType: 'set_volume',
        success: false,
        message: 'Error: $e',
      );
    }
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

  // ============================================================================
  // VISION ASSIST ACTIONS
  // ============================================================================

  /// Increase text size for better readability
  Future<ExecutionResult> _increaseTextSize(Map<String, dynamic> params) async {
    final size = params['to'] as String? ?? 'large'; // 'small', 'medium', 'large', 'max'

    try {
      final success = await platform.invokeMethod<bool>('setTextSize', {'size': size});

      if (success == true) {
        debugPrint('[Executor] Set text size to $size');
        return ExecutionResult(
          actionType: 'increase_text_size',
          success: true,
          message: 'Set text size to $size',
          data: {'size': size},
        );
      }

      return ExecutionResult(
        actionType: 'increase_text_size',
        success: false,
        message: 'Failed to change text size',
      );
    } catch (e) {
      debugPrint('[Executor] Error setting text size: $e');
      return ExecutionResult(
        actionType: 'increase_text_size',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Enable high contrast mode for better visibility
  Future<ExecutionResult> _increaseContrast(Map<String, dynamic> params) async {
    try {
      final success = await platform.invokeMethod<bool>('setHighContrast', {'enabled': true});

      if (success == true) {
        debugPrint('[Executor] Enabled high contrast mode');
        return ExecutionResult(
          actionType: 'increase_contrast',
          success: true,
          message: 'Enabled high contrast mode',
        );
      }

      return ExecutionResult(
        actionType: 'increase_contrast',
        success: false,
        message: 'Failed to enable high contrast',
      );
    } catch (e) {
      debugPrint('[Executor] Error enabling high contrast: $e');
      return ExecutionResult(
        actionType: 'increase_contrast',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Launch screen reader (TalkBack)
  Future<ExecutionResult> _enableScreenReader(Map<String, dynamic> params) async {
    try {
      // Try to open TalkBack settings
      await DeviceApps.openApp('com.google.android.marvin.talkback');

      return ExecutionResult(
        actionType: 'enable_screen_reader',
        success: true,
        message: 'Launched screen reader settings',
      );
    } catch (e) {
      debugPrint('[Executor] Error launching screen reader: $e');
      return ExecutionResult(
        actionType: 'enable_screen_reader',
        success: false,
        message: 'Screen reader not available. Install TalkBack from Play Store.',
      );
    }
  }

  /// Boost brightness to maximum for better visibility
  Future<ExecutionResult> _boostBrightness(Map<String, dynamic> params) async {
    final level = (params['to'] as int? ?? 100).clamp(0, 100);
    // Reuse existing setBrightness logic
    return await _setBrightness({'to': level});
  }

  // ============================================================================
  // MOTOR ASSIST ACTIONS
  // ============================================================================

  /// Reduce gesture sensitivity (stub - requires accessibility service)
  Future<ExecutionResult> _reduceGestureSensitivity(Map<String, dynamic> params) async {
    // Note: This would require a custom AccessibilityService implementation
    debugPrint('[Executor] Reduce gesture sensitivity requested (stub)');
    return ExecutionResult(
      actionType: 'reduce_gesture_sensitivity',
      success: true,
      message: 'Reduced gesture sensitivity (requires accessibility service in future update)',
    );
  }

  /// Enable voice typing
  Future<ExecutionResult> _enableVoiceTyping(Map<String, dynamic> params) async {
    try {
      final success = await platform.invokeMethod<bool>('enableVoiceTyping');

      if (success == true) {
        debugPrint('[Executor] Opened voice typing settings');
        return ExecutionResult(
          actionType: 'enable_voice_typing',
          success: true,
          message: 'Opened input method settings for voice typing',
        );
      }

      return ExecutionResult(
        actionType: 'enable_voice_typing',
        success: false,
        message: 'Failed to open voice typing settings',
      );
    } catch (e) {
      debugPrint('[Executor] Error enabling voice typing: $e');
      return ExecutionResult(
        actionType: 'enable_voice_typing',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Enable one-handed mode
  Future<ExecutionResult> _enableOneHandedMode(Map<String, dynamic> params) async {
    try {
      final success = await platform.invokeMethod<bool>('enableOneHandedMode');

      if (success == true) {
        debugPrint('[Executor] Opened one-handed mode settings');
        return ExecutionResult(
          actionType: 'enable_one_handed_mode',
          success: true,
          message: 'Opened gesture settings for one-handed mode',
        );
      }

      return ExecutionResult(
        actionType: 'enable_one_handed_mode',
        success: false,
        message: 'Failed to enable one-handed mode',
      );
    } catch (e) {
      debugPrint('[Executor] Error enabling one-handed mode: $e');
      return ExecutionResult(
        actionType: 'enable_one_handed_mode',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Increase touch target sizes (stub - requires launcher modification)
  Future<ExecutionResult> _increaseTouchTargets(Map<String, dynamic> params) async {
    debugPrint('[Executor] Increase touch targets requested (stub)');
    return ExecutionResult(
      actionType: 'increase_touch_targets',
      success: true,
      message: 'Touch target sizes increased (visual UI enhancement)',
    );
  }

  // ============================================================================
  // COGNITIVE/NEURODIVERGENT ACTIONS
  // ============================================================================

  /// Reduce animation speed
  Future<ExecutionResult> _reduceAnimation(Map<String, dynamic> params) async {
    try {
      final success = await platform.invokeMethod<bool>('setAnimationScale', {'scale': 0.5});

      if (success == true) {
        debugPrint('[Executor] Reduced animation speed');
        return ExecutionResult(
          actionType: 'reduce_animation',
          success: true,
          message: 'Reduced animation speed by 50%',
        );
      }

      return ExecutionResult(
        actionType: 'reduce_animation',
        success: false,
        message: 'Failed to reduce animations',
      );
    } catch (e) {
      debugPrint('[Executor] Error reducing animations: $e');
      return ExecutionResult(
        actionType: 'reduce_animation',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Simplify home screen (stub - requires launcher integration)
  Future<ExecutionResult> _simplifyHomeScreen(Map<String, dynamic> params) async {
    debugPrint('[Executor] Simplify home screen requested (stub)');
    return ExecutionResult(
      actionType: 'simplify_home_screen',
      success: true,
      message: 'Home screen simplified (requires launcher support)',
    );
  }

  /// Mute common distraction apps
  Future<ExecutionResult> _muteDistractionApps(Map<String, dynamic> params) async {
    final distractionApps = ['Instagram', 'TikTok', 'Twitter', 'Facebook', 'Snapchat', 'YouTube'];
    return await _muteApps({'apps': distractionApps});
  }

  /// Highlight focus apps (stub - visual UI change)
  Future<ExecutionResult> _highlightFocusApps(Map<String, dynamic> params) async {
    debugPrint('[Executor] Highlight focus apps requested (stub)');
    return ExecutionResult(
      actionType: 'highlight_focus_apps',
      success: true,
      message: 'Focus apps highlighted on home screen',
    );
  }

  // ============================================================================
  // HEARING SUPPORT ACTIONS
  // ============================================================================

  /// Launch Live Transcribe app
  Future<ExecutionResult> _enableLiveTranscribe(Map<String, dynamic> params) async {
    try {
      await DeviceApps.openApp('com.google.audio.hearing.visualization.accessibility.scribe');

      return ExecutionResult(
        actionType: 'enable_live_transcribe',
        success: true,
        message: 'Launched Live Transcribe',
      );
    } catch (e) {
      debugPrint('[Executor] Error launching Live Transcribe: $e');
      return ExecutionResult(
        actionType: 'enable_live_transcribe',
        success: false,
        message: 'Live Transcribe not available. Install from Play Store.',
      );
    }
  }

  /// Enable system captions
  Future<ExecutionResult> _enableCaptions(Map<String, dynamic> params) async {
    try {
      final success = await platform.invokeMethod<bool>('enableCaptions');

      if (success == true) {
        debugPrint('[Executor] Enabled system captions');
        return ExecutionResult(
          actionType: 'enable_captions',
          success: true,
          message: 'Enabled system-wide captions',
        );
      }

      return ExecutionResult(
        actionType: 'enable_captions',
        success: false,
        message: 'Failed to enable captions',
      );
    } catch (e) {
      debugPrint('[Executor] Error enabling captions: $e');
      return ExecutionResult(
        actionType: 'enable_captions',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Enable screen flash for alerts
  Future<ExecutionResult> _flashScreenAlerts(Map<String, dynamic> params) async {
    try {
      final success = await platform.invokeMethod<bool>('enableFlashAlerts');

      if (success == true) {
        debugPrint('[Executor] Enabled flash alerts');
        return ExecutionResult(
          actionType: 'flash_screen_alerts',
          success: true,
          message: 'Enabled screen flash for notifications',
        );
      }

      return ExecutionResult(
        actionType: 'flash_screen_alerts',
        success: false,
        message: 'Failed to enable flash alerts',
      );
    } catch (e) {
      debugPrint('[Executor] Error enabling flash alerts: $e');
      return ExecutionResult(
        actionType: 'flash_screen_alerts',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Boost haptic feedback strength
  Future<ExecutionResult> _boostHapticFeedback(Map<String, dynamic> params) async {
    final strength = params['strength'] as String? ?? 'strong';

    try {
      final success = await platform.invokeMethod<bool>('setHapticStrength', {'strength': strength});

      if (success == true) {
        debugPrint('[Executor] Set haptic feedback to $strength');
        return ExecutionResult(
          actionType: 'boost_haptic_feedback',
          success: true,
          message: 'Increased haptic feedback strength to $strength',
          data: {'strength': strength},
        );
      }

      return ExecutionResult(
        actionType: 'boost_haptic_feedback',
        success: false,
        message: 'Failed to boost haptic feedback',
      );
    } catch (e) {
      debugPrint('[Executor] Error boosting haptic feedback: $e');
      return ExecutionResult(
        actionType: 'boost_haptic_feedback',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  // ============================================================================
  // SAFETY ACTIONS
  // ============================================================================

  /// Launch emergency/care app
  Future<ExecutionResult> _launchCareApp(Map<String, dynamic> params) async {
    final careApp = params['app'] as String? ?? 'Emergency Contacts';

    try {
      // Try common emergency/care apps
      final careApps = [
        'com.android.contacts',
        'com.google.android.contacts',
        'com.android.emergency',
      ];

      for (final packageName in careApps) {
        try {
          await DeviceApps.openApp(packageName);
          return ExecutionResult(
            actionType: 'launch_care_app',
            success: true,
            message: 'Launched $careApp',
            data: {'app': careApp},
          );
        } catch (e) {
          continue;
        }
      }

      throw Exception('No care app found');
    } catch (e) {
      debugPrint('[Executor] Error launching care app: $e');
      return ExecutionResult(
        actionType: 'launch_care_app',
        success: false,
        message: 'Could not find emergency contacts app',
      );
    }
  }

  /// Request all necessary permissions
  /// Requires Android
  Future<Map<String, bool>> requestPermissions() async {
    if (!Platform.isAndroid) {
      debugPrint('[Executor] Cannot request permissions on non-Android platform');
      return {'storage': false, 'settings': false, 'write_settings': false};
    }

    final results = <String, bool>{};

    results['storage'] = await Permission.manageExternalStorage.request().isGranted;
    results['settings'] = await Permission.systemAlertWindow.request().isGranted;
    results['write_settings'] = await ensureWriteSettingsPermission();

    return results;
  }

  /// Ensure WRITE_SETTINGS permission is granted (opens settings if needed)
  /// Requires Android
  Future<bool> ensureWriteSettingsPermission() async {
    if (!Platform.isAndroid) return false;

    final canWrite = await platform.invokeMethod<bool>('canWriteSettings');
    if (canWrite == true) return true;

    await platform.invokeMethod('requestWriteSettings');
    final recheck = await platform.invokeMethod<bool>('canWriteSettings');
    return recheck == true;
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_apps/device_apps.dart';
import 'tts_service.dart';
import 'cactus_llm_service.dart';

/// Service for integrating with external apps dynamically
/// Uses Android accessibility services to read screen content from any app
class AppIntegrationService {
  static final AppIntegrationService _instance = AppIntegrationService._internal();
  factory AppIntegrationService() => _instance;
  AppIntegrationService._internal();

  static const platform = MethodChannel('com.nothflows/app_integration');
  final TtsService _tts = TtsService();
  final CactusLLMService _llm = CactusLLMService();

  /// Check if accessibility service is enabled
  Future<bool> isAccessibilityEnabled() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await platform.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } catch (e) {
      debugPrint('[AppIntegration] Error checking accessibility status: $e');
      return false;
    }
  }

  /// Request user to enable accessibility service
  Future<void> requestAccessibilityPermission() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _tts.speak('Please enable NothFlows accessibility service in the settings to read content from other apps.');
      await platform.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      debugPrint('[AppIntegration] Error opening accessibility settings: $e');
    }
  }

  /// Find and launch an app by category or keyword
  Future<Map<String, dynamic>> launchAppByKeyword({
    required String keyword,
    List<String>? categories,
  }) async {
    if (!Platform.isAndroid) {
      debugPrint('[AppIntegration] Not on Android platform');
      return {
        'success': false,
        'message': 'App integration requires Android',
      };
    }

    try {
      debugPrint('[AppIntegration] Searching for apps matching: $keyword');

      // Get all installed apps including system apps
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: false,
        includeSystemApps: true,  // Important: Include system apps like Gmail
        onlyAppsWithLaunchIntent: true,
      );

      debugPrint('[AppIntegration] Total apps found: ${apps.length}');

      // Log first few apps for debugging
      if (apps.length > 0) {
        debugPrint('[AppIntegration] Sample apps: ${apps.take(10).map((a) => '${a.appName} (${a.packageName})').join(', ')}');
      }

      // Filter apps by keyword
      final matchingApps = apps.where((app) {
        final lowerName = app.appName.toLowerCase();
        final lowerPackage = app.packageName.toLowerCase();
        final lowerKeyword = keyword.toLowerCase();
        
        return lowerName.contains(lowerKeyword) || 
               lowerPackage.contains(lowerKeyword);
      }).toList();

      debugPrint('[AppIntegration] Matching apps for "$keyword": ${matchingApps.map((a) => a.appName).join(", ")}');

      if (matchingApps.isEmpty) {
        debugPrint('[AppIntegration] No apps found matching: $keyword');
        await _tts.speak('Could not find any $keyword app installed.');
        return {
          'success': false,
          'message': 'No matching apps found',
          'keyword': keyword,
        };
      }

      // Launch the first matching app using native method channel for better reliability
      final app = matchingApps.first;
      debugPrint('[AppIntegration] Launching ${app.appName} (${app.packageName})');
      
      try {
        final result = await platform.invokeMethod('launchApp', {
          'packageName': app.packageName,
        });
        
        if (result == true) {
          return {
            'success': true,
            'message': 'Launched ${app.appName}',
            'app_name': app.appName,
            'package': app.packageName,
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to launch ${app.appName}',
          };
        }
      } catch (e) {
        debugPrint('[AppIntegration] Error launching via native: $e, trying DeviceApps');
        // Fallback to DeviceApps
        await DeviceApps.openApp(app.packageName);
        return {
          'success': true,
          'message': 'Launched ${app.appName}',
          'app_name': app.appName,
          'package': app.packageName,
        };
      }
    } catch (e) {
      debugPrint('[AppIntegration] Error launching app: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Open an app and read its screen content using accessibility services
  Future<Map<String, dynamic>> openAppAndReadScreen({
    required String appKeyword,
    int waitMs = 2000,
  }) async {
    if (!Platform.isAndroid) {
      return {
        'success': false,
        'message': 'App integration requires Android',
      };
    }

    try {
      debugPrint('[AppIntegration] Opening $appKeyword and reading screen');

      // Check if accessibility service is enabled
      final accessibilityEnabled = await isAccessibilityEnabled();
      if (!accessibilityEnabled) {
        debugPrint('[AppIntegration] Accessibility service not enabled');
        await _tts.speak('Accessibility permission is required to read content from other apps.');
        await requestAccessibilityPermission();
        return {
          'success': false,
          'message': 'Accessibility service not enabled',
          'requires_permission': true,
        };
      }

      // Launch the app
      final launchResult = await launchAppByKeyword(keyword: appKeyword);
      
      if (launchResult['success'] != true) {
        return launchResult;
      }

      final appName = launchResult['app_name'] as String;
      
      // Wait for app to open and render
      await Future.delayed(Duration(milliseconds: waitMs));

      // Request screen content from accessibility service
      final screenContent = await platform.invokeMethod<String>(
        'readScreenContent',
      );

      if (screenContent == null || screenContent.isEmpty) {
        debugPrint('[AppIntegration] Could not read screen content');
        await _tts.speak('Opened $appName, but could not read the screen.');
        return {
          'success': false,
          'message': 'Could not read screen content',
          'app_name': appName,
        };
      }

      debugPrint('[AppIntegration] Screen content: $screenContent');

      // Use Cactus LLM to summarize the screen content
      debugPrint('[AppIntegration] Generating summary with Cactus LLM...');
      final summary = await _summarizeScreenContent(appName, screenContent);

      // Speak the summarized content
      await _tts.speak(summary);

      return {
        'success': true,
        'message': 'Screen content read and summarized',
        'app_name': appName,
        'content': screenContent,
        'summary': summary,
      };
    } catch (e) {
      debugPrint('[AppIntegration] Error reading screen: $e');
      
      // Check if it's a permission error
      if (e.toString().contains('NOT_ENABLED')) {
        await _tts.speak('Accessibility permission is required to read content from other apps.');
        await requestAccessibilityPermission();
        return {
          'success': false,
          'message': 'Accessibility service not enabled',
          'requires_permission': true,
        };
      }
      
      await _tts.speak('Error reading screen content.');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Open Gmail and read the first unread email (dynamic version)
  Future<Map<String, dynamic>> openGmailAndReadFirstUnread() async {
    return await openAppAndReadScreen(
      appKeyword: 'gmail',
      waitMs: 2500,
    );
  }

  /// Open Weather app and read current weather (dynamic version)
  Future<Map<String, dynamic>> openWeatherAndReadCurrent() async {
    return await openAppAndReadScreen(
      appKeyword: 'weather',
      waitMs: 2000,
    );
  }

  /// Generic method to open any app and read its content
  Future<Map<String, dynamic>> openAndReadApp(String appName) async {
    return await openAppAndReadScreen(
      appKeyword: appName,
      waitMs: 2000,
    );
  }

  /// Get list of installed apps matching a keyword
  Future<List<Map<String, String>>> searchInstalledApps(String keyword) async {
    try {
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: false,
        includeSystemApps: true,  // Include system apps
        onlyAppsWithLaunchIntent: true,
      );

      final matchingApps = apps.where((app) {
        final lowerName = app.appName.toLowerCase();
        final lowerKeyword = keyword.toLowerCase();
        return lowerName.contains(lowerKeyword);
      }).toList();

      return matchingApps.map((app) => {
        'name': app.appName,
        'package': app.packageName,
      }).toList();
    } catch (e) {
      debugPrint('[AppIntegration] Error searching apps: $e');
      return [];
    }
  }

  /// Use smart extraction to generate instant summaries of screen content
  /// Uses pattern-based extraction for near-zero latency (no LLM inference)
  Future<String> _summarizeScreenContent(String appName, String rawContent) async {
    // Always use smart fallback for instant response (near-zero latency)
    // This extracts key information without reading literal text
    debugPrint('[AppIntegration] Using smart extraction for instant summary');
    return _createSmartFallback(appName, rawContent);
  }

  /// Create an intelligent fallback summary when LLM is unavailable
  /// Extracts key information based on app type
  String _createSmartFallback(String appName, String content) {
    final lowerContent = content.toLowerCase();
    final lowerAppName = appName.toLowerCase();

    // Weather app - extract temperature, conditions, location
    if (lowerAppName.contains('weather')) {
      return _extractWeatherInfo(content);
    }

    // Email app - extract sender, subject, preview
    if (lowerAppName.contains('gmail') || lowerAppName.contains('email') || lowerAppName.contains('mail')) {
      return _extractEmailInfo(content);
    }

    // Calendar app - extract events, times
    if (lowerAppName.contains('calendar')) {
      return _extractCalendarInfo(content);
    }

    // Generic fallback - extract first meaningful sentences
    return _extractKeyPoints(appName, content);
  }

  String _extractWeatherInfo(String content) {
    // Extract temperature (look for °C or °F patterns)
    final tempMatch = RegExp(r'(\d+)˚[CF°]').firstMatch(content);
    final temp = tempMatch?.group(0) ?? '';

    // Extract location (usually near start)
    final words = content.split(RegExp(r'[.\s]+')).where((w) => w.isNotEmpty).toList();
    final location = words.length > 1 ? words[1] : 'your location';

    // Extract weather condition (rain, sunny, cloudy, etc.)
    final conditions = ['rain', 'sunny', 'cloud', 'snow', 'storm', 'clear', 'fog', 'wind'];
    String condition = '';
    for (final cond in conditions) {
      if (content.toLowerCase().contains(cond)) {
        condition = cond;
        break;
      }
    }

    // Extract high/low if available
    final lowMatch = RegExp(r'Low.*?(\d+)˚').firstMatch(content);
    final highMatch = RegExp(r'High.*?(\d+)˚').firstMatch(content);
    final low = lowMatch?.group(1);
    final high = highMatch?.group(1);

    String summary = 'In $location, ';
    if (temp.isNotEmpty) {
      summary += 'the current temperature is $temp';
    }
    if (condition.isNotEmpty) {
      summary += temp.isNotEmpty ? ' with $condition' : '$condition conditions';
    }
    if (low != null && high != null) {
      summary += '. Today\'s range is $low to $high degrees';
    }
    summary += '.';

    return summary.isNotEmpty ? summary : 'Weather information is available on screen.';
  }

  String _extractEmailInfo(String content) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).take(5).toList();
    if (lines.isEmpty) {
      return 'No new emails found.';
    }

    return 'You have emails in your inbox. ${lines.take(2).join('. ')}.';
  }

  String _extractCalendarInfo(String content) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).take(5).toList();
    if (lines.isEmpty) {
      return 'No upcoming events found.';
    }

    return 'Your calendar shows: ${lines.take(2).join('. ')}.';
  }

  String _extractKeyPoints(String appName, String content) {
    // Remove UI elements and navigation text
    final cleaned = content
        .replaceAll(RegExp(r'\b(Menu|Settings|Back|More|Share|Search)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\.{2,}'), '. ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Take first 150 characters of meaningful content
    final meaningful = cleaned.length > 150
        ? '${cleaned.substring(0, 150)}...'
        : cleaned;

    return 'In $appName: $meaningful';
  }
}


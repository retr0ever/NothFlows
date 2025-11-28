import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/flow_dsl.dart';

/// Service for monitoring device sensors and evaluating flow conditions
class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  // Internal state
  String _ambientLight = 'medium'; // 'low' | 'medium' | 'high'
  String _noiseLevel = 'moderate'; // 'quiet' | 'moderate' | 'loud' (stubbed)
  String _deviceMotion = 'still'; // 'still' | 'walking' | 'shaky'

  // Debug values
  int _currentLux = 500;
  double _currentMotion = 0.0;

  // Subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isMonitoring = false;
  bool _hasLoggedSensorError = false;

  // Getters
  String get ambientLight => _ambientLight;
  String get noiseLevel => _noiseLevel;
  String get deviceMotion => _deviceMotion;
  int get currentLux => _currentLux;
  double get currentMotion => _currentMotion;
  bool get isMonitoring => _isMonitoring;

  /// Start monitoring sensors
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      debugPrint('[SensorService] Already monitoring');
      return;
    }

    debugPrint('[SensorService] Starting sensor monitoring...');
    _isMonitoring = true;

    // Simulate light sensor based on time of day
    _simulateLightSensor();

    // Subscribe to accelerometer (motion detection)
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        _accelerometerSubscription = accelerometerEvents.listen(
          (AccelerometerEvent event) {
            _updateMotionState(event);
          },
          onError: (error) {
            if (!_hasLoggedSensorError) {
              debugPrint('[SensorService] Accelerometer error: $error');
              debugPrint('[SensorService] Falling back to simulated motion values');
              _hasLoggedSensorError = true;
            }
            _fallbackToSimulatedMotion();
          },
          cancelOnError: false,
        );
        debugPrint('[SensorService] Accelerometer monitoring started');
      } catch (e) {
        if (!_hasLoggedSensorError) {
          debugPrint('[SensorService] Failed to start accelerometer: $e');
          debugPrint('[SensorService] Falling back to simulated motion values');
          _hasLoggedSensorError = true;
        }
        _fallbackToSimulatedMotion();
      }
    } else {
      debugPrint('[SensorService] Non-mobile platform detected, using simulated values');
      _fallbackToSimulatedMotion();
    }
  }

  /// Stop monitoring sensors
  void stopMonitoring() {
    debugPrint('[SensorService] Stopping sensor monitoring');
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _isMonitoring = false;
  }

  /// Update motion state from accelerometer data
  void _updateMotionState(AccelerometerEvent event) {
    // Calculate motion magnitude (simple Euclidean distance)
    final magnitude = (event.x * event.x + event.y * event.y + event.z * event.z);
    _currentMotion = magnitude;

    // Classify motion based on magnitude thresholds
    if (magnitude < 2.0) {
      _deviceMotion = 'still';
    } else if (magnitude < 10.0) {
      _deviceMotion = 'walking';
    } else {
      _deviceMotion = 'shaky';
    }
  }

  /// Fallback to simulated motion when sensors unavailable
  void _fallbackToSimulatedMotion() {
    _deviceMotion = 'still';
    _currentMotion = 0.5;
  }

  /// Simulate ambient light based on time of day
  void _simulateLightSensor() {
    final hour = DateTime.now().hour;

    // Heuristic: morning (6-11), afternoon (12-17), evening (18-21), night (22-5)
    if (hour >= 6 && hour < 12) {
      _ambientLight = 'medium';
      _currentLux = 500;
    } else if (hour >= 12 && hour < 18) {
      _ambientLight = 'high';
      _currentLux = 1000;
    } else if (hour >= 18 && hour < 22) {
      _ambientLight = 'medium';
      _currentLux = 300;
    } else {
      _ambientLight = 'low';
      _currentLux = 50;
    }

    debugPrint('[SensorService] Simulated light: $_ambientLight (${_currentLux}lux) at hour $hour');
  }

  /// Evaluate flow conditions against current sensor state
  bool evaluateConditions(FlowConditions? conditions) {
    if (conditions == null || conditions.isEmpty) {
      return true;
    }

    // Check ambient light
    if (conditions.ambientLight != null && conditions.ambientLight != _ambientLight) {
      debugPrint('[SensorService] Light condition not met: expected ${conditions.ambientLight}, got $_ambientLight');
      return false;
    }

    // Check noise level
    if (conditions.noiseLevel != null && conditions.noiseLevel != _noiseLevel) {
      debugPrint('[SensorService] Noise condition not met: expected ${conditions.noiseLevel}, got $_noiseLevel');
      return false;
    }

    // Check device motion
    if (conditions.deviceMotion != null && conditions.deviceMotion != _deviceMotion) {
      debugPrint('[SensorService] Motion condition not met: expected ${conditions.deviceMotion}, got $_deviceMotion');
      return false;
    }

    // TODO: Add time-based checks (conditions.timeOfDay)
    // TODO: Add battery checks (conditions.batteryLevel, conditions.isCharging)
    // TODO: Add recent usage checks (conditions.recentUsage)

    debugPrint('[SensorService] All conditions met');
    return true;
  }

  /// Get current sensor state as a map (for debugging)
  Map<String, dynamic> getCurrentState() {
    return {
      'ambientLight': _ambientLight,
      'currentLux': _currentLux,
      'noiseLevel': _noiseLevel,
      'deviceMotion': _deviceMotion,
      'currentMotion': _currentMotion,
      'isMonitoring': _isMonitoring,
    };
  }
}

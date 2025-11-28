import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/mode_model.dart';
import '../models/flow_dsl.dart';

/// Service for local storage of modes and flows
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;
  bool _isInitialised = false;

  // Storage keys
  static const String _keyModes = 'nothflows_modes';
  static const String _keyActiveMode = 'nothflows_active_mode';
  static const String _keyFlowCounter = 'nothflows_flow_counter';

  /// Initialise storage
  Future<void> initialise() async {
    if (_isInitialised) return;

    _prefs = await SharedPreferences.getInstance();
    _isInitialised = true;

    // Initialise default modes if first run
    final modes = await getModes();
    if (modes.isEmpty) {
      await _initialiseDefaultModes();
    }

    debugPrint('[Storage] Initialised successfully');
  }

  /// Ensure storage is ready
  Future<void> _ensureInitialised() async {
    if (!_isInitialised) {
      await initialise();
    }
  }

  /// Initialise default modes
  Future<void> _initialiseDefaultModes() async {
    final defaults = ModeModel.defaults;
    await saveModes(defaults);
    debugPrint('[Storage] Initialised default modes: ${defaults.map((m) => m.name).join(", ")}');
  }

  /// Save all modes
  Future<void> saveModes(List<ModeModel> modes) async {
    await _ensureInitialised();

    final json = modes.map((m) => m.toJson()).toList();
    final jsonString = jsonEncode(json);

    await _prefs!.setString(_keyModes, jsonString);
    debugPrint('[Storage] Saved ${modes.length} modes');
  }

  /// Get all modes
  Future<List<ModeModel>> getModes() async {
    await _ensureInitialised();

    final jsonString = _prefs!.getString(_keyModes);
    if (jsonString == null) {
      return [];
    }

    try {
      final json = jsonDecode(jsonString) as List<dynamic>;
      return json
          .map((m) => ModeModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Storage] Error loading modes: $e');
      return [];
    }
  }

  /// Get a specific mode by ID
  Future<ModeModel?> getMode(String modeId) async {
    final modes = await getModes();
    try {
      return modes.firstWhere((m) => m.id == modeId);
    } catch (e) {
      return null;
    }
  }

  /// Update a specific mode
  Future<void> updateMode(ModeModel mode) async {
    final modes = await getModes();
    final index = modes.indexWhere((m) => m.id == mode.id);

    if (index != -1) {
      modes[index] = mode;
      await saveModes(modes);
      debugPrint('[Storage] Updated mode: ${mode.id}');
    }
  }

  /// Add a flow to a mode
  Future<void> addFlowToMode(String modeId, FlowDSL flow) async {
    final mode = await getMode(modeId);
    if (mode == null) return;

    // Generate unique ID for flow if not set
    final flowWithId = flow.id == null
        ? flow.copyWith(id: await _generateFlowId())
        : flow;

    final updatedMode = mode.addFlow(flowWithId);
    await updateMode(updatedMode);

    debugPrint('[Storage] Added flow to mode $modeId');
  }

  /// Remove a flow from a mode
  Future<void> removeFlowFromMode(String modeId, String flowId) async {
    final mode = await getMode(modeId);
    if (mode == null) return;

    final updatedMode = mode.removeFlow(flowId);
    await updateMode(updatedMode);

    debugPrint('[Storage] Removed flow $flowId from mode $modeId');
  }

  /// Get flows for a specific mode
  Future<List<FlowDSL>> getFlowsForMode(String modeId) async {
    final mode = await getMode(modeId);
    return mode?.flows ?? [];
  }

  /// Set active mode (deactivate all others)
  Future<void> setActiveMode(String modeId) async {
    final modes = await getModes();

    for (var i = 0; i < modes.length; i++) {
      if (modes[i].id == modeId) {
        modes[i] = modes[i].copyWith(
          isActive: true,
          lastActivated: DateTime.now(),
        );
      } else {
        modes[i] = modes[i].copyWith(isActive: false);
      }
    }

    await saveModes(modes);
    await _prefs!.setString(_keyActiveMode, modeId);

    debugPrint('[Storage] Set active mode: $modeId');
  }

  /// Deactivate all modes
  Future<void> deactivateAllModes() async {
    final modes = await getModes();

    for (var i = 0; i < modes.length; i++) {
      modes[i] = modes[i].copyWith(isActive: false);
    }

    await saveModes(modes);
    await _prefs!.remove(_keyActiveMode);

    debugPrint('[Storage] Deactivated all modes');
  }

  /// Get currently active mode
  Future<ModeModel?> getActiveMode() async {
    final activeModeId = _prefs!.getString(_keyActiveMode);
    if (activeModeId == null) return null;

    return await getMode(activeModeId);
  }

  /// Toggle mode activation
  Future<void> toggleMode(String modeId) async {
    final mode = await getMode(modeId);
    if (mode == null) return;

    if (mode.isActive) {
      await deactivateAllModes();
    } else {
      await setActiveMode(modeId);
    }
  }

  /// Generate unique flow ID
  Future<String> _generateFlowId() async {
    await _ensureInitialised();

    final counter = _prefs!.getInt(_keyFlowCounter) ?? 0;
    final newCounter = counter + 1;
    await _prefs!.setInt(_keyFlowCounter, newCounter);

    return 'flow_$newCounter';
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAll() async {
    await _ensureInitialised();
    await _prefs!.clear();
    _isInitialised = false;
    await initialise();
    debugPrint('[Storage] Cleared all data');
  }
}

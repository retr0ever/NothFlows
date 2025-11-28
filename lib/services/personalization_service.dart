import 'dart:convert';
import 'dart:io';
import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flow_dsl.dart';

/// Document stored in RAG for retrieval
class RagDocument {
  final String id;
  final String content;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  RagDocument({
    required this.id,
    required this.content,
    required this.metadata,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RagDocument.fromJson(Map<String, dynamic> json) => RagDocument(
        id: json['id'] as String,
        content: json['content'] as String,
        metadata: Map<String, dynamic>.from(json['metadata'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Service for local personalization using embeddings and RAG
/// Stores user flows and check-ins for personalized suggestions
class PersonalizationService {
  static final PersonalizationService _instance = PersonalizationService._internal();
  factory PersonalizationService() => _instance;
  PersonalizationService._internal();

  CactusLM? _llm;
  bool _isInitialised = false;
  bool _isLoading = false;

  // Local storage for documents (fallback when embeddings aren't available)
  final List<RagDocument> _documents = [];
  static const String _storageKey = 'nothflows_personalization_docs';

  /// Initialize the embedding model for RAG
  Future<void> initialise() async {
    if (_isInitialised || _isLoading) return;

    _isLoading = true;
    debugPrint('[Personalization] Initializing...');

    try {
      // Load cached documents from SharedPreferences
      await _loadDocuments();

      // On Android, try to initialize the embedding model
      if (Platform.isAndroid) {
        try {
          _llm = CactusLM();
          await _llm!.downloadModel(model: 'qwen3-0.6');
          await _llm!.initializeModel();
          debugPrint('[Personalization] Embedding model loaded');
        } catch (e) {
          debugPrint('[Personalization] Embedding model failed, using keyword search: $e');
          _llm = null;
        }
      }

      _isInitialised = true;
      debugPrint('[Personalization] Initialized with ${_documents.length} cached documents');
    } catch (e) {
      debugPrint('[Personalization] Failed to initialize: $e');
      // Still mark as initialized - we can work without embeddings
      _isInitialised = true;
    } finally {
      _isLoading = false;
    }
  }

  bool get isReady => _isInitialised;

  /// Store user flow for future personalization
  Future<void> storeFlow(FlowDSL flow) async {
    if (!_isInitialised) await initialise();

    try {
      final doc = RagDocument(
        id: flow.id ?? 'flow_${DateTime.now().millisecondsSinceEpoch}',
        content: flow.getDescription(),
        metadata: {
          'type': 'flow',
          'trigger': flow.trigger,
          'mode': flow.trigger.split(':').last,
          'actions': flow.actions.map((a) => a.type).toList(),
          'action_count': flow.actions.length,
          'has_conditions': flow.conditions != null && !flow.conditions!.isEmpty,
        },
      );

      _documents.add(doc);
      await _saveDocuments();

      debugPrint('[Personalization] Stored flow: ${doc.id}');
    } catch (e) {
      debugPrint('[Personalization] Error storing flow: $e');
    }
  }

  /// Store daily check-in response
  Future<void> storeCheckIn(String response, String sentiment) async {
    if (!_isInitialised) await initialise();

    try {
      final doc = RagDocument(
        id: 'checkin_${DateTime.now().millisecondsSinceEpoch}',
        content: response,
        metadata: {
          'type': 'daily_checkin',
          'sentiment': sentiment, // 'positive', 'neutral', 'struggling'
          'date': DateTime.now().toIso8601String(),
        },
      );

      _documents.add(doc);
      await _saveDocuments();

      debugPrint('[Personalization] Stored check-in with sentiment: $sentiment');
    } catch (e) {
      debugPrint('[Personalization] Error storing check-in: $e');
    }
  }

  /// Query user context for personalized suggestions
  /// Uses embeddings if available, otherwise keyword matching
  Future<List<RagDocument>> queryUserContext(String query, {int limit = 5}) async {
    if (!_isInitialised) await initialise();

    if (_documents.isEmpty) {
      debugPrint('[Personalization] No documents stored');
      return [];
    }

    try {
      // If we have embeddings, use semantic search
      if (_llm != null) {
        return await _semanticSearch(query, limit);
      }

      // Fallback to keyword search
      return _keywordSearch(query, limit);
    } catch (e) {
      debugPrint('[Personalization] Error querying context: $e');
      return [];
    }
  }

  /// Semantic search using embeddings
  Future<List<RagDocument>> _semanticSearch(String query, int limit) async {
    // Generate embedding for query
    final queryEmbedding = await _llm!.generateEmbedding(text: query);

    if (!queryEmbedding.success) {
      debugPrint('[Personalization] Embedding generation failed, falling back to keyword search');
      return _keywordSearch(query, limit);
    }

    // For now, fall back to keyword search since we'd need to store embeddings
    // Full implementation would store embeddings with documents and compute similarity
    return _keywordSearch(query, limit);
  }

  /// Keyword-based search fallback
  List<RagDocument> _keywordSearch(String query, int limit) {
    final queryWords = query.toLowerCase().split(' ').toSet();

    final scored = _documents.map((doc) {
      final contentWords = doc.content.toLowerCase().split(' ').toSet();
      final metadataStr = jsonEncode(doc.metadata).toLowerCase();

      int score = 0;
      for (final word in queryWords) {
        if (contentWords.contains(word)) score += 2;
        if (metadataStr.contains(word)) score += 1;
      }

      return MapEntry(doc, score);
    }).where((e) => e.value > 0).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.take(limit).map((e) => e.key).toList();
  }

  /// Get personalized suggestions for a specific assistive mode
  Future<List<String>> getSuggestionsForMode(String mode) async {
    final suggestions = <String>[];

    try {
      final results = await queryUserContext(
        '$mode mode flows actions prefer',
        limit: 3,
      );

      if (results.isNotEmpty) {
        suggestions.add('Based on your history with $mode mode:');
        for (final doc in results) {
          if (doc.metadata['type'] == 'flow') {
            suggestions.add(doc.content);
          }
        }
      }

      // Add defaults if we don't have enough
      if (suggestions.length < 3) {
        suggestions.addAll(_getDefaultSuggestionsForMode(mode));
      }
    } catch (e) {
      debugPrint('[Personalization] Error getting suggestions: $e');
      suggestions.addAll(_getDefaultSuggestionsForMode(mode));
    }

    return suggestions.take(4).toList();
  }

  /// Get recent sentiment from check-ins
  Future<String> getRecentSentiment() async {
    try {
      // Find most recent check-in
      final checkIns = _documents
          .where((d) => d.metadata['type'] == 'daily_checkin')
          .toList();

      if (checkIns.isEmpty) return 'neutral';

      checkIns.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final recentCheckIn = checkIns.first;
      return recentCheckIn.metadata['sentiment'] as String? ?? 'neutral';
    } catch (e) {
      debugPrint('[Personalization] Error getting sentiment: $e');
      return 'neutral';
    }
  }

  /// Get usage statistics
  Future<Map<String, dynamic>> getUsageStats() async {
    if (!_isInitialised) await initialise();

    final flows = _documents.where((d) => d.metadata['type'] == 'flow').toList();
    final checkIns = _documents.where((d) => d.metadata['type'] == 'daily_checkin').toList();

    // Count flows by mode
    final modeCount = <String, int>{};
    for (final flow in flows) {
      final mode = flow.metadata['mode'] as String? ?? 'custom';
      modeCount[mode] = (modeCount[mode] ?? 0) + 1;
    }

    // Count check-in sentiments
    final sentimentCount = <String, int>{};
    for (final checkIn in checkIns) {
      final sentiment = checkIn.metadata['sentiment'] as String? ?? 'neutral';
      sentimentCount[sentiment] = (sentimentCount[sentiment] ?? 0) + 1;
    }

    return {
      'total_flows': flows.length,
      'total_checkins': checkIns.length,
      'flows_by_mode': modeCount,
      'checkins_by_sentiment': sentimentCount,
      'most_used_mode': modeCount.isNotEmpty
          ? modeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  /// Clear all stored personalization data
  Future<void> clearAllData() async {
    _documents.clear();
    await _saveDocuments();
    debugPrint('[Personalization] Cleared all user data');
  }

  /// Load documents from SharedPreferences
  Future<void> _loadDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List;
        _documents.clear();
        _documents.addAll(
          jsonList.map((j) => RagDocument.fromJson(j as Map<String, dynamic>)),
        );
      }
    } catch (e) {
      debugPrint('[Personalization] Error loading documents: $e');
    }
  }

  /// Save documents to SharedPreferences
  Future<void> _saveDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_documents.map((d) => d.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('[Personalization] Error saving documents: $e');
    }
  }

  List<String> _getDefaultSuggestionsForMode(String mode) {
    switch (mode) {
      case 'vision':
        return [
          'Increase text size to maximum',
          'Enable high contrast mode',
          'Boost brightness to 90%',
        ];
      case 'motor':
        return [
          'Reduce gesture sensitivity',
          'Enable voice typing',
          'Enable one-handed mode',
        ];
      case 'neurodivergent':
        return [
          'Mute distraction apps',
          'Enable Do Not Disturb',
          'Reduce animations',
        ];
      case 'calm':
        return [
          'Enable Do Not Disturb',
          'Lower brightness to 30%',
          'Reduce all notifications',
        ];
      case 'hearing':
        return [
          'Enable live transcribe',
          'Flash screen for alerts',
          'Boost haptic feedback',
        ];
      case 'sleep':
        return [
          'Lower brightness to 10%',
          'Enable Do Not Disturb',
          'Reduce blue light',
        ];
      case 'focus':
        return [
          'Mute social media apps',
          'Enable Do Not Disturb',
          'Launch productivity app',
        ];
      default:
        return ['Create your own custom routine'];
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_llm != null) {
      _llm!.unload();
      _llm = null;
    }
    _isInitialised = false;
    debugPrint('[Personalization] Resources disposed');
  }
}

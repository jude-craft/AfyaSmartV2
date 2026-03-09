import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_constants.dart';
import '../models/chat_session.dart';
import '../models/message_model.dart';

class HistoryProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<ChatSessionModel> _sessions = [];
  bool _isLoading = false;

  // ── Getters ──────────────────────────────────────────
  List<ChatSessionModel> get sessions  => List.unmodifiable(_sessions);
  bool                   get isLoading => _isLoading;
  bool                   get isEmpty   => _sessions.isEmpty;

  HistoryProvider() {
    _loadHistory();
  }

  // ── Load from local storage ───────────────────────────
  Future<void> _loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(AppConstants.keyChatHistory);

      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _sessions = decoded
            .map((e) => ChatSessionModel.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      } else {
        _sessions = _buildMockSessions();
      }
    } catch (_) {
      _sessions = _buildMockSessions();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Save session ─────────────────────────────────────
  Future<void> saveSession(ChatSessionModel session) async {
    final idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx != -1) {
      _sessions[idx] = session;
    } else {
      _sessions.insert(0, session);
    }
    notifyListeners();
    await _persist();
  }

  // ── Delete session ────────────────────────────────────
  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    notifyListeners();
    await _persist();
  }

  // ── Clear all ─────────────────────────────────────────
  Future<void> clearAll() async {
    _sessions = [];
    notifyListeners();
    await _persist();
  }

  // ── Persist to SharedPreferences ──────────────────────
  Future<void> _persist() async {
    final prefs   = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await prefs.setString(AppConstants.keyChatHistory, encoded);
  }

  // ── Mock seed data ────────────────────────────────────
  List<ChatSessionModel> _buildMockSessions() {
    final now = DateTime.now();
    return List.generate(AppConstants.sampleChatTitles.length, (i) {
      final date = now.subtract(Duration(days: i, hours: i * 2));
      return ChatSessionModel(
        id:        _uuid.v4(),
        title:     AppConstants.sampleChatTitles[i],
        messages:  [
          MessageModel.assistant(
            id:      _uuid.v4(),
            content: AppConstants.aiWelcomeMessage,
          ),
        ],
        createdAt: date,
        updatedAt: date,
      );
    });
  }
}
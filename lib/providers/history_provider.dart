import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_session.dart';
import '../models/message_model.dart';
import '../core/services/api_service.dart';

class HistoryProvider extends ChangeNotifier {
  List<ChatSessionModel> _sessions      = [];
  bool                   _isLoading     = false;
  bool                   _isLoadingMsgs = false;
  String?                _errorMessage;

  // ── Getters ───────────────────────────────────────────
  List<ChatSessionModel> get sessions       => List.unmodifiable(_sessions);
  bool                   get isLoading      => _isLoading;
  bool                   get isLoadingMsgs  => _isLoadingMsgs;
  bool                   get isEmpty        => _sessions.isEmpty;
  String?                get errorMessage   => _errorMessage;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  HistoryProvider() {
    // Auto-fetch when Firebase auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        fetchHistory();
      } else {
        _sessions = [];
        notifyListeners();
      }
    });
  }

  // ─────────────────────────────────────────────────────
  //  Fetch all sessions for the current user
  // ─────────────────────────────────────────────────────
  Future<void> fetchHistory() async {
    if (_uid == null) return;

    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final raw = await ApiService.fetchSessions(_uid!);
      _sessions = raw.map(_mapSession).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load history. Pull to refresh.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────
  //  Fetch messages for a specific session (lazy load)
  //  Returns the fully hydrated ChatSessionModel
  // ─────────────────────────────────────────────────────
  Future<ChatSessionModel?> fetchSessionMessages(
    String sessionId,
  ) async {
    _isLoadingMsgs = true;
    notifyListeners();

    try {
      final rawMessages = await ApiService.fetchMessages(sessionId);
      final messages    = rawMessages.map(_mapMessage).toList();

      // Update the session in our local list with real messages
      final idx = _sessions.indexWhere((s) => s.id == sessionId);
      if (idx != -1) {
        final updated = _sessions[idx].copyWith(messages: messages);
        _sessions[idx] = updated;
        notifyListeners();
        return updated;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load messages.';
      notifyListeners();
    } finally {
      _isLoadingMsgs = false;
      notifyListeners();
    }
    return null;
  }

  // ─────────────────────────────────────────────────────
  //  Delete a single session — optimistic UI
  // ─────────────────────────────────────────────────────
  Future<void> deleteSession(String sessionId) async {
    final backup = List<ChatSessionModel>.from(_sessions);
    _sessions.removeWhere((s) => s.id == sessionId);
    notifyListeners();

    try {
      final success = await ApiService.deleteSession(sessionId);
      if (!success) {
        _sessions = backup;
        _errorMessage = 'Failed to delete session.';
        notifyListeners();
      }
    } catch (_) {
      _sessions     = backup;
      _errorMessage = 'Failed to delete session. Check your connection.';
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────
  //  Clear all — deletes every session
  // ─────────────────────────────────────────────────────
  Future<void> clearAll() async {
    final ids    = _sessions.map((s) => s.id).toList();
    final backup = List<ChatSessionModel>.from(_sessions);

    _sessions = [];
    notifyListeners();

    try {
      await Future.wait(ids.map(ApiService.deleteSession));
    } catch (_) {
      _sessions     = backup;
      _errorMessage = 'Failed to clear history.';
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────
  //  Upsert a session locally after a new chat
  // ─────────────────────────────────────────────────────
  void upsertSession(ChatSessionModel session) {
    final idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx != -1) {
      _sessions[idx] = session;
    } else {
      _sessions.insert(0, session);
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────
  //  Mappers
  // ─────────────────────────────────────────────────────

  /// Maps a raw session row from Supabase → ChatSessionModel
  /// Note: messages are NOT included here — they are lazy loaded
  /// via fetchSessionMessages() when the user opens a chat
  ChatSessionModel _mapSession(Map<String, dynamic> raw) {
    return ChatSessionModel(
      id:        raw['session_id'] as String?  ?? '',
      title:     raw['title']      as String?  ?? 'Untitled Chat',
      messages:  const [],                  // lazy loaded on open
      createdAt: _parseDate(raw['created_at']),
      updatedAt: _parseDate(raw['updated_at'] ?? raw['created_at']),
    );
  }

  /// Maps a raw message row from Supabase → MessageModel
  MessageModel _mapMessage(Map<String, dynamic> raw) {
    final role = (raw['role'] as String?) == 'user'
        ? MessageRole.user
        : MessageRole.assistant;

    return MessageModel(
      id:        raw['id']?.toString()    ?? '',
      content:   raw['content'] as String? ?? '',
      role:      role,
      status:    MessageStatus.sent,
      timestamp: _parseDate(raw['created_at']),
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
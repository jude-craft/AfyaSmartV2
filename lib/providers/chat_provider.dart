import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/api_service.dart';
import '../core/services/web_socket_service.dart';
import '../models/chat_session.dart';
import '../models/message_model.dart';

import 'history_provider.dart';

// ── Chat modes ────────────────────────────────────────────
enum ChatMode { freeChat, symptomChecker }

// ── Symptom session stages (mirrors backend) ──────────────
enum SymptomStage {
  collecting,  // gathering symptoms
  askAge,      // backend asked for age
  askSex,      // backend asked for sex
  diagnosed,   // diagnosis returned
}

class ChatProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final _ws   = WebSocketService();

  HistoryProvider? _historyProvider;

  // ── Core state ────────────────────────────────────────
  List<MessageModel> _messages         = [];
  ChatSessionModel?  _activeSession;
  bool               _isTyping         = false;
  bool               _isStreaming      = false;
  bool               _isLoadingSession = false;
  String?            _errorMessage;
  String             _streamBuffer     = '';
  String?            _currentSessionId;

  // ── Mode & stage ──────────────────────────────────────
  ChatMode?    _chatMode;       // null = not selected yet (empty state)
  SymptomStage _symptomStage   = SymptomStage.collecting;
  Map<String, dynamic>? _diagnosisData; // holds last diagnosis payload

  // ── Getters ───────────────────────────────────────────
  List<MessageModel>    get messages         => List.unmodifiable(_messages);
  ChatSessionModel?     get activeSession    => _activeSession;
  bool                  get isTyping         => _isTyping;
  bool                  get isStreaming      => _isStreaming;
  bool                  get isLoadingSession => _isLoadingSession;
  String?               get errorMessage     => _errorMessage;
  bool                  get hasMessages      => _messages.isNotEmpty;
  ChatMode?             get chatMode         => _chatMode;
  bool                  get modeSelected     => _chatMode != null;
  bool                  get isFreeChat       => _chatMode == ChatMode.freeChat;
  bool                  get isSymptomMode    => _chatMode == ChatMode.symptomChecker;
  SymptomStage          get symptomStage     => _symptomStage;
  bool                  get isDiagnosed      => _symptomStage == SymptomStage.diagnosed;
  bool                  get isAskingSex      => _symptomStage == SymptomStage.askSex;
  bool                  get isAskingAge      => _symptomStage == SymptomStage.askAge;
  Map<String, dynamic>? get diagnosisData    => _diagnosisData;
  WsConnectionState     get wsState          => _ws.state;
  String?               get currentSessionId => _currentSessionId;

  // ── Firebase helpers ──────────────────────────────────
  User?  get _fbUser => FirebaseAuth.instance.currentUser;
  String get _uid    => _fbUser?.uid         ?? '';
  String get _email  => _fbUser?.email       ?? '';
  String get _name   => _fbUser?.displayName ?? 'AfyaSmart User';

  void setHistoryProvider(HistoryProvider p) => _historyProvider = p;

  // ─────────────────────────────────────────────────────
  //  Select mode from empty state
  // ─────────────────────────────────────────────────────
  void selectMode(ChatMode mode) {
    _chatMode         = mode;
    _symptomStage     = SymptomStage.collecting;
    _diagnosisData    = null;
    _currentSessionId = _uuid.v4();
    _messages         = [];
    _activeSession    = null;
    _errorMessage     = null;
    _ws.disconnect();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────
  //  Start fresh (clears mode too → back to empty state)
  // ─────────────────────────────────────────────────────
  void startNewChat() {
    _chatMode         = null;
    _messages         = [];
    _activeSession    = null;
    _isTyping         = false;
    _isStreaming      = false;
    _isLoadingSession = false;
    _errorMessage     = null;
    _streamBuffer     = '';
    _symptomStage     = SymptomStage.collecting;
    _diagnosisData    = null;
    _currentSessionId = null;
    _ws.disconnect();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────
  //  Load session from history
  // ─────────────────────────────────────────────────────
  Future<void> loadSession(
    ChatSessionModel session,
    HistoryProvider historyProvider,
  ) async {
    _ws.disconnect();
    _isLoadingSession = true;
    _activeSession    = session;
    _currentSessionId = session.id;
    _messages         = [];
    _errorMessage     = null;
    _chatMode         = ChatMode.freeChat; // history sessions default to free
    _symptomStage     = SymptomStage.collecting;
    _diagnosisData    = null;
    notifyListeners();

    try {
      final hydrated =
          await historyProvider.fetchSessionMessages(session.id);
      if (hydrated != null) {
        _activeSession = hydrated;
        _messages      = List.from(hydrated.messages);
      } else {
        _messages = List.from(session.messages);
      }
    } catch (_) {
      _errorMessage = 'Could not load messages.';
      _messages     = List.from(session.messages);
    } finally {
      _isLoadingSession = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────
  //  Send message (router)
  // ─────────────────────────────────────────────────────
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _uid.isEmpty) return;
    _clearError();
    _addUserMessage(content.trim());

    if (isFreeChat) {
      await _sendViaWebSocket(content.trim());
    } else {
      await _sendSymptoms(content.trim());
    }
  }

  // ─────────────────────────────────────────────────────
  //  WebSocket — free chat
  // ─────────────────────────────────────────────────────
  Future<void> _sendViaWebSocket(String content) async {
    _ensureSessionId();

    if (!_ws.isConnected) {
      await _ws.connect(
        sessionId:   _currentSessionId!,
        firebaseUid: _uid,
      );
    }

    if (!_ws.isConnected) {
      await _sendViaHttp(content);
      return;
    }

    final streamId = _uuid.v4();
    _addStreamingBubble(streamId);
    _streamBuffer = '';

    _ws.onChunk = (chunk) {
      _streamBuffer += chunk;
      _updateStreamingBubble(streamId, _streamBuffer);
    };
    _ws.onDone = () {
      _finaliseStreamingBubble(streamId, _streamBuffer);
      _clearWsCallbacks();
    };
    _ws.onError = (error) {
      _removeStreamingBubble(streamId);
      _setError(error);
      _clearWsCallbacks();
    };

    _ws.sendMessage(content);
  }

  // ─────────────────────────────────────────────────────
  //  HTTP fallback — free chat
  // ─────────────────────────────────────────────────────
  Future<void> _sendViaHttp(String content) async {
    _isTyping = true;
    notifyListeners();
    try {
      final res = await ApiService.sendChat(
        message:     content,
        firebaseUid: _uid,
        email:       _email,
        displayName: _name,
        sessionId:   _currentSessionId,
      );
      _currentSessionId = res['session_id'] as String? ?? _currentSessionId;
      _addAssistantMessage(res['response'] as String? ?? '');
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Connection failed. Check your network.');
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────
  //  HTTP — symptom checker
  // ─────────────────────────────────────────────────────
  Future<void> _sendSymptoms(String content) async {
    _isTyping = true;
    notifyListeners();

    try {
      final res = await ApiService.sendSymptoms(
        message:     content,
        firebaseUid: _uid,
        email:       _email,
        displayName: _name,
        sessionId:   _currentSessionId,
      );

      _currentSessionId = res['session_id'] as String? ?? _currentSessionId;

      final stage    = res['stage']    as String? ?? '';
      final response = res['response'] as String? ?? '';

      // ── Update stage from backend response ────────────
      _updateSymptomStage(stage, res);

      // ── Only add a text bubble if NOT diagnosed ───────
      // Diagnosis is rendered as a special card, not a bubble
      if (_symptomStage != SymptomStage.diagnosed) {
        _addAssistantMessage(response);
      }
    } on ApiException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Connection failed. Check your network.');
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────
  //  Stage tracker
  // ─────────────────────────────────────────────────────
  void _updateSymptomStage(String stage, Map<String, dynamic> res) {
    switch (stage) {
      case 'ask_age':
        _symptomStage = SymptomStage.askAge;
        break;
      case 'ask_sex':
        _symptomStage = SymptomStage.askSex;
        break;
      case 'diagnosed':
        _symptomStage  = SymptomStage.diagnosed;
        // Store diagnosis payload for the card widget
        _diagnosisData = {
          'response':  res['response'],
          'sessionId': _currentSessionId,
        };
        break;
      default:
        _symptomStage = SymptomStage.collecting;
    }
  }

  // ─────────────────────────────────────────────────────
  //  Streaming bubble lifecycle
  // ─────────────────────────────────────────────────────
  void _addStreamingBubble(String id) {
    _isStreaming = true;
    _isTyping    = true;
    _messages.add(MessageModel.assistant(
      id:      id,
      content: '',
      status:  MessageStatus.sending,
    ));
    notifyListeners();
  }

  void _updateStreamingBubble(String id, String content) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    _messages[idx] = _messages[idx].copyWith(content: content);
    notifyListeners();
  }

  void _finaliseStreamingBubble(String id, String content) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    _messages[idx] = _messages[idx].copyWith(
      content: content,
      status:  MessageStatus.sent,
    );
    _isStreaming = false;
    _isTyping    = false;
    _syncSessionToHistory();
    notifyListeners();
  }

  void _removeStreamingBubble(String id) {
    _messages.removeWhere((m) => m.id == id);
    _isStreaming = false;
    _isTyping    = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────
  //  Message helpers
  // ─────────────────────────────────────────────────────
  void _addUserMessage(String content) {
    _messages.add(MessageModel.user(id: _uuid.v4(), content: content));
    _isTyping = true;
    notifyListeners();
  }

  void _addAssistantMessage(String content) {
    _messages.add(MessageModel.assistant(id: _uuid.v4(), content: content));
    _isTyping = false;
    _syncSessionToHistory();
    notifyListeners();
  }

  void _syncSessionToHistory() {
    if (_historyProvider == null) return;
    final firstMsg = _messages
        .where((m) => m.isUser)
        .map((m) => m.content)
        .firstOrNull ?? 'New Chat';
    final title = firstMsg.length > 45
        ? '${firstMsg.substring(0, 45)}...'
        : firstMsg;
    _activeSession = ChatSessionModel(
      id:        _currentSessionId ?? _uuid.v4(),
      title:     title,
      messages:  List.from(_messages),
      createdAt: _activeSession?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _historyProvider!.upsertSession(_activeSession!);
  }

  void _ensureSessionId() {
    _currentSessionId ??= _uuid.v4();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _isTyping     = false;
    _isStreaming  = false;
    notifyListeners();
  }

  void _clearError()       => _errorMessage = null;
  void clearError()        { _errorMessage = null; notifyListeners(); }
  void _clearWsCallbacks() {
    _ws.onChunk = null;
    _ws.onDone  = null;
    _ws.onError = null;
  }

  @override
  void dispose() {
    _ws.dispose();
    super.dispose();
  }
}
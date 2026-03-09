import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_constants.dart';
import '../models/chat_session.dart';
import '../models/message_model.dart';


class ChatProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<MessageModel> _messages = [];
  ChatSessionModel?  _activeSession;
  bool               _isTyping = false;
  String?            _errorMessage;

  // ── Getters ──────────────────────────────────────────
  List<MessageModel> get messages       => List.unmodifiable(_messages);
  ChatSessionModel?  get activeSession  => _activeSession;
  bool               get isTyping       => _isTyping;
  String?            get errorMessage   => _errorMessage;
  bool               get hasMessages    => _messages.isNotEmpty;

  // ── Start a new session ───────────────────────────────
// ✅ FIXED — truly empty, lets _EmptyState render
void startNewChat() {
  _messages      = [];
  _activeSession = null;
  _isTyping      = false;
  _errorMessage  = null;
  notifyListeners();
}

  // ── Send message (UI stub) ────────────────────────────
  Future<void> sendMessage(String content) async {
  if (content.trim().isEmpty) return;

  // 1. Add user message
  final userMsg = MessageModel.user(
    id:      _uuid.v4(),
    content: content.trim(),
  );
  _messages.add(userMsg);
  _isTyping     = true;
  _errorMessage = null;
  notifyListeners();

  // 2. Simulate AI thinking delay
  await Future.delayed(const Duration(milliseconds: 1500));

  // 3. First message in session gets a warm greeting prefix
  final isFirstMessage = _messages.length == 1;
  final responseContent = isFirstMessage
      ? 'Hi! I\'m Afya 👋 — ${_mockAiResponse(content)}'
      : _mockAiResponse(content);

  // 4. Add AI response
  final aiMsg = MessageModel.assistant(
    id:      _uuid.v4(),
    content: responseContent,
  );
  _messages.add(aiMsg);
  _isTyping = false;
  notifyListeners();

  // 5. Auto-title session from first user message
  if (_activeSession == null) {
    _createSession(userMsg.content);
  }
}

  // ── Load an existing session ──────────────────────────
  void loadSession(ChatSessionModel session) {
    _activeSession = session;
    _messages      = List.from(session.messages);
    _isTyping      = false;
    notifyListeners();
  }

  // ── Clear current chat ────────────────────────────────
  void clearChat() {
    _messages      = [];
    _activeSession = null;
    _isTyping      = false;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────
  void _createSession(String firstMessage) {
    final title = firstMessage.length > 40
        ? '${firstMessage.substring(0, 40)}...'
        : firstMessage;

    _activeSession = ChatSessionModel(
      id:        _uuid.v4(),
      title:     title,
      messages:  List.from(_messages),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  String _mockAiResponse(String userInput) {
    // Stub responses — replace with real API call later
    final input = userInput.toLowerCase();
    if (input.contains('headache') || input.contains('head')) {
      return 'Headaches can result from many causes including tension, '
          'dehydration, lack of sleep, or underlying conditions. '
          'Common remedies include rest, hydration, and over-the-counter '
          'pain relief. If headaches are severe, frequent, or accompanied '
          'by other symptoms, please consult a healthcare provider.\n\n'
          '${AppConstants.aiDisclaimer}';
    }
    if (input.contains('fever')) {
      return 'A fever (temperature above 38°C / 100.4°F) is often the '
          'body\'s response to infection. Rest, fluids, and paracetamol '
          'or ibuprofen can help manage mild fevers. Seek immediate care '
          'for fevers above 39.5°C, fevers lasting more than 3 days, or '
          'if accompanied by severe symptoms.\n\n'
          '${AppConstants.aiDisclaimer}';
    }
    return 'Thank you for your question. As your medical AI assistant, '
        'I\'m here to provide general health information and guidance. '
        'Could you share more details about your concern so I can give '
        'you the most relevant information?\n\n'
        '${AppConstants.aiDisclaimer}';
  }
}
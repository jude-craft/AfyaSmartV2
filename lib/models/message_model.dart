enum MessageRole { user, assistant }

enum MessageStatus { sending, sent, error }

class MessageModel {
  final String id;
  final String content;
  final MessageRole role;
  final MessageStatus status;
  final DateTime timestamp;

  const MessageModel({
    required this.id,
    required this.content,
    required this.role,
    this.status = MessageStatus.sent,
    required this.timestamp,
  });

  // ── Convenience constructors ──────────────────────────
  factory MessageModel.user({
    required String id,
    required String content,
  }) {
    return MessageModel(
      id:        id,
      content:   content,
      role:      MessageRole.user,
      status:    MessageStatus.sent,
      timestamp: DateTime.now(),
    );
  }

  factory MessageModel.assistant({
    required String id,
    required String content,
    MessageStatus status = MessageStatus.sent,
  }) {
    return MessageModel(
      id:        id,
      content:   content,
      role:      MessageRole.assistant,
      status:    status,
      timestamp: DateTime.now(),
    );
  }

  // ── Serialization ─────────────────────────────────────
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id:        json['id'] as String,
      content:   json['content'] as String,
      role:      MessageRole.values.byName(json['role'] as String),
      status:    MessageStatus.values.byName(
                   json['status'] as String? ?? 'sent'),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':        id,
    'content':   content,
    'role':      role.name,
    'status':    status.name,
    'timestamp': timestamp.toIso8601String(),
  };

  // ── Helpers ──────────────────────────────────────────
  bool get isUser      => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSending   => status == MessageStatus.sending;
  bool get hasError    => status == MessageStatus.error;

  MessageModel copyWith({
    String?        id,
    String?        content,
    MessageRole?   role,
    MessageStatus? status,
    DateTime?      timestamp,
  }) {
    return MessageModel(
      id:        id        ?? this.id,
      content:   content   ?? this.content,
      role:      role      ?? this.role,
      status:    status    ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
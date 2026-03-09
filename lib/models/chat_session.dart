import 'message_model.dart';

class ChatSessionModel {
  final String id;
  final String title;
  final List<MessageModel> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatSessionModel({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Convenience ──────────────────────────────────────
  String get lastMessagePreview {
    if (messages.isEmpty) return 'No messages yet';
    final last = messages.last;
    final text = last.content;
    return text.length > 60 ? '${text.substring(0, 60)}...' : text;
  }

  bool get isEmpty => messages.isEmpty;
  int  get messageCount => messages.length;

  // ── Serialization ─────────────────────────────────────
  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id:        json['id'] as String,
      title:     json['title'] as String,
      messages:  (json['messages'] as List<dynamic>)
                   .map((m) => MessageModel.fromJson(
                         m as Map<String, dynamic>))
                   .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':        id,
    'title':     title,
    'messages':  messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  ChatSessionModel copyWith({
    String?             id,
    String?             title,
    List<MessageModel>? messages,
    DateTime?           createdAt,
    DateTime?           updatedAt,
  }) {
    return ChatSessionModel(
      id:        id        ?? this.id,
      title:     title     ?? this.title,
      messages:  messages  ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'ChatSession(id: $id, title: $title, messages: ${messages.length})';
}
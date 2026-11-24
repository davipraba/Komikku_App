/// Model untuk merepresentasikan pesan dalam riwayat percakapan Asisten AI (FR-AI-09).
/// Disimpan di tabel lokal SQLite `ai_messages`.
class ChatMessage {
  final int? id;
  final String userId;
  final String role; // 'user' atau 'assistant'
  final String content;
  final String createdAt;

  ChatMessage({
    this.id,
    required this.userId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser => role == 'user';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'role': role,
      'content': content,
      'created_at': createdAt,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      role: map['role'] as String,
      content: map['content'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}

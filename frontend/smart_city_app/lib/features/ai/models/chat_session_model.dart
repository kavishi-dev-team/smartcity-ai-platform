class ChatSession {
  final int id;
  final int userId;
  final String? title;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.userId,
    this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

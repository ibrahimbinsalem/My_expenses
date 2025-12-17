class UserInsightModel {
  final int? id;
  final int userId;
  final String content;
  final DateTime createdAt;

  const UserInsightModel({
    this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory UserInsightModel.fromMap(Map<String, dynamic> map) {
    return UserInsightModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

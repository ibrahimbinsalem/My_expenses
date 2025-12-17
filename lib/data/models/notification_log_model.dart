class NotificationLogModel {
  final int? id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool isRead;

  const NotificationLogModel({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  NotificationLogModel copyWith({
    int? id,
    String? title,
    String? body,
    String? type,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationLogModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NotificationLogModel.fromMap(Map<String, dynamic> map) {
    return NotificationLogModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      createdAt: DateTime.parse(map['created_at'] as String),
      isRead: (map['is_read'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }
}

class ReminderModel {
  final int? id;
  final int? userId;
  final String message;
  final DateTime date;
  final String time;

  const ReminderModel({
    this.id,
    this.userId,
    required this.message,
    required this.date,
    required this.time,
  });

  ReminderModel copyWith({
    int? id,
    int? userId,
    String? message,
    DateTime? date,
    String? time,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      date: date ?? this.date,
      time: time ?? this.time,
    );
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      message: map['message'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String? ?? '08:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'message': message,
      'date': date.toIso8601String(),
      'time': time,
    };
  }
}

class UserModel {
  final int? id;
  final String name;
  final DateTime createdAt;
  final int avatarIndex;

  const UserModel({
    this.id,
    required this.name,
    required this.createdAt,
    this.avatarIndex = 0,
  });

  UserModel copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    int? avatarIndex,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      avatarIndex: avatarIndex ?? this.avatarIndex,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      avatarIndex: map['avatar_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'avatar_index': avatarIndex,
    };
  }
}

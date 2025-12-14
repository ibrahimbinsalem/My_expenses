class UserModel {
  final int? id;
  final String name;
  final DateTime createdAt;

  const UserModel({this.id, required this.name, required this.createdAt});

  UserModel copyWith({int? id, String? name, DateTime? createdAt}) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'created_at': createdAt.toIso8601String()};
  }
}

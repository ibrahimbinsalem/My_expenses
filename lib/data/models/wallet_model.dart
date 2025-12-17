class WalletModel {
  final int? id;
  final int? userId;
  final String name;
  final String type;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final bool isGoal;

  const WalletModel({
    this.id,
    this.userId,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.createdAt,
    this.isGoal = false,
  });

  WalletModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? type,
    double? balance,
    String? currency,
    DateTime? createdAt,
    bool? isGoal,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      isGoal: isGoal ?? this.isGoal,
    );
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'cash',
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'SAR',
      createdAt: DateTime.parse(map['created_at'] as String),
      isGoal: (map['is_goal'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'is_goal': isGoal ? 1 : 0,
    };
  }
}

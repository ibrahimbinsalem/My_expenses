enum TransactionType { income, expense, saving }

class TransactionModel {
  final int? id;
  final int walletId;
  final int categoryId;
  final double amount;
  final TransactionType type;
  final String? note;
  final DateTime date;
  final String? imagePath;
  final int? goalId;

  const TransactionModel({
    this.id,
    required this.walletId,
    required this.categoryId,
    required this.amount,
    required this.type,
    this.note,
    required this.date,
    this.imagePath,
    this.goalId,
  });

  TransactionModel copyWith({
    int? id,
    int? walletId,
    int? categoryId,
    double? amount,
    TransactionType? type,
    String? note,
    DateTime? date,
    String? imagePath,
    int? goalId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      goalId: goalId ?? this.goalId,
    );
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      walletId: map['wallet_id'] as int,
      categoryId: map['category_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      type: _typeFromString(map['type'] as String),
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      imagePath: map['image_path'] as String?,
      goalId: map['goal_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wallet_id': walletId,
      'category_id': categoryId,
      'amount': amount,
      'type': type.name,
      'note': note,
      'date': date.toIso8601String(),
      'image_path': imagePath,
      'goal_id': goalId,
    };
  }

  static TransactionType _typeFromString(String raw) {
    switch (raw) {
      case 'income':
        return TransactionType.income;
      case 'saving':
        return TransactionType.saving;
      default:
        return TransactionType.expense;
    }
  }
}

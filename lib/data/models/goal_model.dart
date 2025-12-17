class GoalModel {
  final int? id;
  final int? userId;
  final int? walletId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String? currency;

  const GoalModel({
    this.id,
    this.userId,
    this.walletId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    this.currency,
  });

  double get progress {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount).clamp(0, 1);
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      walletId: map['wallet_id'] as int?,
      name: map['name'] as String? ?? '',
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      deadline: DateTime.parse(map['deadline'] as String),
      currency: map['currency'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'wallet_id': walletId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'currency': currency,
    };
  }
}

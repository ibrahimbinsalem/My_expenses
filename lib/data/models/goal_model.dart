class GoalModel {
  final int? id;
  final int? userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;

  const GoalModel({
    this.id,
    this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
  });

  double get progress {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount).clamp(0, 1);
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      name: map['name'] as String? ?? '',
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      deadline: DateTime.parse(map['deadline'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline.toIso8601String(),
    };
  }
}

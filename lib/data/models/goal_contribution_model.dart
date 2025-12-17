class GoalContributionModel {
  final int? id;
  final int goalId;
  final double amount;
  final String? note;
  final DateTime createdAt;

  const GoalContributionModel({
    this.id,
    required this.goalId,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  factory GoalContributionModel.fromMap(Map<String, dynamic> map) {
    return GoalContributionModel(
      id: map['id'] as int?,
      goalId: map['goal_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'amount': amount,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

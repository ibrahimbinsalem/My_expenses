import 'package:intl/intl.dart';

import '../../../data/models/goal_model.dart';
import '../../../data/models/transaction_model.dart';

class CategoryReportEntry {
  final String name;
  final double value;

  const CategoryReportEntry({required this.name, required this.value});
}

class GoalReportEntry {
  final GoalModel goal;
  final double contributionsInRange;

  const GoalReportEntry({
    required this.goal,
    required this.contributionsInRange,
  });

  double get progress {
    if (goal.targetAmount <= 0) return 0;
    return (goal.currentAmount / goal.targetAmount).clamp(0, 1);
  }

  double get remaining =>
      (goal.targetAmount - goal.currentAmount).clamp(0, goal.targetAmount);
}

enum ActivityGrouping { daily, weekly, monthly }

class ActivityBucket {
  final ActivityGrouping grouping;
  final DateTime start;
  final DateTime end;
  final List<TransactionModel> transactions;

  ActivityBucket({
    required this.grouping,
    required this.start,
    required this.end,
    required this.transactions,
  });

  double get income => transactions
      .where((tx) => tx.type == TransactionType.income)
      .fold(0, (sum, tx) => sum + tx.amount);

  double get expense => transactions
      .where((tx) => tx.type != TransactionType.income)
      .fold(0, (sum, tx) => sum + tx.amount);

  double get net => income - expense;

  String get label {
    final formatter = DateFormat('dd/MM');
    switch (grouping) {
      case ActivityGrouping.daily:
        return formatter.format(start);
      case ActivityGrouping.weekly:
        return '${formatter.format(start)}-${formatter.format(end)}';
      case ActivityGrouping.monthly:
        return DateFormat('MM/yyyy').format(start);
    }
  }
}

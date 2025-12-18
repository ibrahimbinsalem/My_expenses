import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/goal_model.dart';
import '../../../data/repositories/local_expense_repository.dart';
import '../models/report_view_models.dart';

class GoalsReportController extends GetxController {
  GoalsReportController(this._repository);

  final LocalExpenseRepository _repository;

  final Rx<DateTimeRange> dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  ).obs;

  final RxList<GoalModel> goals = <GoalModel>[].obs;
  final RxList<GoalReportEntry> entries = <GoalReportEntry>[].obs;
  final RxBool isLoading = false.obs;

  int get activeGoals =>
      goals.where((goal) => !goal.isCompleted && goal.walletId == null).length;

  int get archivedGoals =>
      goals.where((goal) => goal.walletId != null).length;

  double get totalSavedInRange =>
      entries.fold(0, (sum, entry) => sum + entry.contributionsInRange);

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> selectRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDateRange: dateRange.value,
      locale: Get.locale,
    );
    if (picked != null) {
      dateRange.value = picked;
      await loadData();
    }
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final fetchedGoals = await _repository.fetchGoals();
      goals.assignAll(fetchedGoals);
      final contributions = await _repository.goalContributionsByRange(
        dateRange.value.start,
        dateRange.value.end,
      );
      final mapped = fetchedGoals
          .map(
            (goal) => GoalReportEntry(
              goal: goal,
              contributionsInRange:
                  contributions[goal.id ?? -1] ?? 0,
            ),
          )
          .toList()
        ..sort((a, b) => b.goal.progress.compareTo(a.goal.progress));
      entries.assignAll(mapped);
    } finally {
      isLoading.value = false;
    }
  }
}

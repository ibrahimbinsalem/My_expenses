import 'package:get/get.dart';

import '../../../data/repositories/local_expense_repository.dart';

class InsightsController extends GetxController {
  InsightsController(this._repository);

  final LocalExpenseRepository _repository;

  final spendingByCategory = <String, double>{}.obs;
  final monthlyBudget = 3000.0.obs;
  final budgetUsage = 0.0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadInsights();
  }

  Future<void> loadInsights() async {
    isLoading.value = true;
    try {
      final now = DateTime.now();
      spendingByCategory.assignAll(await _repository.spendingByCategory(now));
      budgetUsage.value = await _repository.monthlyBudgetUsage(
        monthlyBudget.value,
        now,
      );
    } finally {
      isLoading.value = false;
    }
  }
}

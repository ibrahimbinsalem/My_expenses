import 'package:get/get.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/local_expense_repository.dart';
import '../../../data/services/ai_insight_service.dart';

class DashboardController extends GetxController {
  DashboardController(this._repository, this._insightService);

  final LocalExpenseRepository _repository;
  final LocalInsightService _insightService;

  final isLoading = false.obs;
  final totalBalance = 0.0.obs;
  final monthlySpending = <String, double>{}.obs;
  final insights = <String>[].obs;
  final recentTransactions = <TransactionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      totalBalance.value = await _repository.totalBalance();
      final now = DateTime.now();
      monthlySpending.assignAll(await _repository.spendingByCategory(now));
      final txns = await _repository.fetchTransactions(
        from: DateTime(now.year, now.month, 1),
        to: DateTime(now.year, now.month + 1, 0),
      );
      recentTransactions.assignAll(txns.take(5));
      insights.assignAll(await _insightService.generateInsights(txns));
    } finally {
      isLoading.value = false;
    }
  }
}

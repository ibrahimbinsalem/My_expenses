import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/wallet_report_stat.dart';
import '../../../data/repositories/local_expense_repository.dart';

class WalletReportController extends GetxController {
  WalletReportController(this._repository);

  final LocalExpenseRepository _repository;

  final Rx<DateTimeRange> dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  ).obs;

  final RxList<WalletReportStat> wallets = <WalletReportStat>[].obs;
  final RxBool isLoading = false.obs;

  double get totalIncome =>
      wallets.fold(0, (sum, entry) => sum + entry.income);

  double get totalExpense =>
      wallets.fold(0, (sum, entry) => sum + entry.expense);

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
      final stats = await _repository.walletReport(
        dateRange.value.start,
        dateRange.value.end,
      );
      wallets.assignAll(stats);
    } finally {
      isLoading.value = false;
    }
  }
}

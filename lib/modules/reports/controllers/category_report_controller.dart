import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/local_expense_repository.dart';
import '../models/report_view_models.dart';

class CategoryReportController extends GetxController {
  CategoryReportController(this._repository);

  final LocalExpenseRepository _repository;

  final Rx<DateTimeRange> dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  ).obs;

  final RxList<CategoryReportEntry> entries = <CategoryReportEntry>[].obs;
  final RxBool isLoading = false.obs;

  double get totalSpending =>
      entries.fold(0, (sum, entry) => sum + entry.value);

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
      final map = await _repository.spendingByCategoryRange(
        dateRange.value.start,
        dateRange.value.end,
      );
      final items = map.entries
          .map(
            (e) => CategoryReportEntry(
              name: e.key,
              value: e.value,
            ),
          )
          .toList();
      items.sort((a, b) => b.value.compareTo(a.value));
      entries.assignAll(items);
    } finally {
      isLoading.value = false;
    }
  }
}

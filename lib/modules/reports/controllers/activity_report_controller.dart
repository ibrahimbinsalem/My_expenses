import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/local_expense_repository.dart';
import '../models/report_view_models.dart';

class ActivityReportController extends GetxController {
  ActivityReportController(this._repository);

  final LocalExpenseRepository _repository;

  final Rx<DateTimeRange> dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  ).obs;

  final RxList<ActivityBucket> dailyBuckets = <ActivityBucket>[].obs;
  final RxList<ActivityBucket> weeklyBuckets = <ActivityBucket>[].obs;
  final RxList<ActivityBucket> monthlyBuckets = <ActivityBucket>[].obs;
  final RxBool isLoading = false.obs;

  Map<int, String> walletNames = {};
  Map<int, String> categoryNames = {};

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> selectRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2021),
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
      final transactions = await _repository.fetchTransactions(
        from: dateRange.value.start,
        to: dateRange.value.end,
      );
      final wallets = await _repository.fetchWallets(includeGoal: true);
      final categories = await _repository.fetchCategories();
      walletNames = {
        for (final wallet in wallets) wallet.id ?? -1: wallet.name,
      };
      categoryNames = {
        for (final category in categories) category.id ?? -1: category.name,
      };
      dailyBuckets.assignAll(
        _buildBuckets(transactions, ActivityGrouping.daily),
      );
      weeklyBuckets.assignAll(
        _buildBuckets(transactions, ActivityGrouping.weekly),
      );
      monthlyBuckets.assignAll(
        _buildBuckets(transactions, ActivityGrouping.monthly),
      );
    } finally {
      isLoading.value = false;
    }
  }

  List<ActivityBucket> _buildBuckets(
    List<TransactionModel> transactions,
    ActivityGrouping grouping,
  ) {
    final Map<String, _BucketData> map = {};
    for (final tx in transactions) {
      final keyData = _bucketKey(tx.date, grouping);
      map.putIfAbsent(keyData.key, () => keyData).transactions.add(tx);
    }
    final buckets = map.values
        .map(
          (data) => ActivityBucket(
            grouping: grouping,
            start: data.start,
            end: data.end,
            transactions: data.transactions,
          ),
        )
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return buckets;
  }

  _BucketData _bucketKey(DateTime date, ActivityGrouping grouping) {
    switch (grouping) {
      case ActivityGrouping.daily:
        final start = DateTime(date.year, date.month, date.day);
        final end = start.add(const Duration(days: 1)).subtract(
          const Duration(milliseconds: 1),
        );
        return _BucketData(
          key: 'day-${start.toIso8601String()}',
          start: start,
          end: end,
        );
      case ActivityGrouping.weekly:
        final start =
            date.subtract(Duration(days: date.weekday - DateTime.monday));
        final normalized = DateTime(start.year, start.month, start.day);
        final end = normalized.add(const Duration(days: 6, hours: 23, minutes: 59));
        return _BucketData(
          key: 'week-${normalized.toIso8601String()}',
          start: normalized,
          end: end,
        );
      case ActivityGrouping.monthly:
        final start = DateTime(date.year, date.month, 1);
        final end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
        return _BucketData(
          key: 'month-${start.toIso8601String()}',
          start: start,
          end: end,
        );
    }
  }

  String walletName(int id) => walletNames[id] ?? 'محفظة';
  String categoryName(int id) => categoryNames[id] ?? 'فئة';
}

class _BucketData {
  _BucketData({
    required this.key,
    required this.start,
    required this.end,
  });

  final String key;
  final DateTime start;
  final DateTime end;
  final List<TransactionModel> transactions = [];
}

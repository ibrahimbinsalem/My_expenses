import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction_model.dart';
import '../controllers/activity_report_controller.dart';
import '../models/report_view_models.dart';
import '../widgets/report_range_header.dart';

class ActivityReportView extends GetView<ActivityReportController> {
  const ActivityReportView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ActivityReportController(Get.find()));
    return Scaffold(
      appBar: AppBar(title: Text('reports.activity.title'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ReportRangeHeader(
              range: controller.dateRange.value,
              onPick: () => controller.selectRange(context),
              title: 'reports.range.title'.tr,
            ),
            const SizedBox(height: 12),
            _ActivitySection(
              title: 'reports.activity.daily'.tr,
              buckets: controller.dailyBuckets,
              onBucketTap: (bucket) => _showBucketDetails(context, bucket),
            ),
            const SizedBox(height: 16),
            _ActivitySection(
              title: 'reports.activity.weekly'.tr,
              buckets: controller.weeklyBuckets,
              onBucketTap: (bucket) => _showBucketDetails(context, bucket),
            ),
            const SizedBox(height: 16),
            _ActivitySection(
              title: 'reports.activity.monthly'.tr,
              buckets: controller.monthlyBuckets,
              onBucketTap: (bucket) => _showBucketDetails(context, bucket),
            ),
          ],
        );
      }),
    );
  }

  void _showBucketDetails(BuildContext context, ActivityBucket bucket) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(bucket.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              'reports.activity.operationsCount'.trParams({
                'count': bucket.transactions.length.toString(),
              }),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: ListView.builder(
                itemCount: bucket.transactions.length,
                itemBuilder: (_, index) {
                  final tx = bucket.transactions[index];
                  return ListTile(
                    leading: Icon(
                      tx.type == TransactionType.income
                          ? Icons.call_received
                          : Icons.call_made,
                      color: tx.type == TransactionType.income
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(Formatters.currency(tx.amount, symbol: '')),
                    subtitle: Text(Formatters.longDate(tx.date)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.title,
    required this.buckets,
    required this.onBucketTap,
  });

  final String title;
  final List<ActivityBucket> buckets;
  final ValueChanged<ActivityBucket> onBucketTap;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('reports.noData'.tr),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SizedBox(
            height: 240,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index < 0 || index >= buckets.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              buckets[index].label,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < buckets.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: buckets[i].net,
                            color: buckets[i].net >= 0
                                ? Colors.green
                                : Colors.red,
                            width: 14,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...buckets.map(
          (bucket) => ListTile(
            title: Text(bucket.label),
            subtitle: Text(
              'reports.activity.summary'.trParams({
                'income': bucket.income.toStringAsFixed(1),
                'expense': bucket.expense.toStringAsFixed(1),
              }),
            ),
            trailing: Text(
              bucket.net.toStringAsFixed(1),
              style: TextStyle(
                color: bucket.net >= 0 ? Colors.green : Colors.red,
              ),
            ),
            onTap: () => onBucketTap(bucket),
          ),
        ),
      ],
    );
  }
}

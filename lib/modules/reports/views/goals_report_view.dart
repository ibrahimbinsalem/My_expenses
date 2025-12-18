import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/goals_report_controller.dart';
import '../models/report_view_models.dart';
import '../widgets/report_range_header.dart';

class GoalsReportView extends GetView<GoalsReportController> {
  const GoalsReportView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(GoalsReportController(Get.find()));
    return Scaffold(
      appBar: AppBar(title: Text('reports.goals.title'.tr)),
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
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _GoalStat(
                      label: 'reports.goals.active'.tr,
                      value: controller.activeGoals.toString(),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _GoalStat(
                      label: 'reports.goals.archived'.tr,
                      value: controller.archivedGoals.toString(),
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    _GoalStat(
                      label: 'reports.goals.periodSaved'.tr,
                      value: controller.totalSavedInRange.toStringAsFixed(1),
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _GoalBarChart(entries: controller.entries),
            const SizedBox(height: 16),
            ...controller.entries.map(
              (entry) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.goal.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: entry.progress,
                        color: Colors.blue,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'reports.goals.progress'
                            .trParams({
                              'value':
                                  (entry.progress * 100).toStringAsFixed(0),
                            }),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'reports.goals.contributions'.trParams({
                          'value':
                              entry.contributionsInRange.toStringAsFixed(2),
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _GoalStat extends StatelessWidget {
  const _GoalStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalBarChart extends StatelessWidget {
  const _GoalBarChart({required this.entries});

  final List<GoalReportEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        height: 260,
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
                    if (index < 0 || index >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entries[index].goal.name,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < entries.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: entries[i].goal.currentAmount,
                      color: Colors.blueAccent,
                      width: 12,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/insights_controller.dart';

class InsightsView extends GetView<InsightsController> {
  const InsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التحليلات الذكية')),
      body: Obx(
        () =>
            controller.isLoading.value && controller.spendingByCategory.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _BudgetUsageCard(
                    usage: controller.budgetUsage.value,
                    budget: controller.monthlyBudget.value,
                  ),
                  const SizedBox(height: 16),
                  _CategoryInsightChart(data: controller.spendingByCategory),
                ],
              ),
      ),
    );
  }
}

class _BudgetUsageCard extends StatelessWidget {
  const _BudgetUsageCard({required this.usage, required this.budget});

  final double usage;
  final double budget;

  @override
  Widget build(BuildContext context) {
    final percent = (usage * 100).clamp(0, 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('استخدام الميزانية الشهرية'),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: usage,
            backgroundColor: Colors.grey.shade200,
            color: usage > 0.8 ? AppColors.danger : AppColors.accent,
          ),
          const SizedBox(height: 12),
          Text(
            'المتبقي ${(100 - double.parse(percent)).toStringAsFixed(0)}% من $budget ريال',
          ),
          Text(
            usage > 1 ? 'تنبيه: تجاوزت الميزانية!' : 'أنت على المسار الصحيح 👍',
            style: TextStyle(
              color: usage > 1 ? AppColors.danger : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryInsightChart extends StatelessWidget {
  const _CategoryInsightChart({required this.data});

  final Map<String, double> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('لا توجد بيانات كافية لعرض المخطط.'),
      );
    }

    int index = 0;
    final colors = [
      Colors.blueGrey,
      Colors.deepPurple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    final sections = data.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      return PieChartSectionData(
        title: entry.key,
        value: entry.value,
        color: color,
        radius: 70,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('مخطط الفئات'),
          SizedBox(
            height: 240,
            child: PieChart(PieChartData(sectionsSpace: 3, sections: sections)),
          ),
        ],
      ),
    );
  }
}

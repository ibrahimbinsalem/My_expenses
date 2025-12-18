import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/category_report_controller.dart';
import '../models/report_view_models.dart';
import '../widgets/report_range_header.dart';

class CategoryReportView extends GetView<CategoryReportController> {
  const CategoryReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('reports.category.title'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.entries.isEmpty) {
          return Center(child: Text('reports.noData'.tr));
        }
        final entries = controller.entries;
        final total = controller.totalSpending;
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
              child: SizedBox(
                height: 280,
                child: PieChart(
                  PieChartData(
                    sections: _buildSections(entries, total),
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'reports.category.total'
                  .trParams({'amount': total.toStringAsFixed(2)}),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...entries.map(
              (entry) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: _colorForIndex(entries.indexOf(entry)),
                ),
                title: Text(entry.name),
                subtitle: Text(
                  'reports.category.percent'
                      .trParams({'value': ((entry.value / total) * 100).toStringAsFixed(1)}),
                ),
                trailing: Text(entry.value.toStringAsFixed(2)),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<CategoryReportEntry> entries,
    double total,
  ) {
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final value = entry.value;
      final percent = total == 0 ? 0 : value / total * 100;
      return PieChartSectionData(
        value: value,
        color: _colorForIndex(index),
        title: '${percent.toStringAsFixed(1)}%',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    });
  }

  Color _colorForIndex(int index) {
    const palette = [
      Color(0xFF3BB78F),
      Color(0xFFF4C95B),
      Color(0xFFEF709B),
      Color(0xFF5B86E5),
      Color(0xFF00C9FF),
      Color(0xFFa1c4fd),
    ];
    return palette[index % palette.length];
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/api_keys.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/insights_controller.dart';

class InsightsView extends GetView<InsightsController> {
  const InsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('التحليلات الذكية'.tr)),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.spendingByCategory.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadInsights,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              if (!controller.isOnline.value)
                _OfflineBanner(onRetry: controller.loadInsights),
              _BudgetUsageCard(
                usage: controller.budgetUsage.value,
                budget: controller.monthlyBudget.value,
                totalExpense: controller.totalExpense.value,
                wallets: controller.walletInsights,
              ),
              const SizedBox(height: 16),
              _CategoryInsightChart(data: controller.spendingByCategory),
              const SizedBox(height: 16),
              _MonthlyOverviewList(
                insights: controller.walletInsights,
                totalIncome: controller.totalIncome.value,
                totalExpense: controller.totalExpense.value,
              ),
              const SizedBox(height: 16),
              _WalletInsightsList(insights: controller.walletInsights),
              const SizedBox(height: 16),
              _AiSuggestionsCard(
                insights: controller.aiInsights,
                enabled: controller.aiFeatureEnabled.value,
                hasApiKey: ApiKeys.hasGeminiKey,
                isOnline: controller.isOnline.value,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MonthlyOverviewList extends StatelessWidget {
  const _MonthlyOverviewList({
    required this.insights,
    required this.totalIncome,
    required this.totalExpense,
  });

  final List<WalletInsight> insights;
  final double totalIncome;
  final double totalExpense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final net = totalIncome - totalExpense;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'insights.overview.title'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _OverviewTile(
                      label: 'insights.overview.income'.tr,
                      value: Formatters.currency(
                        totalIncome,
                        symbol: 'ريال'.tr,
                      ),
                      icon: Icons.trending_up,
                      color: Colors.white,
                      inverse: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OverviewTile(
                      label: 'insights.overview.expense'.tr,
                      value: Formatters.currency(
                        totalExpense,
                        symbol: 'ريال'.tr,
                      ),
                      icon: Icons.trending_down,
                      color: Colors.white,
                      inverse: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'insights.overview.net'.trParams({
                  'amount': Formatters.currency(net, symbol: 'ريال'.tr),
                }),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...insights.map(
          (insight) => Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                foregroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.wallet),
              ),
              title: Text(insight.wallet.name),
              subtitle: Text(
                'insights.overview.wallet_summary'.trParams({
                  'income': Formatters.currency(
                    insight.income,
                    symbol: insight.wallet.currency,
                  ),
                  'expense': Formatters.currency(
                    insight.expense,
                    symbol: insight.wallet.currency,
                  ),
                }),
              ),
              trailing: Text(
                Formatters.currency(
                  insight.net,
                  symbol: insight.wallet.currency,
                ),
                style: TextStyle(
                  color: insight.net >= 0
                      ? AppColors.success
                      : AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.inverse = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final textColor = inverse ? Colors.white : color;
    final secondaryColor = inverse
        ? Colors.white.withOpacity(0.8)
        : color.withOpacity(0.8);
    final backgroundColor = inverse
        ? Colors.white.withOpacity(0.15)
        : color.withOpacity(0.08);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: secondaryColor)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'insights.online_required.title'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'insights.online_required.message'.tr,
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: onRetry,
              child: Text('insights.online_required.retry'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetUsageCard extends StatelessWidget {
  const _BudgetUsageCard({
    required this.usage,
    required this.budget,
    required this.totalExpense,
    required this.wallets,
  });

  final double usage;
  final double budget;
  final double totalExpense;
  final List<WalletInsight> wallets;

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
          Text('استخدام الميزانية الشهرية'.tr),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: usage,
            backgroundColor: Colors.grey.shade200,
            color: usage > 0.8 ? AppColors.danger : AppColors.accent,
          ),
          const SizedBox(height: 12),
          Text(
            'المتبقي @percent% من @budget ريال'.trParams({
              'percent': (100 - double.parse(percent)).toStringAsFixed(0),
              'budget': budget.toStringAsFixed(0),
            }),
          ),
          Text(
            usage > 1
                ? 'تنبيه: تجاوزت الميزانية!'.tr
                : 'أنت على المسار الصحيح 👍'.tr,
            style: TextStyle(
              color: usage > 1 ? AppColors.danger : AppColors.success,
            ),
          ),
          if (wallets.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'insights.wallet.budget_title'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            ...wallets.map(
              (insight) => _WalletBudgetRow(insight: insight),
            ),
          ],
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
          gradient: const LinearGradient(
            colors: [Color(0xFF1C1C33), Color(0xFF2C2C48)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text('لا توجد بيانات كافية لعرض المخطط.'.tr),
      );
    }

    final colors = [
      Colors.tealAccent.shade400,
      Colors.deepPurple.shade300,
      Colors.orange.shade400,
      Colors.pinkAccent.shade200,
      Colors.blueAccent.shade200,
      Colors.greenAccent.shade400,
    ];

    final total = data.values.fold<double>(0, (sum, v) => sum + v);
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = List<PieChartSectionData>.generate(
      sortedEntries.length,
      (index) {
        final entry = sortedEntries[index];
        final color = colors[index % colors.length];
        final percent = total == 0 ? 0 : entry.value / total * 100;
        return PieChartSectionData(
          value: entry.value,
          color: color,
          radius: 90,
          title: '${percent.toStringAsFixed(1)}%',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        );
      },
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'مخطط الفئات'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: sortedEntries.map((entry) {
              final index = data.keys.toList().indexOf(entry.key);
              final color = colors[index % colors.length];
              final percent = total == 0
                  ? '0'
                  : (entry.value / total * 100).toStringAsFixed(1);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(backgroundColor: color, radius: 5),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AiSuggestionsCard extends StatelessWidget {
  const _AiSuggestionsCard({
    required this.insights,
    required this.enabled,
    required this.hasApiKey,
    required this.isOnline,
  });

  final List<String> insights;
  final bool enabled;
  final bool hasApiKey;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? helperText;
    if (!enabled) {
      helperText = 'insights.ai.disabled'.tr;
    } else if (!hasApiKey) {
      helperText = 'insights.ai.key_missing'.tr;
    } else if (!isOnline && insights.isEmpty) {
      helperText = 'insights.online_required.message'.tr;
    } else if (insights.isEmpty) {
      helperText = 'insights.ai.empty'.tr;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                'insights.ai.title'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (helperText != null)
            Text(
              helperText,
              style: const TextStyle(color: Colors.grey),
            )
          else
            ...insights.map(
              (tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 18)),
                    Expanded(child: Text(tip)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WalletInsightsList extends StatelessWidget {
  const _WalletInsightsList({required this.insights});

  final List<WalletInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text('insights.wallet.empty'.tr),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'insights.wallet.section_title'.tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...insights.map(
          (insight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _WalletInsightCard(data: insight),
          ),
        ),
      ],
    );
  }
}

class _WalletInsightCard extends StatelessWidget {
  const _WalletInsightCard({required this.data});

  final WalletInsight data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wallet, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.wallet.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Chip(
                label: Text(data.wallet.currency),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OverviewTile(
                  label: 'insights.wallet.income'.tr,
                  value: Formatters.currency(
                    data.income,
                    symbol: data.wallet.currency,
                  ),
                  icon: Icons.trending_up,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewTile(
                  label: 'insights.wallet.expense'.tr,
                  value: Formatters.currency(
                    data.expense,
                    symbol: data.wallet.currency,
                  ),
                  icon: Icons.trending_down,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'insights.wallet.net'.trParams({
              'amount': Formatters.currency(
                data.net,
                symbol: data.wallet.currency,
              ),
            }),
            style: TextStyle(
              color: data.net >= 0 ? AppColors.success : AppColors.danger,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (data.insights.isEmpty)
            Text(
              'insights.wallet.no_data'.tr,
              style: const TextStyle(color: Colors.grey),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.insights.take(2).map((tip) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _WalletBudgetRow extends StatelessWidget {
  const _WalletBudgetRow({required this.insight});

  final WalletInsight insight;

  @override
  Widget build(BuildContext context) {
    final usagePercent = (insight.budgetUsage * 100).clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  insight.wallet.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${usagePercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: insight.budgetUsage > 1
                      ? AppColors.danger
                      : AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: insight.budgetUsage.clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                insight.budgetUsage > 1 ? AppColors.danger : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'insights.wallet.budget_status'.trParams({
              'spent': Formatters.currency(
                insight.expense,
                symbol: insight.wallet.currency,
              ),
              'limit': Formatters.currency(
                insight.budgetLimit,
                symbol: insight.wallet.currency,
              ),
            }),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

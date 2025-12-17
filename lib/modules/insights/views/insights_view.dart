import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/api_keys.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../controllers/insights_controller.dart';
import '../../../routes/app_routes.dart';

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
              if (controller.goalInsights.value != null) ...[
                _GoalsInsightCard(
                  data: controller.goalInsights.value!,
                ),
                const SizedBox(height: 16),
              ],
              _MonthlyOverviewList(insights: controller.walletInsights),
              if (controller.cashflowSummaries.isNotEmpty) ...[
                const SizedBox(height: 16),
                _CashflowSection(
                  cashflows: controller.cashflowSummaries,
                ),
              ],
              const SizedBox(height: 16),
              if (controller.savingsReports.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SavingsReportsSection(reports: controller.savingsReports),
              ],
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

class _GoalsInsightCard extends StatelessWidget {
  const _GoalsInsightCard({required this.data});

  final GoalsInsightData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'goals.insights.title'.tr,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    Text(
                      'goals.insights.subtitle'.tr,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.goals),
                child: Text(
                  'goals.insights.manage'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _GoalChip(
                icon: Icons.flag_outlined,
                label: 'goals.insights.active'
                    .trParams({'count': data.activeCount.toString()}),
              ),
              _GoalChip(
                icon: Icons.archive_outlined,
                label: 'goals.insights.archived'
                    .trParams({'count': data.archivedCount.toString()}),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.remainingByCurrency.isNotEmpty)
            _CurrencyBreakdownRow(
              title: 'goals.insights.remaining_currency'.tr,
              entries: data.remainingByCurrency.entries.toList(),
            ),
          if (data.archivedByCurrency.isNotEmpty)
            _CurrencyBreakdownRow(
              title: 'goals.insights.archived_currency'.tr,
              entries: data.archivedByCurrency.entries.toList(),
            ),
          const SizedBox(height: 12),
          if (data.highlights.isEmpty)
            Text(
              'goals.insights.no_active'.tr,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.white70),
            )
          else ...[
            Text(
              'goals.insights.highlights'.tr,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...data.highlights.map(
              (highlight) => Card(
                color: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  leading: CircularProgressIndicator(
                    value: highlight.progress,
                    strokeWidth: 4,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                  title: Text(
                    highlight.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'goals.insights.deadline'.trParams({
                          'date': Formatters.shortDate(highlight.deadline),
                        }) +
                        ' • ' +
                        'goals.insights.progress'.trParams({
                          'percent':
                              (highlight.progress * 100).clamp(0, 100).toStringAsFixed(0),
                        }),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Text(
                    Formatters.currency(
                      highlight.remaining,
                      symbol: highlight.currency,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: Colors.white.withOpacity(0.12),
      avatar: Icon(icon, color: Colors.white70),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class _CurrencyBreakdownRow extends StatelessWidget {
  const _CurrencyBreakdownRow({required this.title, required this.entries});

  final String title;
  final List<MapEntry<String, double>> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries
              .map(
                (entry) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Formatters.currency(
                      entry.value,
                      symbol: entry.key,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MonthlyOverviewList extends StatelessWidget {
  const _MonthlyOverviewList({required this.insights});

  final List<WalletInsight> insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'insights.overview.title'.tr,
          style: theme.textTheme.titleMedium,
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

class _SavingsReportsSection extends StatelessWidget {
  const _SavingsReportsSection({required this.reports});

  final List<SavingsReport> reports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'savingsReports.title'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'savingsReports.subtitle'.tr,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth * 0.85;
            return SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final currency = report.wallet.currency;
                  final delta = report.deltaVsPrevious;
                  final deltaKey = delta >= 0
                      ? 'savingsReports.deltaUp'
                      : 'savingsReports.deltaDown';
                  final deltaText = delta.abs() < 1
                      ? 'savingsReports.deltaStable'.tr
                      : deltaKey.trParams({
                          'amount':
                              Formatters.currency(delta.abs(), symbol: currency),
                        });
                  return SizedBox(
                    width: itemWidth,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.9),
                              theme.colorScheme.primary.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.wallet.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              deltaText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Chip(
                                  backgroundColor: Colors.white.withOpacity(0.15),
                                  label: Text(
                                    'savingsReports.topCategory'.trParams({
                                      'name': report.topCategoryName,
                                    }),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Chip(
                                  backgroundColor: Colors.white.withOpacity(0.15),
                                  label: Text(
                                    Formatters.currency(
                                      report.topCategoryAmount,
                                      symbol: currency,
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _SavingsMetric(
                                    label: 'savingsReports.weeklyLabel'.tr,
                                    value: Formatters.currency(
                                      report.weeklyAverage,
                                      symbol: currency,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SavingsMetric(
                                    label: 'savingsReports.projectedLabel'.tr,
                                    value: Formatters.currency(
                                      report.projectedExpense,
                                      symbol: currency,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'savingsReports.tip'.trParams({
                                'category': report.topCategoryName,
                                'amount': Formatters.currency(
                                  report.suggestedCut,
                                  symbol: currency,
                                ),
                              }),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: reports.length,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SavingsMetric extends StatelessWidget {
  const _SavingsMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _GoalsInsightCard extends StatelessWidget {
  const _GoalsInsightCard({required this.data});

  final GoalsInsightData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'goals.insights.title'.tr,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    Text(
                      'goals.insights.subtitle'.tr,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.goals),
                child: Text(
                  'goals.insights.manage'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _GoalChip(
                icon: Icons.flag_outlined,
                label: 'goals.insights.active'
                    .trParams({'count': data.activeCount.toString()}),
              ),
              _GoalChip(
                icon: Icons.archive_outlined,
                label: 'goals.insights.archived'
                    .trParams({'count': data.archivedCount.toString()}),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.remainingByCurrency.isNotEmpty)
            _CurrencyBreakdownRow(
              title: 'goals.insights.remaining_currency'.tr,
              entries: data.remainingByCurrency.entries.toList(),
            ),
          if (data.archivedByCurrency.isNotEmpty)
            _CurrencyBreakdownRow(
              title: 'goals.insights.archived_currency'.tr,
              entries: data.archivedByCurrency.entries.toList(),
            ),
          const SizedBox(height: 12),
          if (data.highlights.isEmpty)
            Text(
              'goals.insights.no_active'.tr,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.white70),
            )
          else ...[
            Text(
              'goals.insights.highlights'.tr,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...data.highlights.map(
              (highlight) => Card(
                color: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  leading: CircularProgressIndicator(
                    value: highlight.progress,
                    strokeWidth: 4,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                  title: Text(
                    highlight.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'goals.insights.deadline'.trParams({
                          'date': Formatters.shortDate(highlight.deadline),
                        }) +
                        ' • ' +
                        'goals.insights.progress'.trParams({
                          'percent':
                              (highlight.progress * 100).clamp(0, 100).toStringAsFixed(0),
                        }),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Text(
                    Formatters.currency(
                      highlight.remaining,
                      symbol: highlight.currency,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: Colors.white.withOpacity(0.12),
      avatar: Icon(icon, color: Colors.white70),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class _CurrencyBreakdownRow extends StatelessWidget {
  const _CurrencyBreakdownRow({required this.title, required this.entries});

  final String title;
  final List<MapEntry<String, double>> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries
              .map(
                (entry) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Formatters.currency(
                      entry.value,
                      symbol: entry.key,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MonthlyOverviewList extends StatelessWidget {
  const _MonthlyOverviewList({required this.insights});

  final List<WalletInsight> insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'insights.overview.title'.tr,
          style: theme.textTheme.titleMedium,
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

class _SavingsReportsSection extends StatelessWidget {
  const _SavingsReportsSection({required this.reports});

  final List<SavingsReport> reports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'savingsReports.title'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'savingsReports.subtitle'.tr,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth * 0.85;
            return SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final currency = report.wallet.currency;
                  final delta = report.deltaVsPrevious;
                  final deltaKey = delta >= 0
                      ? 'savingsReports.deltaUp'
                      : 'savingsReports.deltaDown';
                  final deltaText = delta.abs() < 1
                      ? 'savingsReports.deltaStable'.tr
                      : deltaKey.trParams({
                          'amount':
                              Formatters.currency(delta.abs(), symbol: currency),
                        });
                  return SizedBox(
                    width: itemWidth,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.9),
                              theme.colorScheme.primary.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.wallet.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              deltaText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Chip(
                                  backgroundColor: Colors.white.withOpacity(0.15),
                                  label: Text(
                                    'savingsReports.topCategory'.trParams({
                                      'name': report.topCategoryName,
                                    }),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Chip(
                                  backgroundColor: Colors.white.withOpacity(0.15),
                                  label: Text(
                                    Formatters.currency(
                                      report.topCategoryAmount,
                                      symbol: currency,
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _SavingsMetric(
                                    label: 'savingsReports.weeklyLabel'.tr,
                                    value: Formatters.currency(
                                      report.weeklyAverage,
                                      symbol: currency,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SavingsMetric(
                                    label: 'savingsReports.projectedLabel'.tr,
                                    value: Formatters.currency(
                                      report.projectedExpense,
                                      symbol: currency,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'savingsReports.tip'.trParams({
                                'category': report.topCategoryName,
                                'amount': Formatters.currency(
                                  report.suggestedCut,
                                  symbol: currency,
                                ),
                              }),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: reports.length,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SavingsMetric extends StatelessWidget {
  const _SavingsMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CashflowSection extends StatelessWidget {
  const _CashflowSection({required this.cashflows});

  final List<WalletCashflow> cashflows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'cashflow.title'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: 'cashflow.info'.tr,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 48,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Text(
                            'cashflow.infoTitle'.tr,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ...[
                            'cashflow.infoIncome',
                            'cashflow.infoExpense',
                            'cashflow.infoProjection',
                          ].map(
                            (key) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.circle, size: 8),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(key.tr),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              icon: const Icon(Icons.info_outline),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'cashflow.subtitle'.tr,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...cashflows.map(
          (flow) => Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          flow.wallet.name,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Chip(
                        label: Text(
                          'cashflow.remaining'
                              .trParams({'days': flow.remainingDays.toString()}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CashflowMetric(
                          label: 'cashflow.income'.tr,
                          value: Formatters.currency(
                            flow.income,
                            symbol: flow.wallet.currency,
                          ),
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CashflowMetric(
                          label: 'cashflow.expense'.tr,
                          value: Formatters.currency(
                            flow.expense,
                            symbol: flow.wallet.currency,
                          ),
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CashflowMetric(
                    label: 'cashflow.projected'.tr,
                    value: Formatters.currency(
                      flow.net + flow.projectedNet,
                      symbol: flow.wallet.currency,
                    ),
                    color: flow.net + flow.projectedNet >= 0
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CashflowMetric extends StatelessWidget {
  const _CashflowMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
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

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('مصاريفي الذكي')),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: controller.loadDashboard,
          child:
              controller.isLoading.value &&
                  controller.recentTransactions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? const LinearGradient(
                            colors: [Color(0xFF101729), Color(0xFF0C111F)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFE6F2F5), Color(0xFFFDFDFD)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                  ),
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _BalanceCard(
                        total: controller.totalBalance.value,
                        currencyName: controller.primaryCurrencyName.value,
                        currencyCode: controller.primaryCurrencyCode.value,
                        onAddFunds: () => controller.openAddFundsSheet(context),
                      ),
                      const SizedBox(height: 16),
                      _SpendingChart(data: controller.monthlySpending),
                      const SizedBox(height: 16),
                      _InsightsList(insights: controller.insights),
                      const SizedBox(height: 16),
                      _RecentTransactions(
                        transactions: controller.recentTransactions,
                      ),
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(
          AppRoutes.addTransaction,
        )?.then((_) => controller.loadDashboard()),
        icon: const Icon(Icons.add),
        label: const Text('إضافة عملية'),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.navIndex.value,
          onDestinationSelected: controller.onNavDestinationSelected,
          indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
          destinations: controller.navItems
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.total,
    required this.currencyName,
    required this.currencyCode,
    required this.onAddFunds,
  });

  final double total;
  final String currencyName;
  final String currencyCode;
  final VoidCallback onAddFunds;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountWords = Formatters.amountInArabicWords(
      total,
      currency: currencyName,
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF0B3C49), Color(0xFF051C21)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الرصيد الكلي', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(total, symbol: 'ريال'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.shield_outlined, color: Colors.white70, size: 18),
              SizedBox(width: 6),
              Text(
                'البيانات مخزنة محليًا',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amountWords,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            'العملة: $currencyName ($currencyCode)',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
              onPressed: onAddFunds,
              icon: const Icon(Icons.add_card),
              label: const Text('شحن محفظة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingChart extends StatelessWidget {
  const _SpendingChart({required this.data});

  final Map<String, double> data;

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text('سجل مصاريفك لتظهر التحليلات.')),
      );
    }

    final colors = [
      Colors.teal.shade400,
      Colors.orange.shade400,
      Colors.blue.shade400,
      Colors.purple.shade400,
      Colors.green.shade400,
    ];

    int index = 0;
    final sections = data.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: entry.key,
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الصرف حسب الفئات'),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(sectionsSpace: 2, sections: sections)),
          ),
        ],
      ),
    );
  }
}

class _InsightsList extends StatelessWidget {
  const _InsightsList({required this.insights});

  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: AppColors.secondary),
              SizedBox(width: 8),
              Text('نصائح ذكية'),
            ],
          ),
          const SizedBox(height: 12),
          if (insights.isEmpty)
            const Text('نقوم بالتحليل تلقائيًا بعد إضافة أول عملية.')
          else
            ...insights.map(
              (tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
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

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.transactions});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('لا توجد عمليات حتى الآن.'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('أحدث العمليات'),
          const SizedBox(height: 12),
          ...transactions.map(
            (txn) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: txn.type == TransactionType.income
                    ? AppColors.success.withAlpha((0.2 * 255).round())
                    : AppColors.danger.withAlpha((0.2 * 255).round()),
                child: Icon(
                  txn.type == TransactionType.income
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: txn.type == TransactionType.income
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
              title: Text(Formatters.currency(txn.amount, symbol: 'ريال')),
              subtitle: Text(Formatters.shortDate(txn.date)),
              trailing: Text(
                txn.type == TransactionType.income
                    ? '+${txn.amount}'
                    : '-${txn.amount}',
                style: TextStyle(
                  color: txn.type == TransactionType.income
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

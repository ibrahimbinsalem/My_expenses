import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction_model.dart';
import '../../../routes/app_routes.dart';
import '../../goals/controllers/goals_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../../notifications/controllers/notifications_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notificationsController = Get.find<NotificationsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('مصاريفي الذكي'.tr),
        actions: [
          Obx(() {
            final unreadCount = notificationsController.notifications
                .where((notification) => !notification.isRead)
                .length;
            return IconButton(
              tooltip: 'notifications.center.title'.tr,
              onPressed: () {
                Get.toNamed(
                  AppRoutes.notifications,
                )?.then((_) => notificationsController.fetchNotifications());
              },
              icon: Badge(
                backgroundColor: AppColors.accent,
                isLabelVisible: unreadCount > 0,
                label: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                child: const Icon(Icons.notifications_none_outlined),
              ),
            );
          }),
        ],
      ),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: controller.loadDashboard,
          child: controller.isLoading.value &&
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
                      _WalletBalancesCarousel(
                        summaries: controller.walletSummaries.toList(),
                        isHidden: controller.isBalanceHidden.value,
                        onToggleVisibility: controller.toggleBalanceVisibility,
                        onAddFunds: () => controller.openAddFundsSheet(context),
                        onAddWallet: () => Get.toNamed(AppRoutes.wallets),
                      ),
                      const SizedBox(height: 16),
                      if (controller.walletSummaries.isNotEmpty) ...[
                        _WalletsOverview(
                          summaries: controller.walletSummaries.toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const _GoalsSummaryCard(),
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
      floatingActionButton: _QuickActionsFab(controller: controller),
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
                  label: item.labelKey.tr,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _WalletBalancesCarousel extends StatefulWidget {
  const _WalletBalancesCarousel({
    required this.summaries,
    required this.isHidden,
    required this.onToggleVisibility,
    required this.onAddFunds,
    required this.onAddWallet,
  });

  final List<WalletSummary> summaries;
  final bool isHidden;
  final VoidCallback onToggleVisibility;
  final VoidCallback onAddFunds;
  final VoidCallback onAddWallet;

  @override
  State<_WalletBalancesCarousel> createState() =>
      _WalletBalancesCarouselState();
}

class _WalletBalancesCarouselState extends State<_WalletBalancesCarousel> {
  late final PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
    _pageController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _WalletBalancesCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summaries.length != widget.summaries.length) {
      final maxValidPage = (widget.summaries.length - 1)
          .clamp(0, double.infinity)
          .toInt();
      if (_currentPage > maxValidPage) {
        _pageController.jumpToPage(maxValidPage);
      }
    }
  }

  void _onScroll() {
    if (!mounted) return;
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.summaries.isEmpty) {
      return _EmptyWalletsCard(onAddWallet: widget.onAddWallet);
    }

    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: _pageController,
        reverse: true,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.summaries.length,
        itemBuilder: (context, index) {
          final summary = widget.summaries[index];
          final isFocused = (_currentPage.round() == index);
          return AnimatedScale(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            scale: isFocused ? 1 : 0.95,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isFocused ? 1 : 0.8,
              child: _WalletBalanceCard(
                summary: summary,
                isHidden: widget.isHidden,
                onToggleVisibility: widget.onToggleVisibility,
                onAddFunds: widget.onAddFunds,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionsFab extends StatelessWidget {
  const _QuickActionsFab({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOpen = controller.isQuickFabOpen.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _QuickActionButton(
            isVisible: isOpen,
            label: 'dashboard.quick.bill'.tr,
            icon: Icons.receipt_long,
            color: Colors.deepPurple,
            onTap: () {
              controller.toggleQuickFab();
              controller.openBillBook();
            },
          ),
          _QuickActionButton(
            isVisible: isOpen,
            label: 'dashboard.quick.transaction'.tr,
            icon: Icons.add_card,
            color: Colors.teal,
            onTap: () {
              controller.toggleQuickFab();
              controller.openAddTransaction();
            },
          ),
          _QuickActionButton(
            isVisible: isOpen,
            label: 'dashboard.quick.note'.tr,
            icon: Icons.sticky_note_2_outlined,
            color: Colors.orange,
            onTap: () {
              controller.toggleQuickFab();
              controller.openQuickNoteSheet(context);
            },
          ),
          _QuickActionButton(
            isVisible: isOpen,
            label: 'dashboard.quick.tasks'.tr,
            icon: Icons.repeat_on,
            color: Colors.indigo,
            onTap: () {
              controller.toggleQuickFab();
              controller.openTasks();
            },
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: controller.toggleQuickFab,
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: isOpen ? 0.125 : 0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isOpen ? 0.9 : 1,
                child: Icon(isOpen ? Icons.close : Icons.add),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.isVisible,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final bool isVisible;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const offset = Offset(-0.1, 0.2);
    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      offset: isVisible ? Offset.zero : offset,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1 : 0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: isVisible ? 1 : 0.8,
          child: IgnorePointer(
            ignoring: !isVisible,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuickActionLabel(
                    text: label,
                    alignment: AlignmentDirectional.centerStart,
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: '$label-${icon.codePoint}',
                    backgroundColor: color,
                    onPressed: onTap,
                    child: Icon(icon, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionLabel extends StatelessWidget {
  const _QuickActionLabel({required this.text, required this.alignment});

  final String text;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          textAlign:
              alignment == AlignmentDirectional.centerStart
                  ? TextAlign.left
                  : TextAlign.right,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({
    required this.summary,
    required this.isHidden,
    required this.onToggleVisibility,
    required this.onAddFunds,
  });

  final WalletSummary summary;
  final bool isHidden;
  final VoidCallback onToggleVisibility;
  final VoidCallback onAddFunds;

  @override
  Widget build(BuildContext context) {
    final wallet = summary.wallet;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0B3C49), Color(0xFF051C21)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : AppColors.heroGradient;
    final amountText = isHidden
        ? '••••••'
        : Formatters.currency(wallet.balance, symbol: wallet.currency);
    final amountWords = isHidden
        ? 'الرصيد مخفي'.tr
        : Formatters.amountInArabicWords(
            wallet.balance,
            currency: summary.currencyName,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showTransactionsSheet(context),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: constraints.maxHeight.isFinite
                    ? const BouncingScrollPhysics()
                    : null,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                                  wallet.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  summary.currencyName,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: onToggleVisibility,
                            icon: Icon(
                              isHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        amountText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'البيانات مخزنة محليًا'.tr,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        amountWords,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'العملة: @name (@code)'.trParams({
                          'name': summary.currencyName,
                          'code': summary.wallet.currency,
                        }),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          onPressed: onAddFunds,
                          icon: const Icon(Icons.add_card),
                          label: Text('شحن محفظة'.tr),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTransactionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _WalletTransactionsSheet(summary: summary),
    );
  }
}

class _EmptyWalletsCard extends StatelessWidget {
  const _EmptyWalletsCard({required this.onAddWallet});

  final VoidCallback onAddWallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'لا توجد محافظ'.tr,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإضافة محفظة جديدة لعرض أرصدة العملات المختلفة.'.tr,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            ),
            onPressed: onAddWallet,
            icon: const Icon(Icons.wallet),
            label: Text('إضافة محفظة'.tr),
          ),
        ],
      ),
    );
  }
}

class _WalletsOverview extends StatelessWidget {
  const _WalletsOverview({required this.summaries});

  final List<WalletSummary> summaries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ملخص المحافظ'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...summaries.map(
          (summary) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _WalletSummaryCard(summary: summary),
          ),
        ),
      ],
    );
  }
}

class _GoalsSummaryCard extends StatelessWidget {
  const _GoalsSummaryCard();

  @override
  Widget build(BuildContext context) {
    final goalsController = Get.find<GoalsController>();
    return Obx(
      () {
        final goals = goalsController.goals.toList();
        final theme = Theme.of(context);
        if (goals.isEmpty) {
          return _EmptyStateCard(
            icon: Icons.flag_outlined,
            title: 'dashboard.goals.title'.tr,
            description: 'dashboard.goals.empty'.tr,
            actionLabel: 'dashboard.goals.cta'.tr,
            onAction: () => Get.toNamed(AppRoutes.goals),
          );
        }
        goals.sort(
          (a, b) => a.deadline.compareTo(b.deadline),
        );
        final goal = goals.first;
        final progress = goal.progress;
        final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);
        final remainingAmount =
            goal.targetAmount - goal.currentAmount <= 0 ? 0 : goal.targetAmount - goal.currentAmount;
        final remainingLabel = Formatters.currency(
          remainingAmount,
          symbol: 'ريال',
        );
        final formattedCurrent =
            Formatters.currency(goal.currentAmount, symbol: 'ريال');
        final formattedTarget =
            Formatters.currency(goal.targetAmount, symbol: 'ريال');
        final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
        final deadlineLabel = daysLeft >= 0
            ? 'dashboard.goals.deadline'
                .trParams({'days': daysLeft.toString()})
            : 'dashboard.goals.deadline_overdue'
                .trParams({'days': (-daysLeft).toString()});

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'dashboard.goals.title'.tr,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'dashboard.goals.subtitle'.tr,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.goals),
                    child: Text('dashboard.goals.cta'.tr),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                goal.name,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: progress,
                  backgroundColor:
                      theme.colorScheme.primary.withOpacity(0.12),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'dashboard.goals.progress'.trParams({'percent': percent}),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    deadlineLabel,
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'dashboard.goals.remaining'.trParams(
                  {'amount': remainingLabel},
                ),
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              Text(
                'dashboard.goals.summary'.trParams({
                  'current': formattedCurrent,
                  'target': formattedTarget,
                }),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade700),
              ),
            ],
          ),
        );
      },
    );
  }
}
class _WalletSummaryCard extends StatelessWidget {
  const _WalletSummaryCard({required this.summary});

  final WalletSummary summary;

  IconData _walletIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance;
      case 'digital':
        return Icons.wallet;
      default:
        return Icons.savings;
    }
  }

  Color _walletAccent(String type, ThemeData theme) {
    switch (type) {
      case 'bank':
        return AppColors.primary;
      case 'digital':
        return AppColors.secondary;
      default:
        return AppColors.accent;
    }
  }

  String _walletTypeLabel(String type) {
    switch (type) {
      case 'bank':
        return 'wallet.type.bank';
      case 'digital':
        return 'wallet.type.digital';
      default:
        return 'wallet.type.cash';
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = summary.wallet;
    final theme = Theme.of(context);
    final accent = _walletAccent(wallet.type, theme);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showTransactionsSheet(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: accent.withOpacity(0.15),
                    foregroundColor: accent,
                    child: Icon(_walletIcon(wallet.type)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _walletTypeLabel(wallet.type).tr,
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text('${summary.currencyName} (${wallet.currency})'),
                    backgroundColor: accent.withOpacity(0.15),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary.transactions.isEmpty
                    ? 'لا يوجد عمليات بعد لهذه المحفظة.'.tr
                    : 'انقر على البطاقة لعرض العمليات الأخيرة.'.tr,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _WalletTransactionsSheet(summary: summary),
    );
  }
}

class _WalletTransactionRow extends StatelessWidget {
  const _WalletTransactionRow({
    required this.transaction,
    required this.currency,
  });

  final TransactionModel transaction;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final visual = _visualForType(transaction.type);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _presentTransactionDetails(context, transaction, currency),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: visual.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                visual.icon,
                color: visual.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.note ?? 'عملية بدون ملاحظة'.tr),
                  Text(
                    Formatters.shortDate(transaction.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              Formatters.currency(
                transaction.amount,
                symbol: currency,
                sign: visual.prefix,
              ),
              style: TextStyle(
                color: visual.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletTransactionsSheet extends StatelessWidget {
  const _WalletTransactionsSheet({required this.summary});

  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final wallet = summary.wallet;
    final incomeTransactions = summary.transactions
        .where((txn) => txn.type == TransactionType.income)
        .toList();
    final expenseTransactions = summary.transactions
        .where((txn) => txn.type == TransactionType.expense)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Text(
            'سجل عمليات @name'.trParams({'name': wallet.name}),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (summary.transactions.isEmpty)
            Padding(
              padding: EdgeInsets.all(24),
              child: Text('لا يوجد عمليات بعد لهذه المحفظة.'.tr),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (incomeTransactions.isNotEmpty)
                    _TransactionSection(
                      title: 'عمليات الإيداع'.tr,
                      icon: Icons.trending_up,
                      color: AppColors.success,
                      transactions: incomeTransactions,
                      currency: wallet.currency,
                    ),
                  if (expenseTransactions.isNotEmpty)
                    _TransactionSection(
                      title: 'عمليات الخصم'.tr,
                      icon: Icons.trending_down,
                      color: AppColors.danger,
                      transactions: expenseTransactions,
                      currency: wallet.currency,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionSection extends StatelessWidget {
  const _TransactionSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.transactions,
    required this.currency,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<TransactionModel> transactions;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  foregroundColor: color,
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'common.operations_count'.trParams({
                    'count': transactions.length.toString(),
                  }),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(transactions.length, (index) {
              final txn = transactions[index];
              return Column(
                children: [
                  _WalletTransactionRow(transaction: txn, currency: currency),
                  if (index != transactions.length - 1)
                    const Divider(height: 12),
                ],
              );
            }),
          ],
        ),
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
        child: Center(child: Text('سجل مصاريفك لتظهر التحليلات.'.tr)),
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
          Text('الصرف حسب الفئات'.tr),
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
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text('نصائح ذكية'.tr),
            ],
          ),
          const SizedBox(height: 12),
          if (insights.isEmpty)
            Text('نقوم بالتحليل تلقائيًا بعد إضافة أول عملية.'.tr)
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
        child: Text('لا توجد عمليات حتى الآن.'.tr),
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
          Text('أحدث العمليات'.tr),
          const SizedBox(height: 12),
          ...transactions.map((txn) {
            final visual = _visualForType(txn.type);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor:
                    visual.color.withAlpha((0.2 * 255).round()),
                child: Icon(
                  visual.icon,
                  color: visual.color,
                ),
              ),
              title: Text(
                Formatters.currency(
                  txn.amount,
                  symbol: 'ريال'.tr,
                  sign: visual.prefix,
                ),
              ),
              subtitle: Text(Formatters.shortDate(txn.date)),
              trailing: Icon(
                Icons.chevron_left,
                color: Theme.of(context).iconTheme.color,
              ),
              onTap: () => _presentTransactionDetails(
                context,
                txn,
                'ريال'.tr,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.cardColor,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style:
                theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

void _presentTransactionDetails(
  BuildContext context,
  TransactionModel transaction,
  String currencySymbol,
) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'common.cancel'.tr,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      );
      return Opacity(
        opacity: animation.value,
        child: Transform.scale(
          scale: curved.value,
          child: _TransactionDetailsDialog(
            transaction: transaction,
            currencySymbol: currencySymbol,
          ),
        ),
      );
    },
  );
}

class _TransactionDetailsDialog extends StatelessWidget {
  const _TransactionDetailsDialog({
    required this.transaction,
    required this.currencySymbol,
  });

  final TransactionModel transaction;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = _visualForType(transaction.type);
    final amountColor = visual.color;
    final localeCode = Get.locale?.languageCode ?? 'ar';
    final dateFormatter = DateFormat.yMMMMd(localeCode);
    final timeFormatter = DateFormat.jm(localeCode);
    final dateText =
        '${dateFormatter.format(transaction.date)} • ${timeFormatter.format(transaction.date)}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'transaction.details.title'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Formatters.currency(
                      transaction.amount,
                      symbol: currencySymbol,
                      sign: visual.prefix,
                    ),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(_transactionTypeLabel(transaction.type)),
                    backgroundColor: amountColor.withOpacity(0.1),
                    labelStyle: TextStyle(color: amountColor),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'التاريخ'.tr, value: dateText),
                  const SizedBox(height: 10),
                  _DetailRow(
                    label: 'النوع'.tr,
                    value: _transactionTypeLabel(transaction.type),
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    label: 'ملاحظة'.tr,
                    value: transaction.note?.isNotEmpty == true
                        ? transaction.note!
                        : 'عملية بدون ملاحظة'.tr,
                  ),
                  if (transaction.imagePath != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      'transaction.receipt_section'.tr,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: Text('transaction.view_receipt'.tr),
                      onPressed: () async {
                        await OpenFilex.open(transaction.imagePath!);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _transactionTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'transaction.type.income'.tr;
      case TransactionType.expense:
        return 'transaction.type.expense'.tr;
      case TransactionType.saving:
        return 'transaction.type.saving'.tr;
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(value, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}

class _TransactionVisual {
  const _TransactionVisual({
    required this.color,
    required this.icon,
    required this.prefix,
  });

  final Color color;
  final IconData icon;
  final String prefix;
}

_TransactionVisual _visualForType(TransactionType type) {
  switch (type) {
    case TransactionType.income:
      return const _TransactionVisual(
        color: AppColors.success,
        icon: Icons.arrow_downward,
        prefix: '+',
      );
    case TransactionType.expense:
      return const _TransactionVisual(
        color: AppColors.danger,
        icon: Icons.arrow_upward,
        prefix: '-',
      );
    case TransactionType.saving:
      return const _TransactionVisual(
        color: AppColors.secondary,
        icon: Icons.savings_outlined,
        prefix: '',
      );
  }
}

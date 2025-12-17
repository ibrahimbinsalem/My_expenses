import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../controllers/goals_controller.dart';
import '../../../data/models/goal_model.dart';
import '../widgets/goal_contribution_sheet.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/currency_picker_field.dart';

class GoalsView extends GetView<GoalsController> {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الأهداف المالية'.tr),
        actions: [
          IconButton(
            tooltip: 'goals.guide.button'.tr,
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showGoalsGuide(context),
          ),
        ],
      ),
      body: Obx(() {
        final allGoals = controller.goals.toList();
        allGoals.sort((a, b) => a.deadline.compareTo(b.deadline));
        final activeGoals =
            allGoals.where((goal) => goal.walletId == null).toList();
        final archivedGoals =
            allGoals.where((goal) => goal.walletId != null).toList();
        final totalTarget = activeGoals.fold<double>(
          0.0,
          (sum, goal) => sum + goal.targetAmount,
        );
        final totalCurrent = activeGoals.fold<double>(
          0.0,
          (sum, goal) => sum + goal.currentAmount,
        );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            
            _GoalForm(controller: controller),
            const SizedBox(height: 20),
            if (controller.isLoading.value && activeGoals.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (activeGoals.isEmpty)
              _EmptyGoalsState(onAddTransaction: () {
                Get.toNamed(AppRoutes.addTransaction);
              })
            else
              ...activeGoals.map((goal) {
                final dueDate =
                    '${goal.deadline.day}/${goal.deadline.month}/${goal.deadline.year}';
                final payoutWallet = controller.walletForId(goal.walletId);
                final isCompleted = goal.isCompleted;
                final currencyLabel = goal.currency ??
                    payoutWallet?.currency ??
                    '—';
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: goal.id == null
                        ? null
                        : () => Get.toNamed(
                              AppRoutes.goalDetails,
                              arguments: goal.id,
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
                                goal.name,
                                style:
                                    Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Chip(
                              label: Text(
                                goal.isCompleted
                                    ? 'goals.status.completed'.tr
                                    : 'goals.status.in_progress'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: goal.isCompleted
                                  ? AppColors.success.withOpacity(0.15)
                                  : AppColors.secondary.withOpacity(0.15),
                              labelStyle: TextStyle(
                                color: goal.isCompleted
                                    ? AppColors.success
                                    : AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: goal.progress,
                          backgroundColor: Colors.grey.shade200,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'المستهدف: @target • الحالي: @current'.trParams({
                            'target': goal.targetAmount.toStringAsFixed(1),
                            'current': goal.currentAmount.toStringAsFixed(1),
                          }),
                        ),
                        Text('الموعد: @date'.trParams({'date': dueDate})),
                        const SizedBox(height: 4),
                        Text(
                          payoutWallet == null
                              ? 'goals.wallet.pending'.tr
                              : 'goals.wallet.created'
                                  .trParams({'name': payoutWallet.name}),
                        ),
                        Text('goals.card.currency'.trParams({
                          'code': currencyLabel,
                        })),
                        const SizedBox(height: 12),
                        if (goal.id != null)
                          SizedBox(
                            width: double.infinity,
                            child: isCompleted
                                ? OutlinedButton.icon(
                                    onPressed: () =>
                                        Get.toNamed(AppRoutes.goalDetails,
                                            arguments: goal.id),
                                    icon: const Icon(Icons.swap_horiz),
                                    label: Text('goals.transfer.button'.tr),
                                  )
                                : FilledButton.icon(
                                    onPressed: () =>
                                        showGoalContributionSheet(
                                      context: context,
                                      controller: controller,
                                      goal: goal,
                                    ),
                                    icon:
                                        const Icon(Icons.savings_outlined),
                                    label: Text(
                                        'goals.contribution.add'.tr),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ));
              }),
            if (archivedGoals.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ArchivedGoalsSection(goals: archivedGoals),
            ],
          ],
        );
      }),
    );
  }
}

class _GoalForm extends StatelessWidget {
  const _GoalForm({required this.controller});

  final GoalsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF143C54), Color(0xFF0D1F2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'هدف جديد'.tr,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    Text(
                      'ضع اسمًا ومبلغًا واضحين وعرّف عملة الادخار.'.tr,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.nameController,
            decoration: InputDecoration(
              labelText: 'اسم الهدف'.tr,
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              labelStyle: const TextStyle(color: Colors.white),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: controller.amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'المبلغ المستهدف'.tr,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: CurrencyPickerField(
                    controller: controller.currencyController,
                    label: 'goals.form.currency_label',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Obx(
              () => Row(
                children: [
                  Expanded(
                    child: Text(
                      'التاريخ: @date'.trParams({
                        'date':
                            '${controller.deadline.value.day}/${controller.deadline.value.month}/${controller.deadline.value.year}',
                      }),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.date_range, color: Colors.white),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.deadline.value,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(DateTime.now().year + 5),
                      );
                      if (picked != null) {
                        controller.deadline.value = picked;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: controller.createGoal,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                'إضافة الهدف'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedGoalsSection extends StatelessWidget {
  const _ArchivedGoalsSection({required this.goals});

  final List<GoalModel> goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        title: Text('goals.archived.title'.tr),
        subtitle: Text(
          'goals.archived.subtitle'.trParams({
            'count': goals.length.toString(),
          }),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        children: goals.map((goal) {
          final formattedAmount =
              Formatters.currency(goal.currentAmount, symbol: goal.currency);
          return ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: Text(goal.name),
            subtitle: Text(
              'goals.archived.amount'.trParams({
                'amount': formattedAmount,
                'date': Formatters.shortDate(goal.deadline),
              }),
            ),
            trailing: TextButton(
              onPressed: () => Get.toNamed(
                AppRoutes.goalDetails,
                arguments: goal.id,
              ),
              child: Text('goals.archived.view'.tr),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GoalsOverview extends StatelessWidget {
  const _GoalsOverview({
    required this.totalTarget,
    required this.totalCurrent,
    required this.controller,
  });

  final double totalTarget;
  final double totalCurrent;
  final GoalsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completion = totalTarget == 0
        ? 0.0
        : (totalCurrent / totalTarget).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'goals.overview.title'.tr,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              totalTarget == 0
                  ? 'goals.overview.empty'.tr
                  : 'goals.overview.summary'.trParams({
                      'current': totalCurrent.toStringAsFixed(1),
                      'target': totalTarget.toStringAsFixed(1),
                    }),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: completion,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.secondary,
              minHeight: 12,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.account_balance_wallet_outlined),
                  label: Text('goals.quick.wallets'.tr),
                  onPressed: () => Get.toNamed(AppRoutes.wallets),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add_circle_outline),
                  label: Text('goals.quick.transaction'.tr),
                  onPressed: () => Get.toNamed(AppRoutes.addTransaction),
                ),
                ActionChip(
                  avatar: const Icon(Icons.alarm),
                  label: Text('goals.quick.reminder'.tr),
                  onPressed: () => Get.toNamed(AppRoutes.remindersSettings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGoalsState extends StatelessWidget {
  const _EmptyGoalsState({required this.onAddTransaction});

  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
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
          const Icon(Icons.flag_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            'goals.empty.title'.tr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'goals.empty.subtitle'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAddTransaction,
            icon: const Icon(Icons.trending_up_outlined),
            label: Text('goals.empty.action'.tr),
          ),
        ],
      ),
    );
  }
}

void _showGoalsGuide(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'goals.guide.title'.tr,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...List.generate(4, (index) {
              final step = 'goals.guide.step${index + 1}'.tr;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(child: Text(step)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.dashboard),
                icon: const Icon(Icons.dashboard_outlined),
                label: Text('goals.guide.cta'.tr),
              ),
            ),
          ],
        ),
      );
    },
  );
}

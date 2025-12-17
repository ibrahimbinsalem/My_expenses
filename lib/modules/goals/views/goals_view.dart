import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../controllers/goals_controller.dart';
import '../../../data/models/goal_model.dart';

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
        final goals = controller.goals;
        final totalTarget = goals.fold<double>(
          0.0,
          (sum, goal) => sum + goal.targetAmount,
        );
        final totalCurrent = goals.fold<double>(
          0.0,
          (sum, goal) => sum + goal.currentAmount,
        );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _GoalsOverview(
              totalTarget: totalTarget,
              totalCurrent: totalCurrent,
              controller: controller,
            ),
            const SizedBox(height: 20),
            _GoalForm(controller: controller),
            const SizedBox(height: 20),
            if (controller.isLoading.value && goals.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (goals.isEmpty)
              _EmptyGoalsState(onAddTransaction: () {
                Get.toNamed(AppRoutes.addTransaction);
              })
            else
              ...goals.map((goal) {
                final dueDate =
                    '${goal.deadline.day}/${goal.deadline.month}/${goal.deadline.year}';
                final payoutWallet = controller.walletForId(goal.walletId);
                final currencyLabel = goal.currency ??
                    payoutWallet?.currency ??
                    '—';
                return Card(
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
                                goal.progress >= 1
                                    ? 'goals.status.completed'.tr
                                    : 'goals.status.in_progress'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: goal.progress >= 1
                                  ? AppColors.success.withOpacity(0.15)
                                  : AppColors.secondary.withOpacity(0.15),
                              labelStyle: TextStyle(
                                color: goal.progress >= 1
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
                          FilledButton.icon(
                            onPressed: () => _showContributionSheet(
                              context,
                              controller,
                              goal,
                            ),
                            icon: const Icon(Icons.savings_outlined),
                            label: Text('goals.contribution.add'.tr),
                          ),
                      ],
                    ),
                  ),
                );
              }),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هدف جديد'.tr),
            const SizedBox(height: 12),
            TextField(
              controller: controller.nameController,
              decoration: InputDecoration(labelText: 'اسم الهدف'.tr),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'المبلغ المستهدف'.tr),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: Text(
                      'التاريخ: @date'.trParams({
                        'date':
                            '${controller.deadline.value.day}/${controller.deadline.value.month}/${controller.deadline.value.year}',
                      }),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.date_range),
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
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: controller.createGoal,
              child: Text('إضافة الهدف'.tr),
            ),
          ],
        ),
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

void _showContributionSheet(
  BuildContext context,
  GoalsController controller,
  GoalModel goal,
) {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
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
            Text(
              'goals.contribution.add'.tr,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'goals.contribution.amount_label'.tr,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'goals.contribution.note_label'.tr,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final parsed = double.tryParse(amountController.text);
                  if (parsed == null || parsed <= 0) {
                    Get.snackbar(
                      'common.alert'.tr,
                      'goals.contribution.invalid'.tr,
                    );
                    return;
                  }
                  await controller.addContribution(
                    goal,
                    parsed,
                    note: noteController.text,
                  );
                  Get.back();
                  Get.snackbar(
                    'common.success'.tr,
                    'goals.contribution.success'.tr,
                  );
                },
                child: Text('goals.contribution.submit'.tr),
              ),
            ),
          ],
        ),
      );
    },
  );
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

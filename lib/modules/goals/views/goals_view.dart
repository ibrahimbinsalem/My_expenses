import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/goals_controller.dart';

class GoalsView extends GetView<GoalsController> {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الأهداف المالية'.tr)),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _GoalForm(controller: controller),
            const SizedBox(height: 20),
            if (controller.isLoading.value && controller.goals.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              ...controller.goals.map((goal) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: Theme.of(context).textTheme.titleLarge,
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
                        Text(
                          'الموعد: @date'.trParams({
                            'date':
                                '${goal.deadline.day}/${goal.deadline.month}/${goal.deadline.year}',
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
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

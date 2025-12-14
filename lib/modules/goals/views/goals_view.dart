import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/goals_controller.dart';

class GoalsView extends GetView<GoalsController> {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأهداف المالية')),
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
                          'المستهدف: ${goal.targetAmount} • الحالي: ${goal.currentAmount.toStringAsFixed(1)}',
                        ),
                        Text(
                          'الموعد: ${goal.deadline.day}/${goal.deadline.month}/${goal.deadline.year}',
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
            const Text('هدف جديد'),
            const SizedBox(height: 12),
            TextField(
              controller: controller.nameController,
              decoration: const InputDecoration(labelText: 'اسم الهدف'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ المستهدف'),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: Text(
                      'التاريخ: ${controller.deadline.value.day}/${controller.deadline.value.month}/${controller.deadline.value.year}',
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
              child: const Text('إضافة الهدف'),
            ),
          ],
        ),
      ),
    );
  }
}

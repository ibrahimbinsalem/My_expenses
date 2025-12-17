import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/goal_model.dart';
import '../controllers/goals_controller.dart';
import '../../../routes/app_routes.dart';

Future<void> showGoalContributionSheet({
  required BuildContext context,
  required GoalsController controller,
  required GoalModel goal,
  VoidCallback? onCompleted,
}) async {
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  await showModalBottomSheet(
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
                  final completed = await controller.addContribution(
                    goal,
                    parsed,
                    note: noteController.text,
                  );
                  Get.back();
                  if (completed) {
                    Get.toNamed(
                      AppRoutes.goalCelebration,
                      arguments: {
                        'goalId': goal.id,
                        'goalName': goal.name,
                        'targetAmount': goal.targetAmount,
                        'currency': goal.currency,
                      },
                    );
                  } else {
                    Get.snackbar(
                      'common.success'.tr,
                      'goals.contribution.success'.tr,
                    );
                  }
                  onCompleted?.call();
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

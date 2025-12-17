import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/goal_model.dart';
import '../../../data/models/wallet_model.dart';
import '../controllers/goals_controller.dart';

Future<void> showGoalTransferSheet({
  required BuildContext context,
  required GoalsController controller,
  required GoalModel goal,
  VoidCallback? onSuccess,
}) async {
  final wallets = controller.allWallets
      .where((wallet) => !wallet.isGoal)
      .toList();
  if (wallets.isEmpty) {
    Get.snackbar('common.alert'.tr, 'goals.transfer.no_wallets'.tr);
    return;
  }
  WalletModel? selectedWallet = wallets.first;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
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
                  'goals.transfer.title'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'goals.transfer.subtitle'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: wallets.length > 3 ? 260 : wallets.length * 72.0,
                  child: ListView.builder(
                    itemCount: wallets.length,
                    itemBuilder: (context, index) {
                      final wallet = wallets[index];
                      return RadioListTile<WalletModel>(
                        value: wallet,
                        groupValue: selectedWallet,
                        onChanged: (value) {
                          setState(() {
                            selectedWallet = value;
                          });
                        },
                        title: Text(wallet.name),
                        subtitle: Text(
                          'goals.transfer.wallet_balance'.trParams({
                            'amount': wallet.balance.toStringAsFixed(2),
                            'currency': wallet.currency,
                          }),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selectedWallet == null
                        ? null
                        : () async {
                            final wallet = selectedWallet!;
                            final success = await controller
                                .transferGoalToWallet(goal, wallet);
                            if (success) {
                              Get.back();
                              Get.snackbar('common.success'.tr,
                                  'goals.transfer.success'.tr);
                              onSuccess?.call();
                            } else {
                              Get.snackbar('common.alert'.tr,
                                  'goals.transfer.error'.tr);
                            }
                          },
                    child: Text('goals.transfer.confirm'.tr),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

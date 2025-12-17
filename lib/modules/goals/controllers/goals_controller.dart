import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/goal_model.dart';
import '../../../data/models/goal_contribution_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/local_expense_repository.dart';

class GoalsController extends GetxController {
  GoalsController(this._repository);

  final LocalExpenseRepository _repository;

  final goals = <GoalModel>[].obs;
  final allWallets = <WalletModel>[].obs;
  final isLoading = false.obs;

  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final deadline = DateTime.now().add(const Duration(days: 30)).obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      fetchWallets(),
      fetchGoals(),
    ]);
  }

  Future<void> fetchGoals() async {
    isLoading.value = true;
    try {
      goals.assignAll(await _repository.fetchGoals());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchWallets() async {
    final loaded = await _repository.fetchWallets(includeGoal: true);
    allWallets.assignAll(loaded);
  }

  WalletModel? walletForId(int? id) {
    if (id == null) return null;
    return allWallets.firstWhereOrNull((wallet) => wallet.id == id);
  }

  Future<void> createGoal() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('common.alert'.tr, 'goals.form.validation.name'.tr);
      return;
    }
    final parsedAmount = double.tryParse(amountController.text);
    if (parsedAmount == null || parsedAmount <= 0) {
      Get.snackbar('common.alert'.tr, 'goals.form.validation.amount'.tr);
      return;
    }
    final referenceWallet = allWallets
        .firstWhereOrNull((wallet) => !wallet.isGoal);
    final currency = referenceWallet?.currency ?? 'SAR';
    final goal = GoalModel(
      name: nameController.text,
      targetAmount: parsedAmount,
      currentAmount: 0,
      deadline: deadline.value,
      walletId: null,
      currency: currency,
    );
    await _repository.upsertGoal(goal);
    await fetchGoals();
    await fetchWallets();
    nameController.clear();
    amountController.clear();
  }

  Future<void> addContribution(
    GoalModel goal,
    double amount, {
    String? note,
  }) async {
    if (goal.id == null || amount <= 0) {
      return;
    }
    await _repository.insertGoalContribution(
      GoalContributionModel(
        goalId: goal.id!,
        amount: amount,
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
        createdAt: DateTime.now(),
      ),
    );
    await fetchGoals();
    await fetchWallets();
  }

  Future<List<GoalContributionModel>> loadContributions(int goalId) {
    return _repository.fetchGoalContributions(goalId);
  }

  @override
  void onClose() {
    nameController.dispose();
    amountController.dispose();
    super.onClose();
  }
}

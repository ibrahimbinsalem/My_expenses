import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/goal_model.dart';
import '../../../data/repositories/local_expense_repository.dart';

class GoalsController extends GetxController {
  GoalsController(this._repository);

  final LocalExpenseRepository _repository;

  final goals = <GoalModel>[].obs;
  final isLoading = false.obs;

  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final deadline = DateTime.now().add(const Duration(days: 30)).obs;

  @override
  void onInit() {
    super.onInit();
    fetchGoals();
  }

  Future<void> fetchGoals() async {
    isLoading.value = true;
    try {
      goals.assignAll(await _repository.fetchGoals());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createGoal() async {
    if (nameController.text.isEmpty || amountController.text.isEmpty) return;
    final goal = GoalModel(
      name: nameController.text,
      targetAmount: double.tryParse(amountController.text) ?? 0,
      currentAmount: 0,
      deadline: deadline.value,
    );
    await _repository.upsertGoal(goal);
    await fetchGoals();
    nameController.clear();
    amountController.clear();
  }

  @override
  void onClose() {
    nameController.dispose();
    amountController.dispose();
    super.onClose();
  }
}

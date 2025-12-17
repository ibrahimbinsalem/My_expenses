import 'package:get/get.dart';

import '../../../data/models/recurring_task_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/repositories/local_expense_repository.dart';

class TasksController extends GetxController {
  TasksController(this._repository);

  final LocalExpenseRepository _repository;

  final tasks = <RecurringTaskModel>[].obs;
  final wallets = <WalletModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  Future<void> loadTasks() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _repository.fetchRecurringTasks(),
        _repository.fetchWallets(),
      ]);
      tasks.assignAll(results[0] as List<RecurringTaskModel>);
      wallets.assignAll(results[1] as List<WalletModel>);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addTask(RecurringTaskModel task) async {
    final id = await _repository.insertRecurringTask(task);
    if (id <= 0) return false;
    tasks.insert(0, task.copyWith(id: id));
    return true;
  }

  Future<void> deleteTask(int id) async {
    await _repository.deleteRecurringTask(id);
    tasks.removeWhere((task) => task.id == id);
  }

  Future<void> completeTask(RecurringTaskModel task) async {
    final nextDate = _calculateNextDate(task);
    final updated = task.copyWith(nextDate: nextDate);
    await _repository.updateRecurringTask(updated);
    final index = tasks.indexWhere((element) => element.id == task.id);
    if (index >= 0) {
      tasks[index] = updated;
    }
  }

  DateTime _calculateNextDate(RecurringTaskModel task) {
    switch (task.frequency) {
      case RecurringFrequency.weekly:
        return task.nextDate.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(task.nextDate.year, task.nextDate.month + 1,
            task.nextDate.day);
      case RecurringFrequency.quarterly:
        return DateTime(task.nextDate.year, task.nextDate.month + 3,
            task.nextDate.day);
      case RecurringFrequency.yearly:
        return DateTime(task.nextDate.year + 1, task.nextDate.month,
            task.nextDate.day);
    }
  }
}

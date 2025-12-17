import 'package:get/get.dart';

import '../../../data/models/notification_log_model.dart';
import '../../../data/repositories/local_expense_repository.dart';

class NotificationsController extends GetxController {
  NotificationsController(this._repository);

  final LocalExpenseRepository _repository;

  final notifications = <NotificationLogModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      notifications.assignAll(await _repository.fetchNotificationLogs());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllNotificationsAsRead();
    await fetchNotifications();
  }

  Future<void> clearAll() async {
    await _repository.clearNotificationLogs();
    notifications.clear();
  }
}

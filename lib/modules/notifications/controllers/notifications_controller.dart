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

  Future<void> markAsRead(NotificationLogModel log) async {
    if (log.id == null || log.isRead) return;
    await _repository.markNotificationAsRead(log.id!);
    final index = notifications.indexWhere((item) => item.id == log.id);
    if (index != -1) {
      notifications[index] = log.copyWith(isRead: true);
    }
  }

  Future<void> deleteNotification(NotificationLogModel log) async {
    if (log.id == null) return;
    await _repository.deleteNotification(log.id!);
    notifications.removeWhere((item) => item.id == log.id);
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

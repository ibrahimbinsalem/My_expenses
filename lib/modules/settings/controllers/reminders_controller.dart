import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../data/models/reminder_model.dart';
import '../../../data/repositories/local_expense_repository.dart';

class RemindersController extends GetxController {
  RemindersController(this._repository);

  final LocalExpenseRepository _repository;
  final NotificationService _notificationService =
      Get.find<NotificationService>();
  final SettingsService _settingsService = Get.find<SettingsService>();

  final reminders = <ReminderModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReminders();
  }

  Future<void> fetchReminders() async {
    isLoading.value = true;
    try {
      reminders.assignAll(await _repository.fetchReminders());
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addReminder({
    required String message,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return false;
    final user = await _repository.getPrimaryUser();
    final reminder = ReminderModel(
      userId: user?.id,
      message: trimmed,
      date: date,
      time: _formatTime(time),
    );
    final id = await _repository.insertReminder(reminder);
    final savedReminder = reminder.copyWith(id: id);
    if (_settingsService.notificationsEnabled) {
      await _notificationService.scheduleReminder(savedReminder);
    }
    await fetchReminders();
    return true;
  }

  Future<bool> updateReminder({
    required ReminderModel reminder,
    required String message,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    if (reminder.id == null) return false;
    final trimmed = message.trim();
    if (trimmed.isEmpty) return false;
    final updated = reminder.copyWith(
      message: trimmed,
      date: date,
      time: _formatTime(time),
    );
    await _repository.updateReminder(updated);
    await _notificationService.cancelReminder(updated.id!);
    if (_settingsService.notificationsEnabled) {
      await _notificationService.scheduleReminder(updated);
    }
    await fetchReminders();
    return true;
  }

  Future<void> deleteReminder(ReminderModel reminder) async {
    if (reminder.id == null) return;
    await _notificationService.cancelReminder(reminder.id!);
    await _repository.deleteReminder(reminder.id!);
    await fetchReminders();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

}

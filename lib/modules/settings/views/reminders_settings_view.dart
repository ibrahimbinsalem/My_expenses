import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/reminder_model.dart';
import '../controllers/reminders_controller.dart';

class RemindersSettingsView extends GetView<RemindersController> {
  const RemindersSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings.reminders.manage_title'.tr)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReminderSheet(context, controller),
        icon: const Icon(Icons.add_alert),
        label: Text('settings.reminders.add'.tr),
      ),
      body: Obx(
        () {
          if (controller.isLoading.value && controller.reminders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.reminders.isEmpty) {
            return Center(
              child: Text(
                'settings.reminders.empty'.tr,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.reminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final reminder = controller.reminders[index];
              final formattedDate = DateFormat.yMMMEd().format(reminder.date);
              return Card(
                child: ListTile(
                  title: Text(reminder.message),
                  subtitle: Text(
                    'settings.reminders.entry'
                        .trParams({'date': formattedDate, 'time': reminder.time}),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openReminderSheet(
                          context,
                          controller,
                          reminder: reminder,
                        );
                      } else if (value == 'delete') {
                        _confirmDelete(reminder);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('settings.reminders.edit'.tr),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('settings.reminders.delete'.tr),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(ReminderModel reminder) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('settings.reminders.delete'.tr),
        content: Text('settings.reminders.delete_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('common.cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text('common.ok'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteReminder(reminder);
    }
  }
}

Future<void> _openReminderSheet(
  BuildContext context,
  RemindersController controller, {
  ReminderModel? reminder,
}) async {
  var message = reminder?.message ?? '';
  var selectedDate = reminder?.date ?? DateTime.now();
  var selectedTime = reminder != null
      ? _parseTime(reminder.time)
      : const TimeOfDay(hour: 8, minute: 0);

  if (!context.mounted) return;
  final navigator = Navigator.of(context);
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(
                    reminder == null
                        ? 'settings.reminders.add'.tr
                        : 'settings.reminders.edit'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: message,
                    decoration: InputDecoration(
                      labelText: 'settings.reminders.message_label'.tr,
                    ),
                    onChanged: (value) => message = value,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(DateFormat.yMMMMd().format(selectedDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: Text(
                      selectedTime.format(context),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) setState(() => selectedTime = picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('common.cancel'.tr),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final success = reminder == null
                                ? await controller.addReminder(
                                    message: message,
                                    date: selectedDate,
                                    time: selectedTime,
                                  )
                                : await controller.updateReminder(
                                    reminder: reminder,
                                    message: message,
                                    date: selectedDate,
                                    time: selectedTime,
                                  );
                            if (success) {
                              navigator.pop();
                              Get.snackbar(
                                'common.success'.tr,
                                'settings.reminders.saved'.tr,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            } else {
                              Get.snackbar(
                                'common.alert'.tr,
                                'settings.reminders.validation'.tr,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                          child: Text('common.save'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return const TimeOfDay(hour: 8, minute: 0);
  final hour = int.tryParse(parts[0]) ?? 8;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hour, minute: minute);
}

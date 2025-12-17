import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('notifications.center.title'.tr),
        actions: [
          IconButton(
            tooltip: 'notifications.center.mark_read'.tr,
            onPressed: controller.markAllAsRead,
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            tooltip: 'notifications.center.clear'.tr,
            onPressed: controller.clearAll,
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: Obx(
        () {
          if (controller.isLoading.value && controller.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.notifications.isEmpty) {
            return Center(
              child: Text(
                'notifications.center.empty'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: controller.fetchNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = controller.notifications[index];
                final date = DateFormat('y/MM/dd – HH:mm').format(log.createdAt);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withOpacity(0.1),
                        foregroundColor: AppColors.primary,
                        child: Icon(_iconForType(log.type)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    log.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (!log.isRead)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(log.body),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Chip(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  label: Text(_labelForType(log.type)),
                                ),
                                const Spacer(),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'reminder':
        return Icons.alarm;
      case 'budget':
        return Icons.account_balance_wallet;
      case 'insight':
        return Icons.auto_awesome;
      default:
        return Icons.notifications;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'reminder':
        return 'notifications.type.reminder'.tr;
      case 'budget':
        return 'notifications.type.budget'.tr;
      case 'insight':
        return 'notifications.type.insight'.tr;
      default:
        return 'notifications.type.general'.tr;
    }
  }
}

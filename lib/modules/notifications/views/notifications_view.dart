import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF16334A), Color(0xFF0B1923)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'notifications.center.title'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'notifications.center.mark_read'.tr,
                        onPressed: controller.markAllAsRead,
                        icon: const Icon(Icons.done_all, color: Colors.white),
                      ),
                      IconButton(
                        tooltip: 'notifications.center.clear'.tr,
                        onPressed: controller.clearAll,
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'notifications.center.subtitle'.tr,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.notifications.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.notifications.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.08),
                                ),
                                child: const Icon(
                                  Icons.notifications_off_outlined,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'notifications.center.empty'.tr,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: controller.fetchNotifications,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: controller.notifications.length,
                        itemBuilder: (context, index) {
                          final log = controller.notifications[index];
                          final date = DateFormat('y/MM/dd • HH:mm')
                              .format(log.createdAt);
                          final statusBg = log.isRead
                              ? theme.colorScheme.surfaceVariant
                              : AppColors.accent.withOpacity(0.18);
                          final statusColor = log.isRead
                              ? theme.colorScheme.onSurfaceVariant
                              : AppColors.accent;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: log.isRead
                                    ? [
                                        theme.cardColor,
                                        theme.cardColor,
                                      ]
                                    : [
                                        theme.colorScheme.primary
                                            .withOpacity(0.08),
                                        theme.cardColor,
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: log.isRead
                                    ? Colors.transparent
                                    : theme.colorScheme.primary.withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: _colorForType(log.type)
                                              .withValues(alpha: 0.14),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Icon(
                                          _iconForType(log.type),
                                          color: _colorForType(log.type),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              log.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              date,
                                              style: theme.textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .textTheme.bodySmall?.color
                                                        ?.withOpacity(0.6),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!log.isRead)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'notifications.badge.new'.tr,
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    log.body,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Chip(
                                        avatar: Icon(
                                          Icons.label_rounded,
                                          size: 16,
                                          color: theme
                                              .colorScheme.onSecondaryContainer,
                                        ),
                                        label: Text(_labelForType(log.type)),
                                        backgroundColor: theme
                                            .colorScheme.secondaryContainer,
                                      ),
                                      Chip(
                                        avatar: Icon(
                                          log.isRead
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 16,
                                          color: statusColor,
                                        ),
                                        label: Text(
                                          log.isRead
                                              ? 'notifications.status.read'.tr
                                              : 'notifications.status.unread'.tr,
                                        ),
                                        backgroundColor: statusBg,
                                        labelStyle: theme.textTheme.bodySmall
                                            ?.copyWith(color: statusColor),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: theme
                                                .colorScheme.primary,
                                          ),
                                          onPressed: log.isRead
                                              ? null
                                              : () =>
                                                  controller.markAsRead(log),
                                          icon: const Icon(
                                              Icons.mark_email_read_outlined),
                                          label: Text(
                                            'notifications.actions.read'.tr,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextButton.icon(
                                          style: TextButton.styleFrom(
                                            backgroundColor: theme
                                                .colorScheme.error
                                                .withOpacity(0.08),
                                            foregroundColor:
                                                theme.colorScheme.error,
                                          ),
                                          onPressed: () => controller
                                              .deleteNotification(log),
                                          icon: const Icon(
                                              Icons.delete_sweep_outlined),
                                          label: Text(
                                            'notifications.actions.delete'.tr,
                                          ),
                                        ),
                                    )  ],
                                  
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
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

  Color _colorForType(String type) {
    switch (type) {
      case 'reminder':
        return AppColors.accent;
      case 'budget':
        return const Color(0xFF2FB886);
      case 'insight':
        return const Color(0xFF8E6CFF);
      default:
        return const Color(0xFF5C7393);
    }
  }
}

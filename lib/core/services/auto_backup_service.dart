import 'dart:async';

import 'package:get/get.dart';
import 'package:my_expenses/core/services/backup_service.dart';

import 'notification_service.dart';
import 'settings_service.dart';

class AutoBackupService extends GetxService {
  late final SettingsService _settings;
  late final BackupService _backupService;
  late final NotificationService _notificationService;
  Timer? _timer;

  Future<AutoBackupService> init() async {
    _settings = Get.find<SettingsService>();
    _backupService = Get.find<BackupService>();
    _notificationService = Get.find<NotificationService>();
    _startScheduler();
    if (_settings.autoBackupEnabled) {
      unawaited(_checkDue());
    }
    return this;
  }

  void _startScheduler() {
    _timer?.cancel();
    if (!_settings.autoBackupEnabled) return;
    _timer = Timer.periodic(const Duration(hours: 6), (_) => _checkDue());
  }

  Future<void> refreshSchedule({bool runImmediate = false}) async {
    if (_settings.autoBackupEnabled) {
      _startScheduler();
      if (runImmediate) {
        await _checkDue();
      }
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _checkDue() async {
    if (!_settings.autoBackupEnabled) return;
    final lastRun = _settings.lastAutoBackup;
    final interval = _frequencyDuration(_settings.autoBackupFrequency);
    final now = DateTime.now();
    if (lastRun != null && now.difference(lastRun) < interval) return;
    try {
      final entry = await _backupService.createBackup();
      final runDate = entry.createdAt;
      await _settings.setLastAutoBackup(runDate);
      await _notificationService.showInstantNotification(
        title: 'backup.auto.success_title'.tr,
        body: 'backup.auto.success_body'.trParams({'path': entry.name}),
        type: 'auto_backup',
      );
    } catch (e) {
      await _notificationService.showInstantNotification(
        title: 'backup.auto.error_title'.tr,
        body: 'backup.auto.error_body'.tr,
        type: 'auto_backup',
      );
    }
  }

  Duration _frequencyDuration(String frequency) {
    switch (frequency) {
      case 'daily':
        return const Duration(days: 1);
      case 'monthly':
        return const Duration(days: 30);
      case 'weekly':
      default:
        return const Duration(days: 7);
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

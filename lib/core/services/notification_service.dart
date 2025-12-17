import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/notification_log_model.dart';
import '../../data/models/reminder_model.dart';
import '../../data/repositories/local_expense_repository.dart';
import 'settings_service.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  late final LocalExpenseRepository _repository;
  late final SettingsService _settingsService;
  bool _initialized = false;
  bool _customSoundAvailable = true;
  bool _exactAlarmAllowed = true;

  static const _reminderChannelId = 'reminders_channel';
  static const _reminderChannelName = 'Reminders';
  static const _reminderChannelDescription =
      'Local reminders scheduled from the My Expenses app.';

  Future<NotificationService> init() async {
    _repository = Get.find<LocalExpenseRepository>();
    _settingsService = Get.find<SettingsService>();
    if (_isRunningInTest || !_isSupportedPlatform) {
      return this;
    }
    await _configureTimezone();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    await _plugin.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    await _requestPermissions();
    _initialized = true;
    return this;
  }

  Future<void> _configureTimezone() async {
    tz.initializeTimeZones();
    final zoneName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(zoneName));
      return;
    } catch (_) {
      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inHours;
      if (hours == 0) {
        tz.setLocalLocation(tz.getLocation('UTC'));
        return;
      }
      final sign = hours >= 0 ? '-' : '+';
      final locationName = 'Etc/GMT$sign${hours.abs()}';
      try {
        tz.setLocalLocation(tz.getLocation(locationName));
        return;
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (_isRunningInTest) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails _buildReminderDetails({bool useCustomSound = true}) {
    final android = AndroidNotificationDetails(
      _reminderChannelId,
      _reminderChannelName,
      channelDescription: _reminderChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: useCustomSound && _customSoundAvailable
          ? RawResourceAndroidNotificationSound('reminder_tone')
          : null,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  Future<void> scheduleReminder(
    ReminderModel reminder, {
    bool logEntry = true,
  }) async {
    if (!_initialized) return;
    if (reminder.id == null) return;
    final scheduledDate = _nextInstance(reminder.date, reminder.time);
    final title = _reminderTitle();
    final body = _reminderBody(reminder);
    int? logId;
    if (logEntry) {
      logId = await _repository.insertNotificationLog(
        NotificationLogModel(
          title: title,
          body: body,
          type: 'reminder',
          createdAt: scheduledDate,
        ),
      );
    }
    Future<void> schedule({
      required AndroidScheduleMode mode,
      bool customSound = true,
    }) async {
      await _plugin.zonedSchedule(
        reminder.id!,
        title,
        body,
        scheduledDate,
        _buildReminderDetails(useCustomSound: customSound),
        payload: logId?.toString(),
        androidScheduleMode: mode,
      );
    }

    try {
      await schedule(
        mode: _exactAlarmAllowed
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      if (e.code == 'invalid_sound' && _customSoundAvailable) {
        _customSoundAvailable = false;
        await schedule(
          mode: _exactAlarmAllowed
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          customSound: false,
        );
      } else if (e.code == 'exact_alarms_not_permitted' && _exactAlarmAllowed) {
        final granted = await _requestExactAlarmPermission();
        if (granted) {
          await schedule(
            mode: AndroidScheduleMode.exactAllowWhileIdle,
            customSound: _customSoundAvailable,
          );
        } else {
          _exactAlarmAllowed = false;
          await schedule(mode: AndroidScheduleMode.inexactAllowWhileIdle);
        }
      } else {
        rethrow;
      }
    }
  }

  Future<bool> _requestExactAlarmPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;
    final granted = await androidPlugin.requestExactAlarmsPermission();
    _exactAlarmAllowed = granted ?? false;
    return _exactAlarmAllowed;
  }

  Future<void> cancelReminder(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAllReminderNotifications() async {
    if (!_initialized) return;
    final reminders = await _repository.fetchReminders();
    for (final reminder in reminders) {
      if (reminder.id != null) {
        await _plugin.cancel(reminder.id!);
      }
    }
  }

  Future<void> rescheduleAllReminders() async {
    await cancelAllReminderNotifications();
    final reminders = await _repository.fetchReminders();
    for (final reminder in reminders) {
      await scheduleReminder(reminder, logEntry: false);
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String type = 'general',
  }) async {
    if (!_initialized) return;
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final logId = await _repository.insertNotificationLog(
      NotificationLogModel(
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
      ),
    );
    await _plugin.show(id, title, body, _buildReminderDetails(),
        payload: logId.toString());
  }

  Future<void> _onNotificationResponse(
    NotificationResponse response,
  ) async {
    if (!_initialized) return;
    final payload = response.payload;
    if (payload == null) return;
    final logId = int.tryParse(payload);
    if (logId != null) {
      await _repository.markNotificationAsRead(logId);
    }
  }

  tz.TZDateTime _nextInstance(DateTime date, String timeString) {
    final parts = timeString.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    var scheduled = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
    final now = tz.TZDateTime.now(tz.local);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  String _formatReminderTime(ReminderModel reminder) {
    final parts = reminder.time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final dt = DateTime(
      reminder.date.year,
      reminder.date.month,
      reminder.date.day,
      hour,
      minute,
    );
    return DateFormat('y/MM/dd – HH:mm').format(dt);
  }

  String _reminderTitle() {
    final code = _settingsService.locale.languageCode;
    return code == 'ar' ? 'تذكير بالمصاريف' : 'Budget reminder';
  }

  String _reminderBody(ReminderModel reminder) {
    final code = _settingsService.locale.languageCode;
    final time = _formatReminderTime(reminder);
    final prefix =
        code == 'ar' ? 'حان وقت التذكير:' : 'Time to review your spending:';
    final scheduleLabel =
        code == 'ar' ? 'الوقت:' : 'Scheduled for:';
    return '$prefix ${reminder.message}\n$scheduleLabel $time';
  }
}

bool get _isRunningInTest =>
    Platform.environment.containsKey('FLUTTER_TEST');

bool get _isSupportedPlatform =>
    Platform.isAndroid ||
    Platform.isIOS ||
    Platform.isMacOS ||
    Platform.isWindows ||
    Platform.isLinux;

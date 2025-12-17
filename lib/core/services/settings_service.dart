import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsService extends GetxService {
  static const _themeKey = 'theme_mode';
  static const _onboardingKey = 'is_onboarded';
  static const _localeKey = 'locale_code';
  static const _budgetKey = 'monthly_budget';
  static const _aiKey = 'ai_insights_enabled';
  static const _notificationsKey = 'notifications_enabled';
  static const _textScaleKey = 'text_scale_factor';
  static const _autoBackupEnabledKey = 'auto_backup_enabled';
  static const _autoBackupFrequencyKey = 'auto_backup_frequency';
  static const _autoBackupLastRunKey = 'auto_backup_last_run';

  final GetStorage _box = GetStorage();
  ThemeMode _themeMode = ThemeMode.light;
  bool _isOnboarded = false;
  Locale _locale = const Locale('ar');
  double _monthlyBudget = 3000;
  bool _aiInsightsEnabled = true;
  bool _notificationsEnabled = true;
  double _textScale = 1.0;
  bool _autoBackupEnabled = false;
  String _autoBackupFrequency = 'weekly';
  DateTime? _lastAutoBackup;
  final RxDouble textScaleNotifier = 1.0.obs;
  final Rxn<DateTime> lastAutoBackupNotifier = Rxn<DateTime>();

  Future<SettingsService> init() async {
    final themeName = _box.read<String>(_themeKey);
    if (themeName != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.light,
      );
    }
    _isOnboarded = _box.read<bool>(_onboardingKey) ?? false;
    final localeCode = _box.read<String>(_localeKey);
    if (localeCode != null) {
      _locale = Locale(localeCode);
    }
    _monthlyBudget = (_box.read<double>(_budgetKey) ?? 3000).toDouble();
    _aiInsightsEnabled = _box.read<bool>(_aiKey) ?? true;
    _notificationsEnabled = _box.read<bool>(_notificationsKey) ?? true;
    _textScale = (_box.read<double>(_textScaleKey) ?? 1.0).clamp(0.8, 1.4);
    textScaleNotifier.value = _textScale;
    _autoBackupEnabled = _box.read<bool>(_autoBackupEnabledKey) ?? false;
    _autoBackupFrequency =
        _box.read<String>(_autoBackupFrequencyKey) ?? 'weekly';
    final lastRunString = _box.read<String>(_autoBackupLastRunKey);
    if (lastRunString != null) {
      _lastAutoBackup = DateTime.tryParse(lastRunString);
    }
    lastAutoBackupNotifier.value = _lastAutoBackup;
    return this;
  }

  ThemeMode get themeMode => _themeMode;
  bool get isOnboarded => _isOnboarded;
  Locale get locale => _locale;
  double get monthlyBudget => _monthlyBudget;
  bool get aiInsightsEnabled => _aiInsightsEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  double get textScaleFactor => textScaleNotifier.value;
  bool get autoBackupEnabled => _autoBackupEnabled;
  String get autoBackupFrequency => _autoBackupFrequency;
  DateTime? get lastAutoBackup => _lastAutoBackup;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _box.write(_themeKey, mode.name);
  }

  Future<void> setOnboardingComplete() async {
    _isOnboarded = true;
    await _box.write(_onboardingKey, true);
  }

  Future<void> resetOnboarding() async {
    _isOnboarded = false;
    await _box.write(_onboardingKey, false);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _box.write(_localeKey, locale.languageCode);
  }

  Future<void> setMonthlyBudget(double value) async {
    _monthlyBudget = value;
    await _box.write(_budgetKey, value);
  }

  Future<void> setAiInsightsEnabled(bool value) async {
    _aiInsightsEnabled = value;
    await _box.write(_aiKey, value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _box.write(_notificationsKey, value);
  }

  Future<void> setTextScale(double value) async {
    final clamped = value.clamp(0.8, 1.4);
    _textScale = clamped;
    textScaleNotifier.value = clamped;
    await _box.write(_textScaleKey, clamped);
  }

  Future<void> setAutoBackupEnabled(bool value) async {
    _autoBackupEnabled = value;
    await _box.write(_autoBackupEnabledKey, value);
  }

  Future<void> setAutoBackupFrequency(String value) async {
    _autoBackupFrequency = value;
    await _box.write(_autoBackupFrequencyKey, value);
  }

  Future<void> setLastAutoBackup(DateTime dateTime) async {
    _lastAutoBackup = dateTime;
    lastAutoBackupNotifier.value = dateTime;
    await _box.write(_autoBackupLastRunKey, dateTime.toIso8601String());
  }
}

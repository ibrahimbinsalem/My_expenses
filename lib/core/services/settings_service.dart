import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsService extends GetxService {
  static const _themeKey = 'theme_mode';
  static const _onboardingKey = 'is_onboarded';

  final GetStorage _box = GetStorage();
  ThemeMode _themeMode = ThemeMode.light;
  bool _isOnboarded = false;

  Future<SettingsService> init() async {
    final themeName = _box.read<String>(_themeKey);
    if (themeName != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.light,
      );
    }
    _isOnboarded = _box.read<bool>(_onboardingKey) ?? false;
    return this;
  }

  ThemeMode get themeMode => _themeMode;
  bool get isOnboarded => _isOnboarded;

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
}

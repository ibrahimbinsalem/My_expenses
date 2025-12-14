import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/settings_service.dart';

class ThemeController extends GetxController {
  ThemeController(this._settingsService);

  final SettingsService _settingsService;

  final themeMode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = _settingsService.themeMode;
  }

  void toggleTheme(bool isDark) {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    themeMode.value = mode;
    _settingsService.setThemeMode(mode);
    Get.changeThemeMode(mode);
  }
}

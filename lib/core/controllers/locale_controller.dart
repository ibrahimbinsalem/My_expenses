import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/settings_service.dart';

class LocaleController extends GetxController {
  LocaleController(this._settingsService);

  final SettingsService _settingsService;

  final List<Locale> supportedLocales = const [
    Locale('ar'),
    Locale('en'),
  ];

  final locale = const Locale('ar').obs;

  @override
  void onInit() {
    super.onInit();
    locale.value = _settingsService.locale;
  }

  void changeLocale(Locale newLocale) {
    if (locale.value == newLocale) return;
    locale.value = newLocale;
    _settingsService.setLocale(newLocale);
    Get.updateLocale(newLocale);
  }
}

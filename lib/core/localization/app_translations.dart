import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AppTranslations extends Translations {
  AppTranslations(this._keys);

  final Map<String, Map<String, String>> _keys;

  static Future<AppTranslations> load() async {
    final ar = await _loadLocaleFile('assets/langs/ar.json');
    final en = await _loadLocaleFile('assets/langs/en.json');
    return AppTranslations({'ar': ar, 'en': en});
  }

  static Future<Map<String, String>> _loadLocaleFile(String path) async {
    final data = await rootBundle.loadString(path);
    final Map<String, dynamic> jsonMap = jsonDecode(data);
    return jsonMap.map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  @override
  Map<String, Map<String, String>> get keys => _keys;
}

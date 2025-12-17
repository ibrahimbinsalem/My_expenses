import 'package:get/get.dart';

String localizedCurrencyName(Map<String, String> entry) {
  final arabic =
      entry['nameAr'] ?? entry['name_ar'] ?? entry['name'] ?? '';
  final english =
      entry['nameEn'] ?? entry['name_en'] ?? arabic;
  final localeCode = Get.locale?.languageCode ?? 'ar';
  if (localeCode == 'en') {
    return english.isNotEmpty ? english : arabic;
  }
  return arabic.isNotEmpty ? arabic : english;
}

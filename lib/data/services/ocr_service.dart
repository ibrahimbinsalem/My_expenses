import 'package:get/get.dart';

/// Placeholder for an offline OCR service (e.g., Google ML Kit).
/// Currently returns mocked data until the native implementation is wired.
class ReceiptOcrService {
  Future<Map<String, dynamic>> parseReceipt(String imagePath) async {
    // TODO: integrate ML Kit locally. For now return fake data.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return {
      'amount': 120.5,
      'date': DateTime.now().toIso8601String(),
      'category': 'مطاعم'.tr,
    };
  }
}

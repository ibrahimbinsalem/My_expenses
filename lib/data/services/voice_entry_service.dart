import 'package:get/get.dart';

/// Placeholder for offline speech-to-text parsing.
class VoiceEntryService {
  Future<String> transcribe(String audioPath) async {
    // TODO: connect a local STT like Vosk.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return 'voice.sample_entry'.tr;
  }

  /// Very simple intent parser to extract amount + keyword from text.
  Map<String, dynamic> parseIntent(String sentence) {
    final tokens = sentence.split(' ');
    double? amount;
    for (final token in tokens) {
      final parsed = double.tryParse(token.replaceAll(RegExp('[^0-9.]'), ''));
      if (parsed != null) {
        amount = parsed;
        break;
      }
    }
    return {'amount': amount, 'note': sentence};
  }
}

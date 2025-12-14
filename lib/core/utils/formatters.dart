import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormatter = NumberFormat.currency(
    symbol: '﷼',
    decimalDigits: 2,
    locale: 'ar_SA',
  );
  static final _dateFormatter = DateFormat('dd MMM yyyy');

  static String currency(num value, {String? symbol}) {
    if (symbol != null) {
      final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
      return formatter.format(value);
    }
    return _currencyFormatter.format(value);
  }

  static String shortDate(DateTime date) => _dateFormatter.format(date);

  static String amountInArabicWords(num value, {String currency = 'ريال'}) {
    final integerPart = value.floor();
    final fractionPart = ((value - integerPart) * 100).round();
    final buffer = StringBuffer();
    buffer.write('${_arabicNumberToWords(integerPart)} $currency');
    if (fractionPart > 0) {
      buffer.write(' و${_arabicNumberToWords(fractionPart)} هللة');
    }
    return buffer.toString();
  }

  static String _arabicNumberToWords(int number) {
    if (number == 0) return 'صفر';
    final units = [
      '',
      'واحد',
      'اثنان',
      'ثلاثة',
      'أربعة',
      'خمسة',
      'ستة',
      'سبعة',
      'ثمانية',
      'تسعة',
    ];
    final tens = [
      '',
      'عشرة',
      'عشرون',
      'ثلاثون',
      'أربعون',
      'خمسون',
      'ستون',
      'سبعون',
      'ثمانون',
      'تسعون',
    ];
    final teens = {
      11: 'أحد عشر',
      12: 'اثنا عشر',
      13: 'ثلاثة عشر',
      14: 'أربعة عشر',
      15: 'خمسة عشر',
      16: 'ستة عشر',
      17: 'سبعة عشر',
      18: 'ثمانية عشر',
      19: 'تسعة عشر',
    };
    final hundreds = [
      '',
      'مائة',
      'مائتان',
      'ثلاثمائة',
      'أربعمائة',
      'خمسمائة',
      'ستمائة',
      'سبعمائة',
      'ثمانمائة',
      'تسعمائة',
    ];
    final scales = ['', 'ألف', 'مليون', 'مليار'];

    String convertTriplet(int num) {
      final h = num ~/ 100;
      final remainder = num % 100;
      final t = remainder ~/ 10;
      final u = remainder % 10;
      final parts = <String>[];
      if (h > 0) {
        parts.add(hundreds[h]);
      }
      if (remainder > 10 && remainder < 20) {
        parts.add(teens[remainder]!);
      } else {
        if (u > 0) {
          parts.add(units[u]);
        }
        if (t > 0) {
          parts.add(tens[t]);
        }
      }
      return parts.join(' و');
    }

    final result = <String>[];
    var temp = number;
    var scaleIndex = 0;

    while (temp > 0 && scaleIndex < scales.length) {
      final triplet = temp % 1000;
      if (triplet != 0) {
        final tripletWords = convertTriplet(triplet);
        final scale = scales[scaleIndex];
        result.insert(
          0,
          scale.isNotEmpty
              ? '$tripletWords ${scale.trim()}'.trim()
              : tripletWords,
        );
      }
      temp ~/= 1000;
      scaleIndex++;
    }

    return result.join(' و');
  }
}

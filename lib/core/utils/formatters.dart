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
}

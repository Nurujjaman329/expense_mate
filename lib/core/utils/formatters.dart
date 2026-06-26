import 'package:intl/intl.dart';

/// Currency and date formatting helpers.
class Formatters {
  Formatters._();

  static String currency(
    double amount, {
    String symbol = '\$',
    int decimalDigits = 2,
  }) {
    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }

  static String date(DateTime date, {String pattern = 'MMM dd, yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  static String time(DateTime date, {String pattern = 'hh:mm a'}) {
    return DateFormat(pattern).format(date);
  }

  static String percentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  static String compactNumber(num value) {
    return NumberFormat.compact().format(value);
  }
}

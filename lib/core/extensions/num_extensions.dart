import 'package:intl/intl.dart';

extension NumExtensions on num {
  String toCurrency({String symbol = '\$', int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(this);
  }

  String toCompactCurrency({String symbol = '\$'}) {
    if (this >= 1000000) {
      return '$symbol${(this / 1000000).toStringAsFixed(1)}M';
    }
    if (this >= 1000) {
      return '$symbol${(this / 1000).toStringAsFixed(1)}K';
    }
    return toCurrency(symbol: symbol);
  }
}

extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  bool get isStrongPassword => length >= 8;
}

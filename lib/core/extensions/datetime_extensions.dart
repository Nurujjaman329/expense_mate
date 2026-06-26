import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  String toDisplayDate({String pattern = 'MMM dd, yyyy'}) =>
      DateFormat(pattern).format(this);

  String toDisplayTime({String pattern = 'hh:mm a'}) =>
      DateFormat(pattern).format(this);

  String toDisplayDateTime() => DateFormat('MMM dd, yyyy • hh:mm a').format(this);

  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  DateTime get startOfMonth => DateTime(year, month);

  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;
}

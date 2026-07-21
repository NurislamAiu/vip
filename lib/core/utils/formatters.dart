import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Small display-formatting helpers used across screens.
class Formatters {
  Formatters._();

  static final DateFormat _dateFormat = DateFormat('d MMM yyyy', 'ru');
  static final DateFormat _shortDateFormat = DateFormat('d MMM', 'ru');

  static String date(DateTime? value) =>
      value == null ? '—' : _dateFormat.format(value);

  static String shortDate(DateTime? value) =>
      value == null ? '—' : _shortDateFormat.format(value);

  static String time(String value) => value.trim().isEmpty ? '—' : value;

  static String text(String value) => value.trim().isEmpty ? '—' : value;

  /// "dd MMM · HH:mm" — a compact date+time label for cards.
  static String dateTime(DateTime? date, String time) {
    if (date == null && time.trim().isEmpty) return '—';
    final datePart = date == null ? '' : _shortDateFormat.format(date);
    final timePart = time.trim();
    if (datePart.isEmpty) return timePart;
    if (timePart.isEmpty) return datePart;
    return '$datePart · $timePart';
  }

  static String timeOfDay(TimeOfDay value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static TimeOfDay? parseTimeOfDay(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }
}

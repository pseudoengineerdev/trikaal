import 'package:flutter/material.dart';

class BirthInputFormatters {
  const BirthInputFormatters._();

  static final RegExp _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp _timePattern = RegExp(r'^\d{2}:\d{2}$');

  static String? validateDate(String? value) {
    final input = value?.trim() ?? '';
    if (!_datePattern.hasMatch(input)) {
      return 'Use format YYYY-MM-DD';
    }
    return null;
  }

  static String? validateTime(String? value) {
    final input = value?.trim() ?? '';
    if (!_timePattern.hasMatch(input)) {
      return 'Use format HH:MM';
    }
    return null;
  }

  static DateTime? parseDate(String input) {
    final parts = input.split('-');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime.tryParse('$year-${_two(month)}-${_two(day)}');
  }

  static TimeOfDay? parseTime(String input) {
    final parts = input.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String formatDate(DateTime date) {
    return '${date.year}-${_two(date.month)}-${_two(date.day)}';
  }

  static String formatTime(TimeOfDay time) {
    return '${_two(time.hour)}:${_two(time.minute)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  /// Returns "Today", "Yesterday", or formatted date
  static String chatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date);         // e.g. Monday
    if (date.year == now.year) return DateFormat('MMM d').format(date); // e.g. Jun 3
    return DateFormat('MMM d, yyyy').format(date);                // e.g. Jun 3, 2023
  }

  /// Returns "2:45 PM"
  static String messageTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Returns "Jun 3, 2024 · 2:45 PM"
  static String fullDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy · h:mm a').format(date);
  }
}
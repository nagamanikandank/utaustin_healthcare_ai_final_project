import 'package:intl/intl.dart';

DateTime startOfWeek(DateTime date) {
  // Monday as start of week
  final int daysToSubtract = date.weekday - DateTime.monday;
  return DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: daysToSubtract));
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String formatTimeRange(DateTime start, DateTime end) {
  final fmt = DateFormat('h:mm a');
  return '${fmt.format(start)} - ${fmt.format(end)}';
}

String formatDay(DateTime date) {
  final fmt = DateFormat('EEE, MMM d');
  return fmt.format(date);
}

List<DateTime> halfHourSlots(DateTime day) {
  final List<DateTime> slots = [];
  DateTime t = DateTime(day.year, day.month, day.day, 8, 0);
  final DateTime end = DateTime(day.year, day.month, day.day, 17, 0);
  while (t.isBefore(end)) {
    // Skip lunch 12:00–13:00
    if (!(t.hour == 12)) {
      slots.add(t);
    }
    t = t.add(const Duration(minutes: 30));
  }
  return slots;
}

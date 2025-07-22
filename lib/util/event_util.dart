import 'package:attendify/models/event.dart';
import 'package:intl/intl.dart';

bool isEventCompletedToday(Event event) {
  final today = DateTime.now();
  final todayWeekday = DateFormat('EEEE').format(today);

  if (event.completedDays == null || !event.assignedDays.contains(todayWeekday)) {
    return false;
  }

  // Check if today is marked as not conducted
  if (event.notConductedDays != null) {
    bool isNotConducted = event.notConductedDays!.any(
          (day) =>
      day.date.year == today.year &&
          day.date.month == today.month &&
          day.date.day == today.day,
    );
    if (isNotConducted) return false;
  }

  return event.completedDays!.any(
        (completedDay) =>
    completedDay.date.year == today.year &&
        completedDay.date.month == today.month &&
        completedDay.date.day == today.day,
  );
}

bool isEventNotConductedToday(Event event) {
  final today = DateTime.now();
  final todayWeekday = DateFormat('EEEE').format(today);

  if (!event.assignedDays.contains(todayWeekday)) {
    return false;
  }

  if (event.notConductedDays == null) {
    return false;
  }

  return event.notConductedDays!.any(
        (day) =>
    day.date.year == today.year &&
        day.date.month == today.month &&
        day.date.day == today.day,
  );
}

Map<DateTime, int> prepMapDataset(List<Event> events) {
  Map<DateTime, int> dataset = {};

  for (var event in events) {
    if (event.completedDays == null) continue;

    for (var completedDay in event.completedDays!) {
      final date = completedDay.date;
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final weekday = DateFormat('EEEE').format(normalizedDate);

      if (event.assignedDays.contains(weekday)) {
        // Check if the day is not marked as not conducted
        bool isNotConducted = event.notConductedDays?.any((day) =>
        day.date.year == normalizedDate.year &&
            day.date.month == normalizedDate.month &&
            day.date.day == normalizedDate.day) ??
            false;
        if (!isNotConducted) {
          if (dataset.containsKey(normalizedDate)) {
            dataset[normalizedDate] = dataset[normalizedDate]! + 1;
          } else {
            dataset[normalizedDate] = 1;
          }
        }
      }
    }
  }

  return dataset;
}
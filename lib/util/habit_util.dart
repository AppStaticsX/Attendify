import 'package:attendify/models/event.dart';
import 'package:intl/intl.dart';

bool isHabitCompletedToday(Habit habit) {
  final today = DateTime.now();
  final todayWeekday = DateFormat('EEEE').format(today);

  if (habit.completedDays == null || !habit.assignedDays.contains(todayWeekday)) {
    return false;
  }

  // Check if today is marked as not conducted
  if (habit.notConductedDays != null) {
    bool isNotConducted = habit.notConductedDays!.any(
          (day) =>
      day.date.year == today.year &&
          day.date.month == today.month &&
          day.date.day == today.day,
    );
    if (isNotConducted) return false;
  }

  return habit.completedDays!.any(
        (completedDay) =>
    completedDay.date.year == today.year &&
        completedDay.date.month == today.month &&
        completedDay.date.day == today.day,
  );
}

bool isHabitNotConductedToday(Habit habit) {
  final today = DateTime.now();
  final todayWeekday = DateFormat('EEEE').format(today);

  if (!habit.assignedDays.contains(todayWeekday)) {
    return false;
  }

  if (habit.notConductedDays == null) {
    return false;
  }

  return habit.notConductedDays!.any(
        (day) =>
    day.date.year == today.year &&
        day.date.month == today.month &&
        day.date.day == today.day,
  );
}

Map<DateTime, int> prepMapDataset(List<Habit> habits) {
  Map<DateTime, int> dataset = {};

  for (var habit in habits) {
    if (habit.completedDays == null) continue;

    for (var completedDay in habit.completedDays!) {
      final date = completedDay.date;
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final weekday = DateFormat('EEEE').format(normalizedDate);

      if (habit.assignedDays.contains(weekday)) {
        // Check if the day is not marked as not conducted
        bool isNotConducted = habit.notConductedDays?.any((day) =>
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
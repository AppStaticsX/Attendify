import 'package:attendify/models/event.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for calculating attendance-related statistics for university lectures
class AttendanceCalculator {

  /// Calculates the attendance percentage for a given event/course
  /// Formula: (attended lectures / total conducted lectures) * 100
  /// Cancelled lectures are excluded from the calculation
  static double calculateAttendancePercentage(Event event) {
    if (event.completedDays == null && event.notConductedDays == null) {
      return 0.0;
    }

    final attendedCount = event.completedDays?.length ?? 0;
    final absentCount = event.notConductedDays?.length ?? 0;

    // Total conducted lectures = attended + absent (cancelled lectures don't count)
    final totalConductedLectures = attendedCount + absentCount;

    if (totalConductedLectures == 0) {
      return 0.0;
    }

    return (attendedCount / totalConductedLectures) * 100;
  }

  /// Gets the total number of lectures attended
  static int getAttendedLecturesCount(Event event) {
    return event.completedDays?.length ?? 0;
  }

  /// Gets the total number of lectures missed (absent)
  static int getAbsentLecturesCount(Event event) {
    return event.notConductedDays?.length ?? 0;
  }

  /// Gets the total number of lectures cancelled by professor
  static int getCancelledLecturesCount(Event event) {
    return event.cancelledDays?.length ?? 0;
  }

  /// Gets the total number of conducted lectures (attended + absent, excluding cancelled)
  static int getTotalConductedLectures(Event event) {
    final attendedCount = getAttendedLecturesCount(event);
    final absentCount = getAbsentLecturesCount(event);
    return attendedCount + absentCount;
  }

  /// Calculates total lecture days between start date and end date according to assigned days
  /// This counts all days that match the event's assigned weekdays, excluding holidays and cancelled lectures
  /// Returns the total number of expected lecture days in the given date range
  static Future<int> calculateTotalLectureDays(
      Event event,
      DateTime startDate,
      DateTime endDate,
      ) async {
    // Normalize dates to remove time component
    final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day);

    // Validate date range
    if (normalizedEndDate.isBefore(normalizedStartDate)) {
      return 0;
    }

    // Get cancelled days set for quick lookup
    final cancelledSet = (event.cancelledDays ?? [])
        .map((day) => DateTime(day.date.year, day.date.month, day.date.day))
        .toSet();

    int totalLectureDays = 0;
    DateTime currentDate = normalizedStartDate;

    // Iterate through each day in the date range
    while (currentDate.isBefore(normalizedEndDate.add(Duration(days: 1)))) {
      final weekday = DateFormat('EEEE').format(currentDate);

      // Count if this day is assigned AND not cancelled
      if (event.assignedDays.contains(weekday) && !cancelledSet.contains(currentDate)) {
        totalLectureDays++;
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return totalLectureDays;
  }

  /// Calculates total lecture days from schedule start date to schedule end date
  /// Uses the dates stored in SharedPreferences
  static Future<int> calculateTotalLectureDaysForSemester(Event event) async {
    final prefs = await SharedPreferences.getInstance();
    final int? startDateMillis = prefs.getInt('schedule_start_date');
    final int? endDateMillis = prefs.getInt('schedule_end_date');

    if (startDateMillis == null || endDateMillis == null) {
      // Fallback: return total conducted lectures if dates are not set
      return getTotalConductedLectures(event);
    }

    final startDate = DateTime.fromMillisecondsSinceEpoch(startDateMillis);
    final endDate = DateTime.fromMillisecondsSinceEpoch(endDateMillis);

    return await calculateTotalLectureDays(event, startDate, endDate);
  }

  /// Calculates total lecture days from schedule start date to current date
  /// This is useful for calculating attendance percentage based on expected lectures so far
  static Future<int> calculateTotalLectureDaysToDate(Event event) async {
    final prefs = await SharedPreferences.getInstance();
    final int? startDateMillis = prefs.getInt('schedule_start_date');

    if (startDateMillis == null) {
      // Fallback to old method if schedule start date is not set
      return getTotalConductedLectures(event);
    }

    final startDate = DateTime.fromMillisecondsSinceEpoch(startDateMillis);
    final currentDate = DateTime.now();

    return await calculateTotalLectureDays(event, startDate, currentDate);
  }

  /// Gets the total number of scheduled lectures from schedule_start_date to current date
  /// This counts all days that match the assigned weekdays, excluding holidays and cancelled lectures
  static Future<int> getTotalScheduledLectures(Event event) async {
    final prefs = await SharedPreferences.getInstance();
    final int? storedMillis = prefs.getInt('schedule_start_date');

    if (storedMillis == null) {
      // Fallback to old method if schedule start date is not set
      return getTotalConductedLectures(event);
    }

    final startDate = DateTime.fromMillisecondsSinceEpoch(storedMillis);
    final currentDate = DateTime.now();

    // Get cancelled days set
    final cancelledSet = (event.cancelledDays ?? [])
        .map((day) => DateTime(day.date.year, day.date.month, day.date.day))
        .toSet();

    int totalScheduled = 0;
    DateTime iterDate = startDate;

    while (iterDate.isBefore(currentDate) || iterDate.isAtSameMomentAs(currentDate)) {
      final normalizedIterDate = DateTime(iterDate.year, iterDate.month, iterDate.day);
      final weekday = DateFormat('EEEE').format(iterDate);

      // Count if this day is assigned AND not cancelled
      if (event.assignedDays.contains(weekday) &&
          !cancelledSet.contains(normalizedIterDate)) {
        totalScheduled++;
      }

      iterDate = iterDate.add(const Duration(days: 1));
    }

    return totalScheduled;
  }

  /// Calculates how many more lectures can be missed while staying above minimum attendance
  /// Returns -1 if already below minimum or if calculation is not possible
  static int getSafeAbsences(Event event) {
    final currentPercentage = calculateAttendancePercentage(event);
    final minRequired = event.minAttendanceRequired;

    final attendedCount = getAttendedLecturesCount(event);
    final totalConducted = getTotalConductedLectures(event);

    if (totalConducted == 0 || attendedCount == 0) {
      return 0;
    }

    // If already below minimum, return -1
    if (currentPercentage < minRequired) {
      return -1;
    }

    // Calculate: How many total lectures can we have while maintaining minimum percentage
    // Formula: attendedCount / (attendedCount + absentCount + x) >= minRequired/100
    // Solving for x (additional absences allowed)

    final maxTotalLectures = (attendedCount * 100) / minRequired;
    final safeAbsences = maxTotalLectures.floor() - totalConducted;

    return safeAbsences > 0 ? safeAbsences : 0;
  }

  /// Calculates how many more lectures need to be attended to reach minimum attendance
  /// Returns 0 if already above minimum or if target is unreachable
  static int getRequiredAttendance(Event event) {
    final currentPercentage = calculateAttendancePercentage(event);
    final minRequired = event.minAttendanceRequired;

    // Already above minimum
    if (currentPercentage >= minRequired) {
      return 0;
    }

    final attendedCount = getAttendedLecturesCount(event);
    final totalConducted = getTotalConductedLectures(event);

    if (totalConducted == 0) {
      return 0;
    }

    // Calculate: How many consecutive lectures need to be attended
    // Formula: (attendedCount + x) / (totalConducted + x) >= minRequired/100
    // Solving for x (additional attendance required)

    final numerator = (minRequired * totalConducted) - (attendedCount * 100);
    final denominator = 100 - minRequired;

    if (denominator <= 0) {
      return 0; // Can't reach 100% requirement
    }

    final requiredAttendance = (numerator / denominator).ceil();

    return requiredAttendance > 0 ? requiredAttendance : 0;
  }

  /// Gets attendance status based on current percentage
  /// Returns: 'safe', 'warning', or 'danger'
  static String getAttendanceStatus(Event event) {
    final percentage = calculateAttendancePercentage(event);
    final minRequired = event.minAttendanceRequired;

    if (percentage >= minRequired) {
      return 'safe'; // Green - Good attendance
    } else if (percentage >= minRequired - 10) {
      return 'warning'; // Yellow - Close to minimum, be careful
    } else {
      return 'danger'; // Red - Below minimum, critical
    }
  }

  /// Gets the remaining lectures in the semester (planned - conducted)
  static int getRemainingLectures(Event event) {
    final totalPlanned = event.totalLecturesPlanned;
    final totalConducted = getTotalConductedLectures(event);
    final cancelled = getCancelledLecturesCount(event);

    // Remaining = planned - (conducted + cancelled)
    final remaining = totalPlanned - (totalConducted + cancelled);

    return remaining > 0 ? remaining : 0;
  }

  /// Calculates projected final attendance percentage
  /// Assumes student will attend all remaining lectures
  static double getProjectedAttendance(Event event) {
    final currentAttended = getAttendedLecturesCount(event);
    final totalPlanned = event.totalLecturesPlanned;
    final cancelled = getCancelledLecturesCount(event);

    if (totalPlanned == 0 || totalPlanned <= cancelled) {
      return calculateAttendancePercentage(event);
    }

    // Projected = (current attended + remaining) / (total planned - cancelled)
    final remaining = getRemainingLectures(event);
    final projectedAttended = currentAttended + remaining;
    final projectedTotal = totalPlanned - cancelled;

    return (projectedAttended / projectedTotal) * 100;
  }

  /// Calculates projected attendance if student misses all remaining lectures
  static double getWorstCaseAttendance(Event event) {
    final currentAttended = getAttendedLecturesCount(event);
    final totalPlanned = event.totalLecturesPlanned;
    final cancelled = getCancelledLecturesCount(event);

    if (totalPlanned == 0 || totalPlanned <= cancelled) {
      return calculateAttendancePercentage(event);
    }

    // Worst case = current attended / (total planned - cancelled)
    final worstCaseTotal = totalPlanned - cancelled;

    return (currentAttended / worstCaseTotal) * 100;
  }

  /// Gets a formatted string for attendance display
  /// Example: "15/20 (75.0%)"
  static String getAttendanceDisplayString(Event event) {
    final attended = getAttendedLecturesCount(event);
    final total = getTotalConductedLectures(event);
    final percentage = calculateAttendancePercentage(event);

    return '$attended/$total (${percentage.toStringAsFixed(1)}%)';
  }

  /// Checks if the course attendance is at risk
  static bool isAtRisk(Event event) {
    return getAttendanceStatus(event) != 'safe';
  }

  /// Gets color code based on attendance status (Material Design colors)
  static int getStatusColor(Event event) {
    final status = getAttendanceStatus(event);

    switch (status) {
      case 'safe':
        return 0xFF4CAF50; // Green
      case 'warning':
        return 0xFFFFA726; // Orange
      case 'danger':
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Calculates attendance percentage for a specific date range
  static double calculateAttendanceForDateRange(
      Event event,
      DateTime startDate,
      DateTime endDate,
      ) {
    final attendedInRange = event.completedDays?.where((day) {
      return day.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          day.date.isBefore(endDate.add(const Duration(days: 1)));
    }).length ?? 0;

    final absentInRange = event.notConductedDays?.where((day) {
      return day.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          day.date.isBefore(endDate.add(const Duration(days: 1)));
    }).length ?? 0;

    final totalInRange = attendedInRange + absentInRange;

    if (totalInRange == 0) {
      return 0.0;
    }

    return (attendedInRange / totalInRange) * 100;
  }

  /// Gets the current streak of consecutive attended lectures
  static int getCurrentStreak(Event event) {
    if (event.completedDays == null || event.completedDays!.isEmpty) {
      return 0;
    }

    // Sort completed days in descending order
    final sortedDays = event.completedDays!.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    final today = DateTime.now();

    for (var day in sortedDays) {
      // Check if this day is recent and consecutive
      final daysDifference = today.difference(day.date).inDays;

      if (daysDifference <= (streak * 7) + 7) { // Allowing for weekly lectures
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Gets the longest streak of consecutive attended lectures
  static int getLongestStreak(Event event) {
    if (event.completedDays == null || event.completedDays!.isEmpty) {
      return 0;
    }

    final sortedDays = event.completedDays!.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    int longestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDays.length; i++) {
      final daysDiff = sortedDays[i].date.difference(sortedDays[i - 1].date).inDays;

      // Consider consecutive if within a week (accounting for weekly lectures)
      if (daysDiff <= 7) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }
}
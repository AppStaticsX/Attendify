class DateUtil {
  static const int DAYS_IN_WEEK = 7;

  static const List<String> MONTH_LABEL = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> SHORT_MONTH_LABEL = [
    '',
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEPT',
    'OCT',
    'NOV',
    'DEC',
  ];

  static const List<Map<String, String>> WEEK_LABEL = [
    {'label': '', 'color': ''},
    {'label': 'SUN', 'color': 'red'}, // Changed to include red color for SUN
    {'label': 'MON', 'color': 'black'},
    {'label': 'TUE', 'color': 'black'},
    {'label': 'WED', 'color': 'black'},
    {'label': 'THU', 'color': 'black'},
    {'label': 'FRI', 'color': 'black'},
    {'label': 'SAT', 'color': 'grey'},
  ];

  /// Get start day of month.
  static DateTime startDayOfMonth(final DateTime referenceDate) =>
      DateTime(referenceDate.year, referenceDate.month, 1);

  /// Get last day of month.
  static DateTime endDayOfMonth(final DateTime referenceDate) =>
      DateTime(referenceDate.year, referenceDate.month + 1, 0);

  /// Get exactly one year before of [referenceDate].
  static DateTime oneYearBefore(final DateTime referenceDate) =>
      DateTime(referenceDate.year - 1, referenceDate.month, referenceDate.day);

  /// Separate [referenceDate]'s month to List of every weeks.
  static List<Map<DateTime, DateTime>> separatedMonth(
      final DateTime referenceDate) {
    DateTime startDate = startDayOfMonth(referenceDate);
    DateTime endDate = DateTime(startDate.year, startDate.month,
        startDate.day + DAYS_IN_WEEK - startDate.weekday % DAYS_IN_WEEK - 1);
    DateTime finalDate = endDayOfMonth(referenceDate);
    List<Map<DateTime, DateTime>> savedMonth = [];

    while (startDate.isBefore(finalDate) || startDate == finalDate) {
      savedMonth.add({startDate: endDate});
      startDate = changeDay(endDate, 1);
      endDate = changeDay(
          endDate,
          endDayOfMonth(endDate).day - startDate.day >= DAYS_IN_WEEK
              ? DAYS_IN_WEEK
              : endDayOfMonth(endDate).day - startDate.day + 1);
    }
    return savedMonth;
  }

  /// Change day of [referenceDate].
  static DateTime changeDay(final DateTime referenceDate, final int dayCount) =>
      DateTime(referenceDate.year, referenceDate.month,
          referenceDate.day + dayCount);

  /// Change month of [referenceDate].
  static DateTime changeMonth(final DateTime referenceDate, int monthCount) =>
      DateTime(referenceDate.year, referenceDate.month + monthCount,
          referenceDate.day);
}
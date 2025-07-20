import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/event_database.dart';

class Heatmap extends StatefulWidget {
  final Map<DateTime, int> datasets;
  final DateTime startDate;
  final int totalHabits;
  final DateTime currentDisplayedMonth;
  final List<dynamic> currentHabits;

  const Heatmap({
    super.key,
    required this.datasets,
    required this.startDate,
    required this.totalHabits,
    required this.currentDisplayedMonth,
    required this.currentHabits,
  });

  @override
  State<Heatmap> createState() => _HeatmapState();
}

class _HeatmapState extends State<Heatmap> {
  DateTime? selectedDate;
  Set<DateTime> holidayDates = {};

  @override
  void initState() {
    super.initState();
    _loadHolidayDates();
    _loadSelectedDate();
  }

  // Load holiday dates from database
  Future<void> _loadHolidayDates() async {
    final habitDatabase = Provider.of<HabitDatabase>(context, listen: false);
    final holidays = await habitDatabase.getHolidays();
    setState(() {
      holidayDates = holidays.map((date) => DateTime(date.year, date.month, date.day)).toSet();
    });
  }

  // Load the currently selected date from database (if you store it)
  Future<void> _loadSelectedDate() async {
    final habitDatabase = Provider.of<HabitDatabase>(context, listen: false);
    // Assuming you have a method to get selected date from database
    // final storedSelectedDate = await habitDatabase.getSelectedDate();
    // if (storedSelectedDate != null) {
    //   setState(() {
    //     selectedDate = DateTime(storedSelectedDate.year, storedSelectedDate.month, storedSelectedDate.day);
    //   });
    // }
  }

  // Get modified datasets that include special highlighting for selected date and holidays
  Map<DateTime, int> _getModifiedDatasets() {
    Map<DateTime, int> modifiedDatasets = {};

    // Get habits per day for percentage calculations
    Map<DateTime, int> habitsPerDay = _calculateHabitsPerDay();

    // Convert completion counts to intensity levels (0-4)
    for (DateTime date in widget.datasets.keys) {
      int completedHabits = widget.datasets[date]!;
      int totalHabitsForDay = habitsPerDay[date] ?? 0;

      int intensityLevel;
      if (totalHabitsForDay > 0) {
        double percentage = completedHabits / totalHabitsForDay;
        if (percentage == 0.0) {
          intensityLevel = 0; // No completion
        } else if (percentage <= 0.25) {
          intensityLevel = 1; // Low completion
        } else if (percentage <= 0.5) {
          intensityLevel = 2; // Medium completion
        } else if (percentage <= 0.75) {
          intensityLevel = 3; // High completion
        } else {
          intensityLevel = 4; // Full completion
        }
      } else {
        intensityLevel = 0; // No habits assigned
      }

      modifiedDatasets[date] = intensityLevel;
    }

    // Mark holiday dates with special value
    for (DateTime holiday in holidayDates) {
      DateTime normalizedHoliday = DateTime(holiday.year, holiday.month, holiday.day);
      modifiedDatasets[normalizedHoliday] = -2; // Special value for holidays
    }

    // If a date is selected, mark it with special value
    if (selectedDate != null) {
      DateTime normalizedSelectedDate = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);

      // If selected date is also a holiday, prioritize selected date color
      if (holidayDates.contains(normalizedSelectedDate)) {
        modifiedDatasets[normalizedSelectedDate] = -3; // Special value for selected holiday
      } else {
        modifiedDatasets[normalizedSelectedDate] = 0; // Special value for selected dates
      }
    }

    return modifiedDatasets;
  }

  // Calculate habits per day based on assigned days
  Map<DateTime, int> _calculateHabitsPerDay() {
    Map<DateTime, int> habitsPerDay = {};

    // Calculate first day of displayed month
    final DateTime firstDayOfMonth = DateTime(widget.currentDisplayedMonth.year, widget.currentDisplayedMonth.month, 6);

    // Calculate last day of displayed month
    final DateTime lastDayOfMonth = DateTime(widget.currentDisplayedMonth.year, widget.currentDisplayedMonth.month + 2, 0);

    // For each day in the displayed month range
    for (DateTime date = firstDayOfMonth; date.isBefore(lastDayOfMonth.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
      String dayOfWeek = DateFormat('EEEE').format(date); // e.g., "Monday"

      // Count habits assigned to this day
      int habitsForDay = widget.currentHabits.where((habit) =>
      habit.assignedDays != null && habit.assignedDays!.contains(dayOfWeek)
      ).length;

      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      habitsPerDay[normalizedDate] = habitsForDay;
    }
    return habitsPerDay;
  }

  // Generate static colorsets for intensity levels
  Map<int, Color> _generateDynamicColorsets(Map<DateTime, int> datasets) {
    Map<int, Color> colorsets = {};

    // Add special colors for different states
    colorsets[-1] = Colors.blue.shade600; // Blue for selected dates
    colorsets[-2] = Colors.red.shade400; // Red for holidays
    colorsets[-3] = Colors.purple.shade500; // Purple for selected holidays

    // Static intensity-based colors
    colorsets[0] = Theme.of(context).colorScheme.secondary; // No completion
    colorsets[1] = const Color(0xFF56D364).withValues(alpha: 0.3); // Low completion (0-25%)
    colorsets[2] = const Color(0xFF56D364).withValues(alpha: 0.5); // Medium completion (25-50%)
    colorsets[3] = const Color(0xFF56D364).withValues(alpha: 0.7); // High completion (50-75%)
    colorsets[4] = const Color(0xFF56D364); // Full completion (75-100%)

    return colorsets;
  }

  void _onDateTapped(DateTime date) async {
    final habitDatabase = Provider.of<HabitDatabase>(context, listen: false);
    final isCurrentlyHoliday = await habitDatabase.isHoliday(date);

    if (isCurrentlyHoliday) {
      await habitDatabase.removeHoliday(date);
      _showCustomSnackBar('Public-Holiday removed for ${DateFormat('MMM dd, yyyy').format(date)}');
      _getModifiedDatasets();
    } else {
      await habitDatabase.addHoliday(date);
      _showCustomSnackBar('🎉  Public-Holiday added for ${DateFormat('MMM dd, yyyy').format(date)}');
    }

    setState(() {
      selectedDate = date;
    });

    // Optional: Save selected date to database
    // await habitDatabase.saveSelectedDate(date);

    // Reload holiday dates to update the UI
    await _loadHolidayDates();
  }

  void _showCustomSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use the currentDisplayedMonth instead of current date
    final DateTime displayedMonth = widget.currentDisplayedMonth;

    // Calculate first day of displayed month
    final DateTime firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month, displayedMonth.day - 7);

    // Calculate last day of displayed month
    final DateTime lastDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month + 2);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HeatMap(
              startDate: firstDayOfMonth,
              endDate: lastDayOfMonth,
              datasets: _getModifiedDatasets(),
              colorMode: ColorMode.color,
              defaultColor: Theme.of(context).colorScheme.secondary,
              textColor: Theme.of(context).colorScheme.inverseSurface,
              showText: true,
              scrollable: true,
              showColorTip: false,
              size: 30,
              colorsets: _generateDynamicColorsets(_getModifiedDatasets()),
              onClick: _onDateTapped,
            ),
            const SizedBox(height: 8),
            //_buildHeatmapLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF56D364).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            const Text('Less'),
            const SizedBox(width: 16),

            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF56D364).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            const Text('Normal'),
            const SizedBox(width: 16),

            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF56D364),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            const Text('More'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.purple.shade500,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            const Text('Public-Holiday'),
          ],
        ),
      ],
    );
  }
}
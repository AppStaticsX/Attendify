import 'package:flutter/material.dart';
import 'package:attendify/components/analytics_heatmap.dart';
import 'package:attendify/database/event_database.dart';
import 'package:attendify/models/event.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'ANALYTICS',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: FutureBuilder(
          future: context.watch<HabitDatabase>().getFirstLaunchDate(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final startDate = snapshot.data!;
            return _buildHabitsList(startDate);
          }),
    );
  }

  Widget _buildHabitsList(DateTime startDate) {
    final habitDatabase = context.watch<HabitDatabase>();
    List<Habit> currentHabits = habitDatabase.currentHabits;

    if (currentHabits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /*SvgPicture.asset(
                'assets/icon/chart-21-svgrepo-com.svg',
                height: 120,
                width: 120),*/
            Icon(Iconsax.chart_21_copy, size: 120, color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No events to analyze yet',
              style: TextStyle(
                fontSize: 18,
                color: Theme
                    .of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
            Text(
              'Add events to see analytics',
              style: TextStyle(
                fontSize: 14,
                color: Theme
                    .of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    } else if (currentHabits.isNotEmpty && DateTime.now().millisecondsSinceEpoch > startDate.millisecondsSinceEpoch) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /*SvgPicture.asset(
                'assets/icon/chart-21-svgrepo-com.svg',
                height: 120,
                width: 120),*/
            Icon(Iconsax.warning_2_copy, size: 120, color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'Analytics Not Available',
              style: TextStyle(
                fontSize: 18,
                color: Theme
                    .of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
            Text(
              'Analytics not available until schedule start.',
              style: TextStyle(
                fontSize: 14,
                color: Theme
                    .of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currentHabits.length,
      itemBuilder: (context, index) {
        final habit = currentHabits[index];
        return _buildHabitHeatmapCard(habit, startDate);
      },
    );
  }

  Widget _buildHabitHeatmapCard(Habit habit, DateTime startDate) {
    Map<DateTime, int> habitData = {};

    if (habit.completedDays != null) {
      for (var day in habit.completedDays!) {
        DateTime dateKey = DateTime(day.date.year, day.date.month, day.date.day);
        habitData[dateKey] = 1;
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Lottie.asset(
                  'assets/lottie/streaks-anim.json',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Completed ${habit.completedDays?.length ?? 0} times',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Assigned days: ${habit.assignedDays.join(", ")}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AnalyticsHeatmap(
              datasets: habitData,
              startDate: startDate,
              totalHabits: 1,
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 16),
            _buildDayWiseCompletion(habit),
          ],
        ),
      ),
    );
  }

  Widget _buildDayWiseCompletion(Habit habit) {
    return FutureBuilder<Map<String, Map<String, int>>>(
      future: _calculateDayWiseCompletion(habit),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final completionStats = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Day-wise Completion Rate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...completionStats.entries.map((entry) {
              final dayName = entry.key;
              final stats = entry.value;
              final percentage = stats['completed'] == 0 ? 0.0 :
              (stats['completed']! / stats['total']!) * 100;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${stats['completed']}/${stats['total']} (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(percentage),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.amber;
    return Colors.red;
  }

  Future<Map<String, Map<String, int>>> _calculateDayWiseCompletion(Habit habit) async {
    final habitDatabase = context.read<HabitDatabase>();
    final holidays = await habitDatabase.getHolidays();
    final holidaySet = holidays.map((date) => DateTime(date.year, date.month, date.day)).toSet();
    final notConductedSet = (habit.notConductedDays ?? [])
        .map((day) => DateTime(day.date.year, day.date.month, day.date.day))
        .toSet();

    final prefs = await SharedPreferences.getInstance();
    final int? storedMillis = prefs.getInt('schedule_start_date');

    // Start date is 2025/06/01
    final startDate = DateTime.fromMillisecondsSinceEpoch(storedMillis!);
    final currentDate = DateTime.now();

    // Initialize counters for each day
    Map<String, Map<String, int>> dayStats = {
      'Monday': {'total': 0, 'completed': 0},
      'Tuesday': {'total': 0, 'completed': 0},
      'Wednesday': {'total': 0, 'completed': 0},
      'Thursday': {'total': 0, 'completed': 0},
      'Friday': {'total': 0, 'completed': 0},
      'Saturday': {'total': 0, 'completed': 0},
      'Sunday': {'total': 0, 'completed': 0},
    };

    // Count total occurrences of each day from startDate to currentDate
    DateTime iterDate = startDate;
    while (iterDate.isBefore(currentDate) || iterDate.isAtSameMomentAs(currentDate)) {
      final normalizedIterDate = DateTime(iterDate.year, iterDate.month, iterDate.day);
      final weekday = DateFormat('EEEE').format(iterDate);

      // Only count if this day is assigned to the habit AND it's not a holiday AND not marked as not conducted
      if (habit.assignedDays.contains(weekday) &&
          !holidaySet.contains(normalizedIterDate) &&
          !notConductedSet.contains(normalizedIterDate)) {
        dayStats[weekday]!['total'] = dayStats[weekday]!['total']! + 1;
      }

      iterDate = iterDate.add(const Duration(days: 1));
    }

    // Count completed days for each weekday
    if (habit.completedDays != null) {
      for (var completedDay in habit.completedDays!) {
        final normalizedCompletedDate = DateTime(completedDay.date.year, completedDay.date.month, completedDay.date.day);
        final weekday = DateFormat('EEEE').format(completedDay.date);

        // Only count if this day is assigned to the habit, within our date range, and not a holiday
        if (habit.assignedDays.contains(weekday) &&
            completedDay.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            completedDay.date.isBefore(currentDate.add(const Duration(days: 1))) &&
            !holidaySet.contains(normalizedCompletedDate) &&
            !notConductedSet.contains(normalizedCompletedDate)) {
          dayStats[weekday]!['completed'] = dayStats[weekday]!['completed']! + 1;
        }
      }
    }

    // Filter out days that are not assigned to this habit
    Map<String, Map<String, int>> filteredStats = {};
    for (var entry in dayStats.entries) {
      if (habit.assignedDays.contains(entry.key)) {
        filteredStats[entry.key] = entry.value;
      }
    }

    return filteredStats;
  }

  /*Widget _buildStreakInfo(Habit habit) {
    return FutureBuilder<int>(
      future: _calculateCurrentStreak(habit),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        int currentStreak = snapshot.data!;
        int longestStreak = _calculateLongestStreak(habit);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStreakCard(
              'Current',
              '$currentStreak days',
              Icons.local_fire_department,
              Colors.orange,
            ),
            _buildStreakCard(
              'Longest',
              '$longestStreak days',
              Icons.emoji_events,
              Colors.amber,
            ),
          ],
        );
      },
    );
  }*/

  /*Widget _buildStreakCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }*/

  /*Future<int> _calculateCurrentStreak(Habit habit) async {
    final habitDatabase = context.read<HabitDatabase>();
    final holidays = await habitDatabase.getHolidays();
    final holidaySet = holidays.map((date) => DateTime(date.year, date.month, date.day)).toSet();
    final notConductedSet = (habit.notConductedDays ?? [])
        .map((day) => DateTime(day.date.year, day.date.month, day.date.day))
        .toSet();

    if (habit.completedDays == null || habit.completedDays!.isEmpty || habit.assignedDays.isEmpty) {
      return 0;
    }

    final completedDays = habit.completedDays!.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final today = DateTime.now();
    final todayWeekday = DateFormat('EEEE').format(today);
    final normalizedToday = DateTime(today.year, today.month, today.day);

    if (!habit.assignedDays.contains(todayWeekday) ||
        holidaySet.contains(normalizedToday) ||
        notConductedSet.contains(normalizedToday)) {
      return 0;
    }

    bool hasToday = completedDays.any((day) =>
    day.date.year == today.year &&
        day.date.month == today.month &&
        day.date.day == today.day);

    int streak = hasToday ? 1 : 0;
    DateTime currentDate = normalizedToday.subtract(const Duration(days: 1));

    while (true) {
      final normalizedCurrentDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
      final currentWeekday = DateFormat('EEEE').format(currentDate);

      // Skip holidays and not conducted days
      if (holidaySet.contains(normalizedCurrentDate) ||
          notConductedSet.contains(normalizedCurrentDate)) {
        currentDate = currentDate.subtract(const Duration(days: 1));
        continue;
      }

      if (!habit.assignedDays.contains(currentWeekday)) {
        currentDate = currentDate.subtract(const Duration(days: 1));
        continue;
      }

      bool hasDate = completedDays.any((day) =>
      day.date.year == currentDate.year &&
          day.date.month == currentDate.month &&
          day.date.day == currentDate.day);

      if (!hasDate) break;

      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _calculateLongestStreak(Habit habit) {
    if (habit.completedDays == null || habit.completedDays!.isEmpty || habit.assignedDays.isEmpty) {
      return 0;
    }

    final completedDays = habit.completedDays!.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    int longestStreak = 1;
    int currentStreak = 1;
    DateTime? prevDate;

    for (var day in completedDays) {
      final currentWeekday = DateFormat('EEEE').format(day.date);
      if (!habit.assignedDays.contains(currentWeekday)) {
        continue;
      }

      if (prevDate == null) {
        prevDate = day.date;
        currentStreak = 1;
        continue;
      }

      final difference = day.date.difference(prevDate).inDays;
      if (difference == 7) {
        currentStreak++;
        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      } else {
        currentStreak = 1;
      }
      prevDate = day.date;
    }

    return longestStreak;
  }*/
}
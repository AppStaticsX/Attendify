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

  bool isSearchOpened = false;
  TextEditingController searchController = TextEditingController();
  List<Event> filteredEvents = [];

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      // This will trigger a rebuild and filter the events
    });
  }

  void _toggleSearch() {
    setState(() {
      isSearchOpened = !isSearchOpened;
      if (!isSearchOpened) {
        searchController.clear();
      }
    });
  }

  List<Event> _filterEvents(List<Event> events) {
    if (searchController.text.isEmpty) {
      return events;
    }

    final query = searchController.text.toLowerCase();
    return events.where((event) {
      // Filter by event name
      final nameMatch = event.name.toLowerCase().contains(query);
      return nameMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: isSearchOpened? TextField(
          controller: searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search events...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
          cursorColor: Theme.of(context).colorScheme.primary,
        ) : const Text(
          'ANALYTICS',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Iconsax.arrow_left_2_copy)
        ),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(
              isSearchOpened ? Icons.close : Iconsax.search_normal_1_copy,
            ),
          )
        ],
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: FutureBuilder(
          future: context.watch<EventDatabase>().getFirstLaunchDate(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final startDate = snapshot.data!;
            return _buildEventsList(startDate);
          }
      ),
    );
  }

  Widget _buildEventsList(DateTime startDate) {
    final eventDatabase = context.watch<EventDatabase>();
    List<Event> currentEvents = eventDatabase.currentEvents;

    // Apply search filter
    List<Event> displayEvents = _filterEvents(currentEvents);

    if (currentEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
    } else if (currentEvents.isNotEmpty && DateTime.now().millisecondsSinceEpoch < startDate.millisecondsSinceEpoch) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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

    // Show "no results" message when search returns empty results
    if (displayEvents.isEmpty && searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.search_normal_1_copy,
              size: 120,
              color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayEvents.length,
      itemBuilder: (context, index) {
        final event = displayEvents[index]; // Fixed: changed from 'habit' to 'event'
        return _buildEventHeatmapCard(event, startDate);
      },
    );
  }

  Widget _buildEventHeatmapCard(Event event, DateTime startDate) {
    Map<DateTime, int> eventData = {};

    if (event.completedDays != null) {
      for (var day in event.completedDays!) {
        DateTime dateKey = DateTime(day.date.year, day.date.month, day.date.day);
        eventData[dateKey] = 1;
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
                        event.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Completed ${event.completedDays?.length ?? 0} times',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Assigned days: ${event.assignedDays.join(", ")}',
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
              datasets: eventData,
              startDate: startDate,
              totalEvents: 1,
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 16),
            _buildDayWiseCompletion(event),
          ],
        ),
      ),
    );
  }

  Widget _buildDayWiseCompletion(Event event) {
    bool isPercentageError = false;

    return FutureBuilder<Map<String, Map<String, int>>>(
      future: _calculateDayWiseCompletion(event),
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                          stats['completed']! >= 0 && stats['total'] == 0?
                          Text(
                            'An Error Occurred!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ) : Text(
                            '${stats['completed']}/${stats['total']} (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
            }),
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

  Future<Map<String, Map<String, int>>> _calculateDayWiseCompletion(Event event) async {
    final eventDatabase = context.read<EventDatabase>();
    final holidays = await eventDatabase.getHolidays();
    final holidaySet = holidays.map((date) => DateTime(date.year, date.month, date.day)).toSet();
    final notConductedSet = (event.notConductedDays ?? [])
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
      if (event.assignedDays.contains(weekday) &&
          !holidaySet.contains(normalizedIterDate) &&
          !notConductedSet.contains(normalizedIterDate)) {
        dayStats[weekday]!['total'] = dayStats[weekday]!['total']! + 1;
      }

      iterDate = iterDate.add(const Duration(days: 1));
    }

    // Count completed days for each weekday
    if (event.completedDays != null) {
      for (var completedDay in event.completedDays!) {
        final normalizedCompletedDate = DateTime(completedDay.date.year, completedDay.date.month, completedDay.date.day);
        final weekday = DateFormat('EEEE').format(completedDay.date);

        // Only count if this day is assigned to the habit, within our date range, and not a holiday
        if (event.assignedDays.contains(weekday) &&
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
      if (event.assignedDays.contains(entry.key)) {
        filteredStats[entry.key] = entry.value;
      }
    }

    return filteredStats;
  }
}
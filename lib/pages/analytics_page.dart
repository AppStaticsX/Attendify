import 'package:flutter/material.dart';
import 'package:attendify/components/analytics_heatmap.dart';
import 'package:attendify/database/event_database.dart';
import 'package:attendify/models/event.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:attendify/util/attendance_calculator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/event_util.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {

  bool isSearchOpened = false;
  TextEditingController searchController = TextEditingController();
  List<Event> filteredEvents = [];
  int? _expandedCardIndex;

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

  void _toggleExpand(int index) { // or (String eventId)
    setState(() {
      _expandedCardIndex = _expandedCardIndex == index ? null : index;
      // This toggles: if already expanded, collapse it; otherwise expand it
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
        final event = displayEvents[index];
        return AnimatedEventCard(
          event: event,
          startDate: startDate,
          index: index,
          isExpanded: _expandedCardIndex == index,
          onToggleExpand: () => _toggleExpand(index),
        );
      },
    );
  }

  Color _getStatusColor(Event event) {
    final status = AttendanceCalculator.getAttendanceStatus(event);
    switch (status) {
      case 'safe':
        return const Color(0xFF4CAF50); // Green
      case 'warning':
        return const Color(0xFFFFA726); // Orange
      case 'danger':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  Future<Map<String, Map<String, int>>> _calculateDayWiseCompletion(Event event) async {
    final eventDatabase = context.read<EventDatabase>();
    final holidays = await eventDatabase.getHolidays();
    final holidaySet = holidays.map((date) => DateTime(date.year, date.month, date.day)).toSet();
    final notConductedSet = (event.notConductedDays ?? [])
        .map((day) => DateTime(day.date.year, day.date.month, day.date.day))
        .toSet();
    final cancelledSet = (event.cancelledDays ?? [])
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

      // Only count if this day is assigned to the lecture AND it's not a holiday AND not marked as not conducted AND not cancelled
      if (event.assignedDays.contains(weekday) &&
          !holidaySet.contains(normalizedIterDate) &&
          !notConductedSet.contains(normalizedIterDate) &&
          !cancelledSet.contains(normalizedIterDate)) {
        dayStats[weekday]!['total'] = dayStats[weekday]!['total']! + 1;
      }

      iterDate = iterDate.add(const Duration(days: 1));
    }

    // Count completed days for each weekday
    if (event.completedDays != null) {
      for (var completedDay in event.completedDays!) {
        final normalizedCompletedDate = DateTime(completedDay.date.year, completedDay.date.month, completedDay.date.day);
        final weekday = DateFormat('EEEE').format(completedDay.date);

        // Only count if this day is assigned to the lecture, within our date range, and not a holiday, not cancelled
        if (event.assignedDays.contains(weekday) &&
            completedDay.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            completedDay.date.isBefore(currentDate.add(const Duration(days: 1))) &&
            !holidaySet.contains(normalizedCompletedDate) &&
            !notConductedSet.contains(normalizedCompletedDate) &&
            !cancelledSet.contains(normalizedCompletedDate)) {
          dayStats[weekday]!['completed'] = dayStats[weekday]!['completed']! + 1;
        }
      }
    }

    // Filter out days that are not assigned to this lecture
    Map<String, Map<String, int>> filteredStats = {};
    for (var entry in dayStats.entries) {
      if (event.assignedDays.contains(entry.key)) {
        filteredStats[entry.key] = entry.value;
      }
    }

    return filteredStats;
  }
}

// New Animated Event Card Widget
class AnimatedEventCard extends StatefulWidget {
  final Event event;
  final DateTime startDate;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const AnimatedEventCard({
    super.key,
    required this.event,
    required this.startDate,
    required this.index,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  State<AnimatedEventCard> createState() => _AnimatedEventCardState();
}

class _AnimatedEventCardState extends State<AnimatedEventCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _previousPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateAnimation(double newPercentage) {
    if (_previousPercentage != newPercentage) {
      _animation = Tween<double>(
        begin: _previousPercentage,
        end: newPercentage,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      );
      _previousPercentage = newPercentage;
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNotConductedToday = isEventNotConductedToday(widget.event);
    final isAtRisk = AttendanceCalculator.isAtRisk(widget.event);

    Map<DateTime, int> eventData = {};

    if (widget.event.completedDays != null) {
      for (var day in widget.event.completedDays!) {
        DateTime dateKey = DateTime(day.date.year, day.date.month, day.date.day);
        eventData[dateKey] = 1;
      }
    }

    return FutureBuilder<List<int>>(
      future: Future.wait([
        AttendanceCalculator.calculateTotalLectureDaysForSemester(widget.event),
        AttendanceCalculator.calculateTotalLectureDaysToDate(widget.event),
      ]),
      builder: (context, snapshot) {
        // Use scheduled total if available, otherwise fallback to conducted lectures
        final scheduledTotal = snapshot.hasData
            ? snapshot.data![0]
            : AttendanceCalculator.getTotalConductedLectures(widget.event);
        final lecturesUpToToday = snapshot.hasData && snapshot.data != null
            ? snapshot.data![1]
            : AttendanceCalculator.getTotalConductedLectures(widget.event);

        final notConductedCount = AttendanceCalculator.getAbsentLecturesCount(widget.event);
        final totalCount = (scheduledTotal - notConductedCount);
        final attendedCount = AttendanceCalculator.getAttendedLecturesCount(widget.event);
        final remainingCount = totalCount - (lecturesUpToToday + notConductedCount);
        final absentCount = totalCount - remainingCount;

        final percentage = totalCount > 0
            ? ((scheduledTotal - absentCount + attendedCount) / totalCount * 100)
            : 0.0;

        // Update animation when percentage changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateAnimation(percentage);
        });

        final minRequired = widget.event.minAttendanceRequired;
        Color statusColor;

        if (percentage >= minRequired) {
          statusColor = const Color(0xFF4CAF50); // Green - Safe
        } else if (percentage >= minRequired - 10) {
          statusColor = const Color(0xFFFFA726); // Orange - Warning
        } else {
          statusColor = const Color(0xFFF44336); // Red - Danger
        }

        final isAtRisk = percentage < minRequired;

        return Card(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Opacity(
                    opacity: isNotConductedToday ? 0.5 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Animated Attendance Percentage Circle
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              final animatedPercentage = _animation.value;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: CircularProgressIndicator(
                                      value: animatedPercentage / 100,
                                      strokeWidth: 5,
                                      backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${animatedPercentage.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                      Text(
                                        '$attendedCount/$totalCount',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(width: 16),

                          // Course Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (widget.event.courseCode.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          widget.event.courseCode,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (isAtRisk)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Iconsax.warning_2_copy,
                                              size: 11,
                                              color: statusColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'LOW',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.event.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isNotConductedToday
                                        ? Colors.grey
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Iconsax.user_copy,
                                      size: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.event.conductorName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isNotConductedToday
                                              ? Colors.grey.withValues(alpha: 0.7)
                                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.event.lectureTime.isNotEmpty || widget.event.location.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (widget.event.lectureTime.isNotEmpty) ...[
                                        Icon(
                                          Iconsax.clock_copy,
                                          size: 11,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.event.lectureTime,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                      /*if (widget.event.lectureTime.isNotEmpty && widget.event.location.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Text(
                                            '•',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ),
                                      if (widget.event.location.isNotEmpty) ...[
                                        Icon(
                                          Iconsax.location_copy,
                                          size: 11,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            widget.event.location,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],*/
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: widget.onToggleExpand,
                            icon: Icon(widget.isExpanded ? Iconsax.arrow_up_2_copy : Iconsax.arrow_down_1_copy),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.isExpanded) ...[
                  AnalyticsHeatmap(
                    datasets: eventData,
                    startDate: widget.startDate,
                    totalEvents: 1,
                  ),
                  const SizedBox(height: 8),
                  //const SizedBox(height: 16),
                  //_buildDayWiseCompletion(widget.event, context),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayWiseCompletion(Event event, BuildContext context) {
    return FutureBuilder<Map<String, Map<String, int>>>(
      future: _calculateDayWiseCompletion(event, context),
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
              final percentage = stats['total'] == 0 ? 0.0 :
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
                          Text(
                            stats['total'] == 0
                                ? 'No Data Found'
                                : '${stats['completed']}/${stats['total']} (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: stats['total'] == 0 ? 0 : percentage / 100,
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

  Future<Map<String, Map<String, int>>> _calculateDayWiseCompletion(Event event, BuildContext context) async {
    final eventDatabase = context.read<EventDatabase>();
    final holidays = await eventDatabase.getHolidays();
    final holidaySet = holidays.map((date) => DateTime(date.year, date.month, date.day)).toSet();
    final notConductedSet = (event.notConductedDays ?? [])
        .map((day) => DateTime(day.date.year, day.date.month, day.date.day))
        .toSet();
    final cancelledSet = (event.cancelledDays ?? [])
        .map((day) => DateTime(day.date.year, day.date.month, day.date.day))
        .toSet();

    final prefs = await SharedPreferences.getInstance();
    final int? storedMillis = prefs.getInt('schedule_start_date');

    final startDate = DateTime.fromMillisecondsSinceEpoch(storedMillis!);
    final currentDate = DateTime.now();

    Map<String, Map<String, int>> dayStats = {
      'Monday': {'total': 0, 'completed': 0},
      'Tuesday': {'total': 0, 'completed': 0},
      'Wednesday': {'total': 0, 'completed': 0},
      'Thursday': {'total': 0, 'completed': 0},
      'Friday': {'total': 0, 'completed': 0},
      'Saturday': {'total': 0, 'completed': 0},
      'Sunday': {'total': 0, 'completed': 0},
    };

    DateTime iterDate = startDate;
    while (iterDate.isBefore(currentDate) || iterDate.isAtSameMomentAs(currentDate)) {
      final normalizedIterDate = DateTime(iterDate.year, iterDate.month, iterDate.day);
      final weekday = DateFormat('EEEE').format(iterDate);

      if (event.assignedDays.contains(weekday) &&
          !holidaySet.contains(normalizedIterDate) &&
          !notConductedSet.contains(normalizedIterDate) &&
          !cancelledSet.contains(normalizedIterDate)) {
        dayStats[weekday]!['total'] = dayStats[weekday]!['total']! + 1;
      }

      iterDate = iterDate.add(const Duration(days: 1));
    }

    if (event.completedDays != null) {
      for (var completedDay in event.completedDays!) {
        final normalizedCompletedDate = DateTime(completedDay.date.year, completedDay.date.month, completedDay.date.day);
        final weekday = DateFormat('EEEE').format(completedDay.date);

        if (event.assignedDays.contains(weekday) &&
            completedDay.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            completedDay.date.isBefore(currentDate.add(const Duration(days: 1))) &&
            !holidaySet.contains(normalizedCompletedDate) &&
            !notConductedSet.contains(normalizedCompletedDate) &&
            !cancelledSet.contains(normalizedCompletedDate)) {
          dayStats[weekday]!['completed'] = dayStats[weekday]!['completed']! + 1;
        }
      }
    }

    Map<String, Map<String, int>> filteredStats = {};
    for (var entry in dayStats.entries) {
      if (event.assignedDays.contains(entry.key)) {
        filteredStats[entry.key] = entry.value;
      }
    }

    return filteredStats;
  }
}

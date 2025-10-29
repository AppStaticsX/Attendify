import 'package:flutter/material.dart';
import 'package:attendify/models/event.dart';
import 'package:attendify/util/attendance_calculator.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Today's Lectures section showing only courses scheduled for today
class TodayLecturesSection extends StatelessWidget {
  final List<Event> todayEvents;
  final Function(bool?, Event) onCheckboxChanged;

  const TodayLecturesSection({
    super.key,
    required this.todayEvents,
    required this.onCheckboxChanged,
  });

  String _getNextLectureTime(List<Event> events) {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    Event? nextEvent;
    int? nextEventMinutes;

    for (var event in events) {
      if (event.lectureTime.isEmpty) continue;

      // Parse start time from "9:00 AM - 10:30 AM" format
      final timeParts = event.lectureTime.split('-');
      if (timeParts.isEmpty) continue;

      final startTime = timeParts[0].trim();
      final timeMatch = RegExp(r'(\d+):(\d+)\s*(AM|PM)').firstMatch(startTime);

      if (timeMatch != null) {
        int hour = int.parse(timeMatch.group(1)!);
        int minute = int.parse(timeMatch.group(2)!);
        final period = timeMatch.group(3);

        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;

        final eventMinutes = hour * 60 + minute;

        if (eventMinutes > nowMinutes) {
          if (nextEventMinutes == null || eventMinutes < nextEventMinutes) {
            nextEventMinutes = eventMinutes;
            nextEvent = event;
          }
        }
      }
    }

    if (nextEvent != null) {
      final diff = nextEventMinutes! - nowMinutes;
      final hours = diff ~/ 60;
      final minutes = diff % 60;

      if (hours > 0) {
        return 'Next lecture in ${hours}h ${minutes}m';
      } else {
        return 'Next lecture in ${minutes}m';
      }
    }

    return 'No more lectures today';
  }

  @override
  Widget build(BuildContext context) {
    if (todayEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort events by time
    final sortedEvents = List<Event>.from(todayEvents)..sort((a, b) {
      if (a.lectureTime.isEmpty) return 1;
      if (b.lectureTime.isEmpty) return -1;
      return a.lectureTime.compareTo(b.lectureTime);
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Iconsax.calendar_1_copy,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Lectures",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      Text(
                        _getNextLectureTime(sortedEvents),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${sortedEvents.length} ${sortedEvents.length == 1 ? 'lecture' : 'lectures'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Today's Lecture Cards
          ...sortedEvents.map((event) => _buildTodayLectureCard(context, event)),
        ],
      ),
    );
  }

  Widget _buildTodayLectureCard(BuildContext context, Event event) {
    final percentage = AttendanceCalculator.calculateAttendancePercentage(event);
    final isCompleted = isEventCompletedToday(event);
    final statusColor = Color(AttendanceCalculator.getStatusColor(event));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Time
          if (event.lectureTime.isNotEmpty)
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(
                    Iconsax.clock_copy,
                    size: 16,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.lectureTime.split('-')[0].trim(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),

          // Course Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (event.courseCode.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.courseCode,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        event.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.inversePrimary,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Iconsax.user_copy,
                      size: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.conductorName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    if (event.location.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Iconsax.location_copy,
                        size: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.location,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Attendance %
          Column(
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: isCompleted,
                  activeColor: statusColor,
                  onChanged: (value) => onCheckboxChanged(value, event),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool isEventCompletedToday(Event event) {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    return event.completedDays?.any((day) {
          final dayNormalized = DateTime(day.date.year, day.date.month, day.date.day);
          return dayNormalized == todayNormalized;
        }) ??
        false;
  }
}

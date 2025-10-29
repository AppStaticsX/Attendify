import 'package:flutter/material.dart';
import 'package:attendify/models/event.dart';
import 'package:attendify/util/attendance_calculator.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Quick stats widget showing overall attendance statistics
class QuickStatsCard extends StatelessWidget {
  final List<Event> events;

  const QuickStatsCard({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    // Calculate overall statistics
    int totalCourses = events.length;
    double averageAttendance = 0.0;
    int coursesAtRisk = 0;
    int totalAttended = 0;
    int totalConducted = 0;

    if (events.isNotEmpty) {
      double totalPercentage = 0.0;
      for (var event in events) {
        final percentage = AttendanceCalculator.calculateAttendancePercentage(event);
        totalPercentage += percentage;

        if (AttendanceCalculator.isAtRisk(event)) {
          coursesAtRisk++;
        }

        totalAttended += AttendanceCalculator.getAttendedLecturesCount(event);
        totalConducted += AttendanceCalculator.getTotalConductedLectures(event);
      }
      averageAttendance = totalPercentage / events.length;
    }

    Color averageColor = averageAttendance >= 75
        ? const Color(0xFF4CAF50)
        : averageAttendance >= 65
            ? const Color(0xFFFFA726)
            : const Color(0xFFF44336);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Iconsax.chart_21_copy,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Overall Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Iconsax.book_1_copy,
                  label: 'Total Courses',
                  value: totalCourses.toString(),
                  color: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Iconsax.percentage_circle_copy,
                  label: 'Avg. Attendance',
                  value: '${averageAttendance.toStringAsFixed(1)}%',
                  color: averageColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Iconsax.tick_circle_copy,
                  label: 'Attended',
                  value: '$totalAttended/$totalConducted',
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Iconsax.warning_2_copy,
                  label: 'At Risk',
                  value: coursesAtRisk.toString(),
                  color: coursesAtRisk > 0 ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


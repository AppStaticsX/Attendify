import 'package:flutter/material.dart';
import 'heatmap_calendar/src/data/heatmap_color_mode.dart';
import 'heatmap_calendar/src/heatmap_calendar.dart';

class AnalyticsHeatmap extends StatelessWidget {
  final Map<DateTime, int> datasets;
  final DateTime startDate;
  final int totalEvents; // Added total number of Events

  const AnalyticsHeatmap({
    super.key,
    required this.datasets,
    required this.startDate,
    required this.totalEvents, // Required parameter for total Events
  });

  // Generate dynamic colorsets based on the total number of Events
  Map<int, Color> _generateDynamicColorsets(Map<DateTime, int> datasets) {
    Map<int, Color> colorsets = {};

    // Find the maximum completed Events in a day
    int maxValue = datasets.values.isEmpty ? totalEvents : datasets.values.reduce((max, value) => max > value ? max : value);
    maxValue = maxValue > 0 ? maxValue : totalEvents;

    // Create color gradient based on the number of Events
    for (int i = 1; i <= totalEvents; i++) {
      // Calculate opacity percentage based on completed Events ratio
      double opacityPercentage = i / totalEvents;

      // Create a color with varying intensity based on completion ratio
      // Using shade variants for better visibility
      if (opacityPercentage == 1) {
        colorsets[i] = Colors.green.shade600;
      }
    }

    return colorsets;
  }

  @override
  Widget build(BuildContext context) {
    // Get current date
    final DateTime now = DateTime.now();

    // Calculate first day of current month
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, now.day);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HeatMapCalendar(
              initDate: firstDayOfMonth,  // Start from first day of current month
              datasets: datasets,
              colorMode: ColorMode.color,
              defaultColor: Theme.of(context).colorScheme.secondary,
              textColor: Theme.of(context).colorScheme.inverseSurface,
              showColorTip: false,
              size: 34,
              colorsets: _generateDynamicColorsets(datasets),
            ),
          ],
        ),
      ),
    );
  }
}
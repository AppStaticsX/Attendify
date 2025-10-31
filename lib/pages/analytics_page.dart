import 'package:flutter/material.dart';
import 'package:attendify/database/event_database.dart';
import 'package:attendify/models/event.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool isBarChart = true; // true for bar chart, false for line chart

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Analytics',
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Iconsax.arrow_left_2_copy),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: false,
      ),
      body: FutureBuilder(
        future: context.watch<EventDatabase>().getFirstLaunchDate(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final startDate = snapshot.data!;
          return _buildAnalyticsView(startDate);
        },
      ),
    );
  }

  Widget _buildAnalyticsView(DateTime startDate) {
    final eventDatabase = context.watch<EventDatabase>();
    List<Event> currentEvents = eventDatabase.currentEvents;

    if (currentEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.chart_21_copy,
              size: 120,
              color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No events to analyze yet',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              'Add events to see analytics',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateOverallAnalytics(currentEvents, startDate, context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final analytics = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 12),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(16)
                ),
                child: Column(
                  children: [
                    _buildWeeklyProgress(analytics),
                    //const SizedBox(height: 24),
                    _buildWeeklyChart(analytics),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 4),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(16)
                  ),
                  child: _buildStatsRow(analytics)),
              const SizedBox(height: 24),
              Container(
                  padding: EdgeInsets.only(left: 12, right: 12, bottom: 4),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(16)
                  ),
                  child: _buildEventsProgress(analytics)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyProgress(Map<String, dynamic> analytics) {
    final currentWeekProgress = analytics['currentWeekProgress'] as double;
    final lastWeekProgress = analytics['lastWeekProgress'] as double;
    final difference = currentWeekProgress - lastWeekProgress;
    final isIncreasing = difference >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.chart_copy,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Icon(
                isIncreasing ? Iconsax.arrow_up_3_copy : Iconsax.arrow_down_copy,
                size: 16,
                color: isIncreasing ? Colors.green : Colors.red,
              ),
              //const SizedBox(width: 4),
              Text(
                '${difference.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isIncreasing ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This week',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    //const SizedBox(height: 4),
                    Text(
                      '${currentWeekProgress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last week',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lastWeekProgress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: currentWeekProgress / 100,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyProgress(Map<String, dynamic> analytics) {
    final currentMonthProgress = analytics['currentMonthProgress'] as double;
    final lastMonthProgress = analytics['lastMonthProgress'] as double;
    final difference = currentMonthProgress - lastMonthProgress;
    final isIncreasing = difference >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.chart_copy,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Monthly Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Icon(
                isIncreasing ? Iconsax.arrow_up_3_copy : Iconsax.arrow_down_copy,
                size: 16,
                color: isIncreasing ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                '${difference.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isIncreasing ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This month',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentMonthProgress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last month',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lastMonthProgress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(Map<String, dynamic> analytics) {
    final weeklyData = analytics['weeklyData'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => isBarChart = !isBarChart),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isBarChart ? Iconsax.chart_copy : Iconsax.chart_21_copy,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isBarChart ? 'Line' : 'Bar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: isBarChart
                ? _buildBarChart(weeklyData)
                : _buildLineChart(weeklyData),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> weeklyData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: weeklyData.map((day) {
        final percentage = day['percentage'] as double;
        final dayName = day['day'] as String;
        final isToday = day['isToday'] as bool;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (percentage > 0)
                  Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(percentage),
                    ),
                  ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: percentage > 0
                          ? _getProgressColor(percentage)
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> weeklyData) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < weeklyData.length) {
                  final day = weeklyData[index];
                  final dayName = day['day'] as String;
                  final isToday = day['isToday'] as bool;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (weeklyData.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: weeklyData.asMap().entries.map((entry) {
              final percentage = entry.value['percentage'] as double;
              return FlSpot(entry.key.toDouble(), percentage);
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final percentage = spot.y;
                return FlDotCirclePainter(
                  radius: 4,
                  color: _getProgressColor(percentage),
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> analytics) {
    final consistency = analytics['consistency'] as double;
    final streak = analytics['currentStreak'] as int;
    final bestStreak = analytics['bestStreak'] as int;
    final totalCompleted = analytics['totalCompleted'] as int;
    final totalExpected = analytics['totalExpected'] as int;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.flash_1,
            title: 'Consistency',
            value: '${consistency.toStringAsFixed(0)}%',
            subtitle: '$totalCompleted/$totalExpected lectures',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.cup,
            title: 'Streak',
            value: '$streak days',
            subtitle: 'Best: $bestStreak days',
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsProgress(Map<String, dynamic> analytics) {
    final eventsProgress = analytics['eventsProgress'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.book_1_copy,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Lectures',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Completion by lecture (this month)',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          ...eventsProgress.map((event) {
            final name = event['name'] as String;
            final courseCode = event['courseCode'] as String? ?? '';
            final conductorName = event['conductorName'] as String? ?? '';
            final assignedDays = (event['assignedDays'] as List?)?.map((e) => e.toString()).toList() ?? [];
            final percentage = event['percentage'] as double;
            final completed = event['completed'] as int;
            final total = event['total'] as int;
            final dailyProgress = event['dailyProgress'] as List<Map<String, dynamic>>? ?? [];



            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                if (courseCode.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Iconsax.code_1, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          courseCode,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.inverseSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                if (conductorName.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Iconsax.user, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          conductorName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.inverseSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (assignedDays.toString().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Iconsax.calendar_1, size: 12, color: Colors.black,),
                                    const SizedBox(width: 4),
                                    Text(
                                      assignedDays.join(', '),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(percentage),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: _buildProgressLineChart(dailyProgress, _getProgressColor(percentage), context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completed/$total completed',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildProgressLineChart(List<Map<String, dynamic>> dailyProgress, Color color, BuildContext context) {
    if (dailyProgress.isEmpty) {
      return Center(
        child: Text(
          'No data',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    // Convert daily progress to FlSpot points
    final List<FlSpot> spots = [];
    for (int i = 0; i < dailyProgress.length; i++) {
      final progress = dailyProgress[i]['progress'] as double;
      spots.add(FlSpot(i.toDouble(), progress));
    }

    // Calculate min and max values
    final maxX = (dailyProgress.length - 1).toDouble();
    final values = spots.map((e) => e.y).toList();
    final maxY = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 1.0;
    final minY = values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : 0.0;

    // Add padding to Y axis for better visualization
    final yRange = maxY - minY;
    final yPadding = yRange > 0 ? yRange * 0.15 : 0.1;
    final adjustedMaxY = (maxY + yPadding).clamp(0.0, 1.0);
    final adjustedMinY = (minY - yPadding).clamp(0.0, 1.0);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 5, // Show every 5 days
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= dailyProgress.length) {
                  return const SizedBox.shrink();
                }

                final index = value.toInt();
                final day = dailyProgress[index]['day'] as int;

                // Only show labels at intervals
                if (index % 5 != 0 && index != 0 && index != dailyProgress.length - 1) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: maxX,
        minY: adjustedMinY,
        maxY: adjustedMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.orange;
    if (percentage >= 20) return Colors.deepOrange;
    return Colors.red;
  }

  Future<Map<String, dynamic>> _calculateOverallAnalytics(
      List<Event> events,
      DateTime startDate,
      BuildContext context,
      ) async {
    final eventDatabase = context.read<EventDatabase>();
    final holidays = await eventDatabase.getHolidays();
    final holidaySet = holidays.map((date) => DateTime(date.year, date.month, date.day)).toSet();

    final now = DateTime.now();

    // Calculate week boundaries
    final currentWeekStart = now.subtract(Duration(days: 6));
    final lastWeekStart = now.subtract(Duration(days: 13));
    final lastWeekEnd = now.subtract(Duration(days: 7));

    int totalCompleted = 0;
    int totalExpected = 0;
    int currentWeekCompleted = 0;
    int currentWeekExpected = 0;
    int lastWeekCompleted = 0;
    int lastWeekExpected = 0;

    List<Map<String, dynamic>> eventsProgress = [];
    Map<int, Map<String, int>> weeklyStats = {};

    // Initialize weekly stats (last 7 days)
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      weeklyStats[day.weekday] = {'completed': 0, 'expected': 0};
    }

    for (var event in events) {
      final notConductedSet = (event.notConductedDays ?? [])
          .map((day) => DateTime(day.date.year, day.date.month, day.date.day))
          .toSet();
      final cancelledSet = (event.cancelledDays ?? [])
          .map((day) => DateTime(day.date.year, day.date.month, day.date.day))
          .toSet();

      int eventWeekCompleted = 0;
      int eventWeekExpected = 0;

      // Calculate for all time and current week
      DateTime iterDate = startDate;
      while (iterDate.isBefore(now) || iterDate.isAtSameMomentAs(now)) {
        final normalizedDate = DateTime(iterDate.year, iterDate.month, iterDate.day);
        final weekday = DateFormat('EEEE').format(iterDate);

        if (event.assignedDays.contains(weekday) &&
            !holidaySet.contains(normalizedDate) &&
            !notConductedSet.contains(normalizedDate) &&
            !cancelledSet.contains(normalizedDate)) {

          totalExpected++;

          // Current week (last 7 days)
          if (iterDate.isAfter(currentWeekStart.subtract(const Duration(days: 1))) &&
              iterDate.isBefore(now.add(const Duration(days: 1)))) {
            currentWeekExpected++;
            eventWeekExpected++;
          }

          // Last week (8-14 days ago)
          if (iterDate.isAfter(lastWeekStart.subtract(const Duration(days: 1))) &&
              iterDate.isBefore(lastWeekEnd.add(const Duration(days: 1)))) {
            lastWeekExpected++;
          }

          // Weekly stats (last 7 days)
          final daysDiff = now.difference(iterDate).inDays;
          if (daysDiff >= 0 && daysDiff < 7) {
            weeklyStats[iterDate.weekday]!['expected'] =
                weeklyStats[iterDate.weekday]!['expected']! + 1;
          }
        }

        iterDate = iterDate.add(const Duration(days: 1));
      }

      // Count completed
      if (event.completedDays != null) {
        for (var completedDay in event.completedDays!) {
          final normalizedDate = DateTime(
            completedDay.date.year,
            completedDay.date.month,
            completedDay.date.day,
          );
          final weekday = DateFormat('EEEE').format(completedDay.date);

          if (event.assignedDays.contains(weekday) &&
              completedDay.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              completedDay.date.isBefore(now.add(const Duration(days: 1))) &&
              !holidaySet.contains(normalizedDate) &&
              !notConductedSet.contains(normalizedDate) &&
              !cancelledSet.contains(normalizedDate)) {

            totalCompleted++;

            // Current week (last 7 days)
            if (completedDay.date.isAfter(currentWeekStart.subtract(const Duration(days: 1))) &&
                completedDay.date.isBefore(now.add(const Duration(days: 1)))) {
              currentWeekCompleted++;
              eventWeekCompleted++;
            }

            // Last week (8-14 days ago)
            if (completedDay.date.isAfter(lastWeekStart.subtract(const Duration(days: 1))) &&
                completedDay.date.isBefore(lastWeekEnd.add(const Duration(days: 1)))) {
              lastWeekCompleted++;
            }

            // Weekly stats
            final daysDiff = now.difference(completedDay.date).inDays;
            if (daysDiff >= 0 && daysDiff < 7) {
              weeklyStats[completedDay.date.weekday]!['completed'] =
                  weeklyStats[completedDay.date.weekday]!['completed']! + 1;
            }
          }
        }
      }

      // Calculate daily progress for this event (last 30 days for continuous line chart)
      List<Map<String, dynamic>> dailyProgress = [];
      DateTime checkDate = now.subtract(const Duration(days: 29)); // 30 days total
      int cumulativeCompleted = 0;
      int cumulativeExpected = 0;

      // First pass: calculate cumulative values for each day
      for (int dayIndex = 0; dayIndex < 30; dayIndex++) {
        final currentDate = checkDate.add(Duration(days: dayIndex));
        final normalizedDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
        final weekday = DateFormat('EEEE').format(currentDate);

        // Check if this is an expected day
        if (event.assignedDays.contains(weekday) &&
            !holidaySet.contains(normalizedDate) &&
            !notConductedSet.contains(normalizedDate) &&
            !cancelledSet.contains(normalizedDate) &&
            currentDate.isAfter(startDate.subtract(const Duration(days: 1)))) {
          cumulativeExpected++;

          // Check if completed
          if (event.completedDays != null) {
            for (var completedDay in event.completedDays!) {
              final completedNormalized = DateTime(
                completedDay.date.year,
                completedDay.date.month,
                completedDay.date.day,
              );
              if (completedNormalized == normalizedDate) {
                cumulativeCompleted++;
                break;
              }
            }
          }
        }

        // Add data point for every day (even non-lecture days)
        double progress = cumulativeExpected > 0
            ? (cumulativeCompleted / cumulativeExpected)
            : 0.0;

        dailyProgress.add({
          'day': dayIndex + 1,
          'progress': progress,
          'date': normalizedDate,
        });
      }

      // Add to events progress (weekly)
      double eventPercentage = eventWeekExpected > 0
          ? (eventWeekCompleted / eventWeekExpected) * 100
          : 0;

      eventsProgress.add({
        'name': event.name,
        'courseCode': event.courseCode,
        'conductorName': event.conductorName,
        'percentage': eventPercentage,
        'assignedDays': event.assignedDays,
        'completed': eventWeekCompleted,
        'total': eventWeekExpected,
        'dailyProgress': dailyProgress,
      });
    }

    // Calculate percentages
    double currentWeekProgress = currentWeekExpected > 0
        ? (currentWeekCompleted / currentWeekExpected) * 100
        : 0;
    double lastWeekProgress = lastWeekExpected > 0
        ? (lastWeekCompleted / lastWeekExpected) * 100
        : 0;
    double consistency = totalExpected > 0
        ? (totalCompleted / totalExpected) * 100
        : 0;

    // Calculate streaks
    final streakData = _calculateStreaks(events, startDate, holidaySet);

    // Prepare weekly data
    List<Map<String, dynamic>> weeklyData = [];
    final daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final stats = weeklyStats[day.weekday]!;
      final percentage = stats['expected']! > 0
          ? (stats['completed']! / stats['expected']!) * 100
          : 0.0;

      weeklyData.add({
        'day': daysOfWeek[day.weekday - 1],
        'percentage': percentage,
        'isToday': i == 6,
      });
    }

    return {
      'currentWeekProgress': currentWeekProgress,
      'lastWeekProgress': lastWeekProgress,
      'consistency': consistency,
      'currentStreak': streakData['current'],
      'bestStreak': streakData['best'],
      'totalCompleted': totalCompleted,
      'totalExpected': totalExpected,
      'weeklyData': weeklyData,
      'eventsProgress': eventsProgress,
    };
  }

  Map<String, int> _calculateStreaks(
      List<Event> events,
      DateTime startDate,
      Set<DateTime> holidaySet,
      ) {
    final now = DateTime.now();
    int currentStreak = 0;
    int bestStreak = 0;
    int tempStreak = 0;

    // Create a map of all expected days
    Set<DateTime> allExpectedDays = {};
    Set<DateTime> allCompletedDays = {};

    for (var event in events) {
      final notConductedSet = (event.notConductedDays ?? [])
          .map((day) => DateTime(day.date.year, day.date.month, day.date.day))
          .toSet();
      final cancelledSet = (event.cancelledDays ?? [])
          .map((day) => DateTime(day.date.year, day.date.month, day.date.day))
          .toSet();

      DateTime iterDate = startDate;
      while (iterDate.isBefore(now) || iterDate.isAtSameMomentAs(now)) {
        final normalizedDate = DateTime(iterDate.year, iterDate.month, iterDate.day);
        final weekday = DateFormat('EEEE').format(iterDate);

        if (event.assignedDays.contains(weekday) &&
            !holidaySet.contains(normalizedDate) &&
            !notConductedSet.contains(normalizedDate) &&
            !cancelledSet.contains(normalizedDate)) {
          allExpectedDays.add(normalizedDate);
        }

        iterDate = iterDate.add(const Duration(days: 1));
      }

      if (event.completedDays != null) {
        for (var completedDay in event.completedDays!) {
          final normalizedDate = DateTime(
            completedDay.date.year,
            completedDay.date.month,
            completedDay.date.day,
          );
          if (allExpectedDays.contains(normalizedDate)) {
            allCompletedDays.add(normalizedDate);
          }
        }
      }
    }

    // Calculate streaks by checking each day
    DateTime checkDate = startDate;
    while (checkDate.isBefore(now) || checkDate.isAtSameMomentAs(now)) {
      final normalizedDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

      if (allExpectedDays.contains(normalizedDate)) {
        if (allCompletedDays.contains(normalizedDate)) {
          tempStreak++;
          if (tempStreak > bestStreak) {
            bestStreak = tempStreak;
          }
        } else {
          tempStreak = 0;
        }
      }

      checkDate = checkDate.add(const Duration(days: 1));
    }

    // Calculate current streak (from today backwards)
    checkDate = now;
    while (checkDate.isAfter(startDate) || checkDate.isAtSameMomentAs(startDate)) {
      final normalizedDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

      if (allExpectedDays.contains(normalizedDate)) {
        if (allCompletedDays.contains(normalizedDate)) {
          currentStreak++;
        } else {
          break;
        }
      }

      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return {
      'current': currentStreak,
      'best': bestStreak,
    };
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:attendify/util/event_util.dart';
import 'package:attendify/util/attendance_calculator.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';

class EventTile extends StatefulWidget {
  final String eventName;
  final String conductorName;
  final bool isCompleted;
  final Event event;
  final void Function(bool?)? onChanged;
  final void Function(BuildContext)? editEvent;
  final void Function(BuildContext)? deleteEvent;
  final void Function(BuildContext)? markNotConducted;

  const EventTile({
    super.key,
    required this.eventName,
    required this.isCompleted,
    required this.event,
    required this.onChanged,
    required this.editEvent,
    required this.deleteEvent,
    required this.conductorName,
    this.markNotConducted,
  });

  @override
  State<EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<EventTile> with SingleTickerProviderStateMixin {
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

  void _showNotConductedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Not Conducted'),
        content: Text('Are you sure you want to mark "${widget.eventName}" as not conducted today? This action can\'t be undone.'),
        actions: [
          MaterialButton(
            onPressed: () {
              if (widget.markNotConducted != null) {
                widget.markNotConducted!(context);
              }
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
          MaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkIfTodayIsStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final int? startDateMillis = prefs.getInt('schedule_start_date');

    if (startDateMillis == null) return false;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    final startDate = DateTime.fromMillisecondsSinceEpoch(startDateMillis);
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    return normalizedToday.isAtSameMomentAs(normalizedStartDate);
  }

  @override
  Widget build(BuildContext context) {
    final bool isNotConductedToday = isEventNotConductedToday(widget.event);

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

        print('$notConductedCount');
        print('${((scheduledTotal - absentCount + attendedCount))}');
        // Update animation when percentage changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateAnimation(percentage);
        });

        // Get status color based on the ACTUAL calculated percentage and minimum required
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

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Slidable(
            enabled: !isNotConductedToday,
            endActionPane: ActionPane(
              motion: const StretchMotion(),
              children: [
                SlidableAction(
                  onPressed: isNotConductedToday ? null : widget.editEvent,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                  backgroundColor: Colors.grey.shade800,
                  label: 'Edit',
                  icon: Iconsax.edit_2,
                ),
                SlidableAction(
                  onPressed: isNotConductedToday ? null : widget.deleteEvent,
                  borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                  backgroundColor: Colors.red.shade800,
                  label: 'Delete',
                  icon: Iconsax.close_circle,
                ),
              ],
            ),
            child: GestureDetector(
              onTap: isNotConductedToday
                  ? null
                  : () {
                if (widget.onChanged != null) {
                  widget.onChanged!(!widget.isCompleted);
                }
              },
              onLongPress: isNotConductedToday ? null : () => _showNotConductedDialog(context),
              child: Opacity(
                opacity: isNotConductedToday ? 0.5 : 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isCompleted
                        ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)
                        : Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Attendance Percentage Circle with Animation
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
                            // Course Code and Name
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
                              widget.eventName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: widget.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                                color: isNotConductedToday
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Professor Name
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
                                    widget.conductorName,
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

                            // Time and Location
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
                                  if (widget.event.lectureTime.isNotEmpty && widget.event.location.isNotEmpty)
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
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Checkbox
                      Transform.scale(
                        scale: 1.1,
                        child: Checkbox(
                          value: widget.isCompleted,
                          activeColor: Colors.green,
                          onChanged: isNotConductedToday ? null : widget.onChanged,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

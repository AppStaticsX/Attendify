import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:attendify/util/habit_util.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../models/event.dart';

class EventTile extends StatelessWidget {
  final String eventName;
  final String conductorName;
  final bool isCompleted;
  final Event event;
  final void Function(bool?)? onChanged;
  final void Function(BuildContext)? editHabit;
  final void Function(BuildContext)? deleteHabit;
  final void Function(BuildContext)? markNotConducted;

  const EventTile({
    super.key,
    required this.eventName,
    required this.isCompleted,
    required this.event,
    required this.onChanged,
    required this.editHabit,
    required this.deleteHabit,
    required this.conductorName,
    this.markNotConducted,
  });

  void _showNotConductedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Not Conducted'),
        content: Text('Are you sure you want to mark "$eventName" as not conducted today? This action can\'t undone.'),
        actions: [
          MaterialButton(
            onPressed: () {
              if (markNotConducted != null) {
                markNotConducted!(context);
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

  @override
  Widget build(BuildContext context) {
    final bool isNotConductedToday = isHabitNotConductedToday(event);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Slidable(
        enabled: !isNotConductedToday, // Disable slidable actions if not conducted
        endActionPane: ActionPane(
          motion: StretchMotion(),
          children: [
            SlidableAction(
              onPressed: isNotConductedToday ? null : editHabit,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
              backgroundColor: Colors.grey.shade800,
              label: 'Edit',
              icon: Iconsax.edit_2,
            ),
            SlidableAction(
              onPressed: isNotConductedToday ? null : deleteHabit,
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
            if (onChanged != null) {
              onChanged!(!isCompleted);
            }
          },
          onLongPress: isNotConductedToday ? null : () => _showNotConductedDialog(context),
          child: Opacity(
            opacity: isNotConductedToday ? 0.5 : 1.0, // Grey out if not conducted
            child: Container(
              decoration: BoxDecoration(
                color: isCompleted
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                title: Text(
                  eventName,
                  style: TextStyle(
                    fontStyle: isCompleted ? FontStyle.italic : FontStyle.normal,
                    fontWeight: FontWeight.bold,
                    decoration:
                    isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    color: isNotConductedToday
                        ? Colors.grey
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  conductorName,
                  style: TextStyle(
                    color: isNotConductedToday
                        ? Colors.grey.withOpacity(0.7)
                        : Colors.grey,
                  ),
                ),
                leading: Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: isCompleted,
                    activeColor: Colors.green,
                    onChanged: isNotConductedToday ? null : onChanged,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
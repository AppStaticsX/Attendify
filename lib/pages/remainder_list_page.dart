import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../models/remainder.dart';
import '../services/notification_service.dart';
import 'add_remainder_page.dart';

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Box<Reminder> reminderBox = Hive.box<Reminder>('reminders');
    final NotificationService notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('GENERAL REMINDERS'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Iconsax.arrow_left_2_copy)
      ),),
      body: ValueListenableBuilder(
        valueListenable: reminderBox.listenable(),
        builder: (context, Box<Reminder> box, _) {
          if (box.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.timer_pause_copy, size: 120, color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text(
                      "No Reminders Added Yet",
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      "Tap + button to add a Reminder",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<Reminder> reminders = box.values.toList()
            ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              final isPast = reminder.scheduledTime.isBefore(DateTime.now());

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      width: 5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with "Everyday" text and toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${reminder.scheduledTime.hour.toString().padLeft(2, '0')}:${reminder.scheduledTime.minute.toString().padLeft(2, '0')} ${reminder.scheduledTime.hour >= 12 ? 'PM' : 'AM'}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                decoration: isPast ? TextDecoration.lineThrough : TextDecoration.none,
                              ),
                            ),
                            IconButton(
                              icon: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.tertiary
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Iconsax.trash_copy,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                notificationService.cancelReminder(reminder.id);
                                box.delete(reminder.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${reminder.title} deleted.')),
                                );
                              },
                            ),
                            Switch(
                              value: !isPast,
                              onChanged: isPast ? null : (value) {
                                // Toggle reminder active/inactive
                                if (!value) {
                                  notificationService.cancelReminder(reminder.id);
                                }
                              },
                              activeThumbColor: Colors.white,
                              activeTrackColor: Colors.green,
                            ),
                          ],
                        ),
                        // Bottom row with title and delete icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        reminder.title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                          decoration: isPast ? TextDecoration.lineThrough : TextDecoration.none,
                                          fontWeight: FontWeight.w900
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isPast? Colors.red.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                          child: Text(
                                            isPast? 'PAST' : 'UPCOMING',
                                            style: TextStyle(
                                              fontSize: 12
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const AddReminderScreen(),
          ));
        },
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.inversePrimary,),
      ),
    );
  }
}
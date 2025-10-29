import 'package:hive/hive.dart';

// 1. You must run 'flutter pub run build_runner build' to generate this file.
part 'remainder.g.dart';

// Use typeId: 2 to avoid conflict with Event (0) and CompletedDay (1)
@HiveType(typeId: 3)
class Reminder extends HiveObject {

  @HiveField(0)
  final int id; // Unique ID for notification and Hive key

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime scheduledTime;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final String ringtone;

  Reminder({
    required this.id,
    required this.title,
    required this.scheduledTime,
    this.isCompleted = false,
    required this.description,
    required this.ringtone
  });

  // Helper method to create a unique ID for the notification and database key
  static int createUniqueId() {
    // Using a large number modulo 1,000,000 to ensure uniqueness while keeping the ID manageable
    return DateTime.now().millisecondsSinceEpoch % 1000000;
  }
}
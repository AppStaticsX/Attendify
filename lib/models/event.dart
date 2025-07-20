import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 0)
class Event extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late String conductorName;

  @HiveField(2)
  HiveList<CompletedDay>? completedDays;

  @HiveField(3)
  int id = DateTime.now().millisecondsSinceEpoch;

  @HiveField(4)
  List<String> assignedDays = []; // List of weekdays (e.g., ["Monday", "Wednesday"])

  @HiveField(5)
  HiveList<CompletedDay>? notConductedDays; // List of days when habit was not conducted

  Habit() {
    // Ensure assignedDays is always initialized to an empty list
    assignedDays = assignedDays ?? [];
    // Do not initialize notConductedDays here; it will be set in HabitDatabase
  }
}

@HiveType(typeId: 1)
class CompletedDay extends HiveObject {
  @HiveField(0)
  late DateTime date;

  CompletedDay({required this.date});
}
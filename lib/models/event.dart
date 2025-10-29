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

  // New lecture-specific fields
  @HiveField(6)
  String courseCode = ''; // e.g., "CS101", "MATH201"

  @HiveField(7)
  int creditHours = 3; // Default 3 credit hours

  @HiveField(8)
  String lectureTime = ''; // e.g., "09:00 AM - 10:30 AM"

  @HiveField(9)
  String location = ''; // e.g., "Room 204", "Lab A"

  @HiveField(10)
  String semester = ''; // e.g., "Fall 2025", "Spring 2026"

  @HiveField(11)
  double minAttendanceRequired = 80.0; // Minimum attendance percentage required (default 75%)

  @HiveField(12)
  int totalLecturesPlanned = 0; // Total lectures planned for the semester

  @HiveField(13)
  int color = 0xFF2196F3; // Color for visual differentiation (default blue)

  @HiveField(14)
  HiveList<CompletedDay>? cancelledDays; // List of days when lecture was cancelled by professor

  Event() {
    // Ensure assignedDays is always initialized to an empty list
    assignedDays = assignedDays ?? [];
    // Do not initialize notConductedDays and cancelledDays here; they will be set in HabitDatabase
  }
}

@HiveType(typeId: 1)
class CompletedDay extends HiveObject {
  @HiveField(0)
  late DateTime date;

  CompletedDay({required this.date});
}
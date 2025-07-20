import 'package:flutter/foundation.dart';
import 'package:attendify/models/app_settings.dart';
import 'package:attendify/models/event.dart';
import 'package:attendify/util/habit_export_util.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EventDatabase extends ChangeNotifier {
  static late Box<Event> _eventBox;
  static late Box<AppSettings> _settingsBox;

  final Map<int, Box<CompletedDay>> _completedDaysBoxes = {};

  final List<Event> currentEvents = [];

  static Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(EventAdapter());
    Hive.registerAdapter(CompletedDayAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    _eventBox = await Hive.openBox<Event>('events');
    _settingsBox = await Hive.openBox<AppSettings>('appSettings');
  }

  Future<Box<CompletedDay>> _openCompletedDaysBox(int eventId) async {
    if (_completedDaysBoxes.containsKey(eventId)) {
      final box = _completedDaysBoxes[eventId]!;
      if (box.isOpen) {
        return box;
      }
      _completedDaysBoxes.remove(eventId);
    }

    final boxName = 'completedDays_$eventId';
    final box = await Hive.openBox<CompletedDay>(boxName);
    _completedDaysBoxes[eventId] = box;
    return box;
  }

  Future<void> saveFirstLaunchDate() async {
    if (_settingsBox.isEmpty) {
      final settings = AppSettings()..firstLaunchDate = DateTime.now();
      await _settingsBox.add(settings);
    }
  }

  Future<DateTime?> getFirstLaunchDate() async {
    if (_settingsBox.isNotEmpty) {
      return _settingsBox.getAt(0)?.firstLaunchDate;
    }
    return null;
  }

  Future<void> addEvent(String eventName, List<String> assignedDays, String conductorName) async {
    try {
      final event = Event()
        ..name = eventName
        ..conductorName = conductorName
        ..assignedDays = assignedDays;

      await _eventBox.add(event);

      final completedDaysBox = await _openCompletedDaysBox(event.id);
      event.completedDays = HiveList(completedDaysBox);
      event.notConductedDays = HiveList(completedDaysBox);
      await event.save();

      await readEvents();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> readEvents() async {
    try {
      currentEvents.clear();

      if (_eventBox.isOpen && _eventBox.isNotEmpty) {
        final events = _eventBox.values.toList();

        for (var event in events) {
          try {
            final completedDaysBox = await _openCompletedDaysBox(event.id);

            if (event.completedDays == null) {
              final existingData = event.completedDays?.toList() ?? [];
              event.completedDays = HiveList(completedDaysBox, objects: existingData);
              await event.save();
            }

            if (event.notConductedDays == null) {
              final existingData = event.notConductedDays?.toList() ?? [];
              event.notConductedDays = HiveList(completedDaysBox, objects: existingData);
              await event.save();
            }
          } catch (e) {
            final completedDaysBox = await _openCompletedDaysBox(event.id);
            event.completedDays = HiveList(completedDaysBox);
            event.notConductedDays = HiveList(completedDaysBox);
            await event.save();
          }
        }

        currentEvents.addAll(events);
      }

      notifyListeners();
    } catch (e) {
      notifyListeners();
    }
  }

  Future<void> updateEventCompletion(int id, bool isCompleted) async {
    final eventIndex = _findEventIndexById(id);

    if (eventIndex != -1) {
      final event = _eventBox.getAt(eventIndex);

      if (event != null) {
        final completedDaysBox = await _openCompletedDaysBox(event.id);

        event.completedDays ??= HiveList(completedDaysBox);

        event.notConductedDays ??= HiveList(completedDaysBox);

        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

        if (isCompleted) {
          bool alreadyCompleted = event.completedDays!.any((day) =>
          day.date.year == today.year &&
              day.date.month == today.month &&
              day.date.day == today.day);

          if (!alreadyCompleted) {
            final completedDay = CompletedDay(date: today);
            await completedDaysBox.add(completedDay);
            event.completedDays!.add(completedDay);
            // Remove from notConductedDays if present
            final notConductedToRemove = event.notConductedDays!.where((day) =>
            day.date.year == today.year &&
                day.date.month == today.month &&
                day.date.day == today.day).toList();
            for (var day in notConductedToRemove) {
              event.notConductedDays!.remove(day);
              await day.delete();
            }
          }
        } else {
          final toRemove = event.completedDays!.where((day) =>
          day.date.year == today.year &&
              day.date.month == today.month &&
              day.date.day == today.day).toList();

          for (var day in toRemove) {
            event.completedDays!.remove(day);
            await day.delete();
          }
        }

        await event.save();
      }
    }

    await readEvents();
  }

  Future<void> markEventNotConducted(int id) async {
    final eventIndex = _findEventIndexById(id);

    if (eventIndex != -1) {
      final event = _eventBox.getAt(eventIndex);

      if (event != null) {
        final completedDaysBox = await _openCompletedDaysBox(event.id);

        event.notConductedDays ??= HiveList(completedDaysBox);

        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

        bool alreadyNotConducted = event.notConductedDays!.any((day) =>
        day.date.year == today.year &&
            day.date.month == today.month &&
            day.date.day == today.day);

        if (!alreadyNotConducted) {
          final notConductedDay = CompletedDay(date: today);
          await completedDaysBox.add(notConductedDay);
          event.notConductedDays!.add(notConductedDay);
          // Remove from completedDays if present
          final completedToRemove = event.completedDays!.where((day) =>
          day.date.year == today.year &&
              day.date.month == today.month &&
              day.date.day == today.day).toList();
          for (var day in completedToRemove) {
            event.completedDays!.remove(day);
            await day.delete();
          }
        }

        await event.save();
      }
    }

    await readEvents();
  }

  Future<void> updateEvent(int id, String newName, List<String> newAssignedDays, String conductorName) async {
    final eventIndex = _findEventIndexById(id);

    if (eventIndex != -1) {
      final event = _eventBox.getAt(eventIndex);

      if (event != null) {
        event.name = newName;
        event.conductorName = conductorName;
        event.assignedDays = newAssignedDays;
        if (event.notConductedDays == null) {
          final completedDaysBox = await _openCompletedDaysBox(event.id);
          event.notConductedDays = HiveList(completedDaysBox);
        }
        await event.save();
      }
    }

    await readEvents();
  }

  Future<void> deleteHabit(int id) async {
    final habitIndex = _findHabitIndexById(id);

    if (habitIndex != -1) {
      final habit = _habitsBox.getAt(habitIndex);

      if (habit != null) {
        final boxName = 'completedDays_${habit.id}';
        Box<CompletedDay>? completedDaysBox = _completedDaysBoxes[habit.id];

        if (completedDaysBox == null || !completedDaysBox.isOpen) {
          try {
            completedDaysBox = await Hive.openBox<CompletedDay>(boxName);
            _completedDaysBoxes[habit.id] = completedDaysBox;
          } catch (e) {
            debugPrint('Error opening completedDays box: $e');
          }
        }

        if (habit.completedDays != null && habit.completedDays!.isNotEmpty) {
          for (var day in habit.completedDays!) {
            await day.delete();
          }
        }

        if (habit.notConductedDays != null && habit.notConductedDays!.isNotEmpty) {
          for (var day in habit.notConductedDays!) {
            await day.delete();
          }
        }

        if (completedDaysBox != null && completedDaysBox.isOpen) {
          await completedDaysBox.close();
          _completedDaysBoxes.remove(habit.id);
        }

        await Hive.deleteBoxFromDisk(boxName);
        await _habitsBox.deleteAt(habitIndex);
        debugPrint('Deleted habit: ${habit.name}');
      }
    }

    await readHabits();
  }

  int _findHabitIndexById(int id) {
    for (int i = 0; i < _habitsBox.length; i++) {
      final habit = _habitsBox.getAt(i);
      if (habit != null && habit.id == id) {
        return i;
      }
    }
    return -1;
  }

  Future<void> exportHabitsAsCSV() async {
    try {
      await HabitExportUtil.exportAndShareHabits(currentHabits);
    } catch (e) {
      debugPrint('Error exporting habits: $e');
      rethrow;
    }
  }

  Future<String> exportHabitsToFile() async {
    try {
      return await HabitExportUtil.exportHabitsToFile(currentHabits);
    } catch (e) {
      debugPrint('Error exporting habits to file: $e');
      rethrow;
    }
  }

  Future<String> exportHabitsToCustomDirectory() async {
    try {
      return await HabitExportUtil.exportHabitsToCustomDirectory(currentHabits);
    } catch (e) {
      debugPrint('Error exporting habits to custom directory: $e');
      rethrow;
    }
  }

  Future<void> importHabitsFromCSV(String filePath) async {
    try {
      List<Map<String, dynamic>> importedHabits = await HabitExportUtil.importHabitsFromCSV(filePath);

      for (var habitData in importedHabits) {
        final habit = Habit()
          ..name = habitData['name']
          ..id = habitData['id']
          ..conductorName = habitData['conductedby']
          ..assignedDays = List<String>.from(habitData['assignedDays'] ?? []);

        await _habitsBox.add(habit);
        final completedDaysBox = await _openCompletedDaysBox(habit.id);

        habit.completedDays = HiveList(completedDaysBox);
        habit.notConductedDays = HiveList(completedDaysBox);
        await habit.save();

        List<DateTime> completedDays = habitData['completedDays'];
        for (var date in completedDays) {
          final completedDay = CompletedDay(date: date);
          await completedDaysBox.add(completedDay);
          habit.completedDays!.add(completedDay);
        }

        await habit.save();
        debugPrint('Imported habit: ${habit.name}, assignedDays: ${habit.assignedDays}');
      }

      await readHabits();
    } catch (e) {
      debugPrint('Error importing habits: $e');
      rethrow;
    }
  }

  // Holiday management methods
  Future<void> addHoliday(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final holidayKey = '${normalizedDate.year}-${normalizedDate.month}-${normalizedDate.day}';

    if (!_settingsBox.isEmpty) {
      final settings = _settingsBox.getAt(0)!;
      settings.holidays ??= <String>[];
      if (!settings.holidays!.contains(holidayKey)) {
        settings.holidays!.add(holidayKey);
        await settings.save();
      }
    }
    notifyListeners();
  }

  Future<void> removeHoliday(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final holidayKey = '${normalizedDate.year}-${normalizedDate.month}-${normalizedDate.day}';

    if (!_settingsBox.isEmpty) {
      final settings = _settingsBox.getAt(0)!;
      settings.holidays?.remove(holidayKey);
      await settings.save();
    }
    notifyListeners();
  }

  Future<bool> isHoliday(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final holidayKey = '${normalizedDate.year}-${normalizedDate.month}-${normalizedDate.day}';

    if (!_settingsBox.isEmpty) {
      final settings = _settingsBox.getAt(0)!;
      return settings.holidays?.contains(holidayKey) ?? false;
    }
    return false;
  }

  Future<List<DateTime>> getHolidays() async {
    if (!_settingsBox.isEmpty) {
      final settings = _settingsBox.getAt(0)!;
      return (settings.holidays ?? <String>[]).map((holidayKey) {
        final parts = holidayKey.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }).toList();
    }
    return [];
  }
}
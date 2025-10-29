import 'package:flutter/foundation.dart';
import 'package:attendify/models/app_settings.dart';
import 'package:attendify/models/event.dart';
import 'package:attendify/util/event_export_util.dart';
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
      event.cancelledDays = HiveList(completedDaysBox);
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

            if (event.cancelledDays == null) {
              final existingData = event.cancelledDays?.toList() ?? [];
              event.cancelledDays = HiveList(completedDaysBox, objects: existingData);
              await event.save();
            }
          } catch (e) {
            final completedDaysBox = await _openCompletedDaysBox(event.id);
            event.completedDays = HiveList(completedDaysBox);
            event.notConductedDays = HiveList(completedDaysBox);
            event.cancelledDays = HiveList(completedDaysBox);
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

  Future<void> deleteEvent(int id) async {
    final eventIndex = _findEventIndexById(id);

    if (eventIndex != -1) {
      final event = _eventBox.getAt(eventIndex);

      if (event != null) {
        final boxName = 'completedDays_${event.id}';
        Box<CompletedDay>? completedDaysBox = _completedDaysBoxes[event.id];

        if (completedDaysBox == null || !completedDaysBox.isOpen) {
          try {
            completedDaysBox = await Hive.openBox<CompletedDay>(boxName);
            _completedDaysBoxes[event.id] = completedDaysBox;
          } catch (e) {
            null;
          }
        }

        if (event.completedDays != null && event.completedDays!.isNotEmpty) {
          for (var day in event.completedDays!) {
            await day.delete();
          }
        }

        if (event.notConductedDays != null && event.notConductedDays!.isNotEmpty) {
          for (var day in event.notConductedDays!) {
            await day.delete();
          }
        }

        if (event.cancelledDays != null && event.cancelledDays!.isNotEmpty) {
          for (var day in event.cancelledDays!) {
            await day.delete();
          }
        }

        if (completedDaysBox != null && completedDaysBox.isOpen) {
          await completedDaysBox.close();
          _completedDaysBoxes.remove(event.id);
        }

        await Hive.deleteBoxFromDisk(boxName);
        await _eventBox.deleteAt(eventIndex);
      }
    }

    await readEvents();
  }

  int _findEventIndexById(int id) {
    for (int i = 0; i < _eventBox.length; i++) {
      final event = _eventBox.getAt(i);
      if (event != null && event.id == id) {
        return i;
      }
    }
    return -1;
  }

  Future<void> exportEventsAsCSV() async {
    try {
      await EventExportUtil.exportAndShareEvents(currentEvents);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> exportEventsToFile() async {
    try {
      return await EventExportUtil.exportEventsToFile(currentEvents);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> exportEventsToCustomDirectory() async {
    try {
      return await EventExportUtil.exportEventsToCustomDirectory(currentEvents);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> importEventsFromCSV(String filePath) async {
    try {
      List<Map<String, dynamic>> importedEvents = await EventExportUtil.importEventsFromCSV(filePath);

      for (var eventData in importedEvents) {
        final event = Event()
          ..name = eventData['name']
          ..id = eventData['id']
          ..conductorName = eventData['conductorName']
          ..courseCode = eventData['courseCode']
          ..creditHours = eventData['creditHours']
          ..lectureTime = eventData['lectureTime']
          ..location = eventData['location']
          ..semester = eventData['semester']
          ..minAttendanceRequired = eventData['minAttendanceRequired']
          ..totalLecturesPlanned = eventData['totalLecturesPlanned']
          ..color = eventData['color']
          ..assignedDays = List<String>.from(eventData['assignedDays'] ?? []);

        await _eventBox.add(event);

        // Setup all day types using the same box (as per current architecture)
        final completedDaysBox = await _openCompletedDaysBox(event.id);
        event.completedDays = HiveList(completedDaysBox);
        event.notConductedDays = HiveList(completedDaysBox);
        event.cancelledDays = HiveList(completedDaysBox);

        // Add completed days
        List<DateTime> completedDays = eventData['completedDays'] ?? [];
        for (var date in completedDays) {
          final completedDay = CompletedDay(date: date);
          await completedDaysBox.add(completedDay);
          event.completedDays!.add(completedDay);
        }

        // Add not conducted days
        List<DateTime> notConductedDays = eventData['notConductedDays'] ?? [];
        for (var date in notConductedDays) {
          final notConductedDay = CompletedDay(date: date);
          await completedDaysBox.add(notConductedDay);
          event.notConductedDays!.add(notConductedDay);
        }

        // Add cancelled days
        List<DateTime> cancelledDays = eventData['cancelledDays'] ?? [];
        for (var date in cancelledDays) {
          final cancelledDay = CompletedDay(date: date);
          await completedDaysBox.add(cancelledDay);
          event.cancelledDays!.add(cancelledDay);
        }

        await event.save();
      }

      await readEvents();
    } catch (e) {
      rethrow;
    }
  }

  // Holiday management methods
  Future<void> addHoliday(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final holidayKey = '${normalizedDate.year}-${normalizedDate.month}-${normalizedDate.day}';

    if (_settingsBox.isNotEmpty) {
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

    if (_settingsBox.isNotEmpty) {
      final settings = _settingsBox.getAt(0)!;
      settings.holidays?.remove(holidayKey);
      await settings.save();
    }
    notifyListeners();
  }

  Future<bool> isHoliday(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final holidayKey = '${normalizedDate.year}-${normalizedDate.month}-${normalizedDate.day}';

    if (_settingsBox.isNotEmpty) {
      final settings = _settingsBox.getAt(0)!;
      return settings.holidays?.contains(holidayKey) ?? false;
    }
    return false;
  }

  Future<List<DateTime>> getHolidays() async {
    if (_settingsBox.isNotEmpty) {
      final settings = _settingsBox.getAt(0)!;
      return (settings.holidays ?? <String>[]).map((holidayKey) {
        final parts = holidayKey.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }).toList();
    }
    return [];
  }
}

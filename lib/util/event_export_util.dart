import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:attendify/models/event.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

class EventExportUtil {
  /// Converts a list of habits into CSV format
  static String eventsToCSV(List<Event> events) {
    List<List<dynamic>> csvData = [
      [
        'Event_ID',
        'Event_Name',
        'Conductor_Name',
        'Course_Code',
        'Credit_Hours',
        'Lecture_Time',
        'Location',
        'Semester',
        'Min_Attendance_Required',
        'Total_Lectures_Planned',
        'Color',
        'Assigned_Days',
        'Completed_Days',
        'Not_Conducted_Days',
        'Cancelled_Days'
      ]
    ];

    for (var event in events) {
      String assignedDaysStr = event.assignedDays.join(';');

      // Convert completed days to semicolon-separated dates
      String completedDaysStr = '';
      if (event.completedDays != null && event.completedDays!.isNotEmpty) {
        completedDaysStr = event.completedDays!
            .map((cd) => '${cd.date.year}-${cd.date.month.toString().padLeft(2, '0')}-${cd.date.day.toString().padLeft(2, '0')}')
            .join(';');
      }

      // Convert not conducted days to semicolon-separated dates
      String notConductedDaysStr = '';
      if (event.notConductedDays != null && event.notConductedDays!.isNotEmpty) {
        notConductedDaysStr = event.notConductedDays!
            .map((ncd) => '${ncd.date.year}-${ncd.date.month.toString().padLeft(2, '0')}-${ncd.date.day.toString().padLeft(2, '0')}')
            .join(';');
      }

      // Convert cancelled days to semicolon-separated dates
      String cancelledDaysStr = '';
      if (event.cancelledDays != null && event.cancelledDays!.isNotEmpty) {
        cancelledDaysStr = event.cancelledDays!
            .map((cd) => '${cd.date.year}-${cd.date.month.toString().padLeft(2, '0')}-${cd.date.day.toString().padLeft(2, '0')}')
            .join(';');
      }

      csvData.add([
        event.id,
        event.name,
        event.conductorName,
        event.courseCode,
        event.creditHours,
        event.lectureTime,
        event.location,
        event.semester,
        event.minAttendanceRequired,
        event.totalLecturesPlanned,
        event.color,
        assignedDaysStr,
        completedDaysStr,
        notConductedDaysStr,
        cancelledDaysStr
      ]);
    }

    String csv = const ListToCsvConverter().convert(csvData);
    return csv;
  }

  /// Exports habits as CSV file and returns the file path
  static Future<String> exportEventsToFile(List<Event> events) async {
    try {
      String csvData = eventsToCSV(events);
      final directory = await _getExportDirectory();
      String timestamp = DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-').split('.').first;
      String fileName = 'attendify_export_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);
      return file.path;
    } catch (e) {
      rethrow;
    }
  }

  /// Exports habits to a user-selected directory using file picker
  static Future<String> exportEventsToCustomDirectory(List<Event> events) async {
    try {
      // Convert habits to CSV
      String csvData = eventsToCSV(events);

      // Create a temporary file to hold the CSV data
      final tempDir = await getTemporaryDirectory();
      String timestamp = DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-').split('.').first;
      String fileName = 'attendify_export_$timestamp.csv';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(csvData);

      // Use file picker to let user select save location
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        // User canceled the picker
        throw Exception('No directory selected');
      }

      // Copy the temporary file to the selected directory
      final finalFile = File('$selectedDirectory/$fileName');
      await tempFile.copy(finalFile.path);

      // Clean up the temporary file
      await tempFile.delete();

      return finalFile.path;
    } catch (e) {
      debugPrint('Error exporting habits to custom directory: $e');
      rethrow;
    }
  }

  /// Exports and shares the habits CSV file
  static Future<void> exportAndShareEvents(List<Event> events) async {
    try {
      String csvData = eventsToCSV(events);
      final tempDir = await getTemporaryDirectory();
      String timestamp = DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-').split('.').first;
      String fileName = 'attendify_export_$timestamp.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvData);
      await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path)],
          text: 'Attendify Data Export'
      ));
    } catch (e) {
      rethrow;
    }
  }

  /// Gets the appropriate directory based on platform
  static Future<Directory> _getExportDirectory() async {
    if (Platform.isAndroid) {
      try {
        Directory? directory = await getExternalStorageDirectory();
        if (directory == null) {
          directory = await getApplicationDocumentsDirectory();
        } else {
          String newPath = "";
          List<String> paths = directory.path.split("/");
          for (int x = 1; x < paths.length; x++) {
            String folder = paths[x];
            if (folder != "Android") {
              newPath += "/$folder";
            } else {
              break;
            }
          }
          newPath += "/Download";
          directory = Directory(newPath);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        }
        return directory;
      } catch (e) {
        return await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Import habits from CSV file
  static Future<List<Map<String, dynamic>>> importEventsFromCSV(String filePath) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString();
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(contents);

      if (rowsAsListOfValues.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> importedEvents = [];

      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        var row = rowsAsListOfValues[i];
        if (row.length < 15) continue; // Ensure we have all required fields

        String eventId = row[0].toString();
        String eventName = row[1].toString();
        String conductorName = row[2].toString();
        String courseCode = row[3].toString();
        int creditHours = int.tryParse(row[4].toString()) ?? 3;
        String lectureTime = row[5].toString();
        String location = row[6].toString();
        String semester = row[7].toString();
        double minAttendanceRequired = double.tryParse(row[8].toString()) ?? 80.0;
        int totalLecturesPlanned = int.tryParse(row[9].toString()) ?? 0;
        int color = int.tryParse(row[10].toString()) ?? 0xFF2196F3;
        String assignedDaysStr = row[11].toString();
        String completedDaysStr = row[12].toString();
        String notConductedDaysStr = row[13].toString();
        String cancelledDaysStr = row[14].toString();

        // Parse assigned days
        List<String> assignedDays = assignedDaysStr.isNotEmpty
            ? assignedDaysStr.split(';').map((day) => day.trim()).toList()
            : <String>[];

        // Parse completed days
        List<DateTime> completedDays = [];
        if (completedDaysStr.isNotEmpty) {
          for (String dateStr in completedDaysStr.split(';')) {
            try {
              completedDays.add(DateTime.parse(dateStr.trim()));
            } catch (e) {
              debugPrint('Error parsing completed date: $dateStr');
            }
          }
        }

        // Parse not conducted days
        List<DateTime> notConductedDays = [];
        if (notConductedDaysStr.isNotEmpty) {
          for (String dateStr in notConductedDaysStr.split(';')) {
            try {
              notConductedDays.add(DateTime.parse(dateStr.trim()));
            } catch (e) {
              debugPrint('Error parsing not conducted date: $dateStr');
            }
          }
        }

        // Parse cancelled days
        List<DateTime> cancelledDays = [];
        if (cancelledDaysStr.isNotEmpty) {
          for (String dateStr in cancelledDaysStr.split(';')) {
            try {
              cancelledDays.add(DateTime.parse(dateStr.trim()));
            } catch (e) {
              debugPrint('Error parsing cancelled date: $dateStr');
            }
          }
        }

        importedEvents.add({
          'id': int.tryParse(eventId) ?? DateTime.now().millisecondsSinceEpoch,
          'name': eventName,
          'conductorName': conductorName,
          'courseCode': courseCode,
          'creditHours': creditHours,
          'lectureTime': lectureTime,
          'location': location,
          'semester': semester,
          'minAttendanceRequired': minAttendanceRequired,
          'totalLecturesPlanned': totalLecturesPlanned,
          'color': color,
          'assignedDays': assignedDays,
          'completedDays': completedDays,
          'notConductedDays': notConductedDays,
          'cancelledDays': cancelledDays,
        });
      }

      return importedEvents;
    } catch (e) {
      rethrow;
    }
  }
}
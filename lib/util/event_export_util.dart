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
      ['Event_ID', 'Events_Name', 'Assigned_Days', 'Completion_Date']
    ];

    for (var event in events) {
      String assignedDaysStr = event.assignedDays.join(';');

      if (event.completedDays == null || event.completedDays!.isEmpty) {
        csvData.add([event.id, event.name, assignedDaysStr, '']);
      } else {
        for (var completedDay in event.completedDays!) {
          String formattedDate = '${completedDay.date.year}-${completedDay.date.month.toString().padLeft(2, '0')}-${completedDay.date.day.toString().padLeft(2, '0')}';
          csvData.add([event.id, event.name, assignedDaysStr, formattedDate]);
        }
      }
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
      Map<String, Map<String, dynamic>> eventsMap = {};

      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        var row = rowsAsListOfValues[i];
        if (row.length < 3) continue;

        String eventId = row[0].toString();
        String eventName = row[1].toString();
        String assignedDaysStr = row.length > 2 ? row[2].toString() : '';
        String completionDate = row.length > 3 ? row[3].toString() : '';

        if (!eventsMap.containsKey(eventId)) {
          List<String> assignedDays = assignedDaysStr.isNotEmpty
              ? assignedDaysStr.split(';').map((day) => day.trim()).toList()
              : <String>[];

          eventsMap[eventId] = {
            'id': int.tryParse(eventId) ?? DateTime.now().millisecondsSinceEpoch,
            'name': eventName,
            'assignedDays': assignedDays,
            'completedDays': <DateTime>[]
          };
        }

        if (completionDate.isNotEmpty) {
          try {
            DateTime date = DateTime.parse(completionDate);
            (eventsMap[eventId]!['completedDays'] as List<DateTime>).add(date);
          } catch (e) {
            null;
          }
        }
      }

      importedEvents = eventsMap.values.toList();
      return importedEvents;
    } catch (e) {
      rethrow;
    }
  }
}
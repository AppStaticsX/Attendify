import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:attendify/models/event.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

class HabitExportUtil {
  /// Converts a list of habits into CSV format
  static String habitsToCSV(List<Habit> habits) {
    List<List<dynamic>> csvData = [
      ['Habit ID', 'Habit Name', 'Assigned Days', 'Completion Date']
    ];

    for (var habit in habits) {
      String assignedDaysStr = habit.assignedDays.join(';');

      if (habit.completedDays == null || habit.completedDays!.isEmpty) {
        csvData.add([habit.id, habit.name, assignedDaysStr, '']);
      } else {
        for (var completedDay in habit.completedDays!) {
          String formattedDate = '${completedDay.date.year}-${completedDay.date.month.toString().padLeft(2, '0')}-${completedDay.date.day.toString().padLeft(2, '0')}';
          csvData.add([habit.id, habit.name, assignedDaysStr, formattedDate]);
        }
      }
    }

    String csv = const ListToCsvConverter().convert(csvData);
    return csv;
  }

  /// Exports habits as CSV file and returns the file path
  static Future<String> exportHabitsToFile(List<Habit> habits) async {
    try {
      String csvData = habitsToCSV(habits);
      final directory = await _getExportDirectory();
      String timestamp = DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-').split('.').first;
      String fileName = 'habitap_export_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);
      return file.path;
    } catch (e) {
      debugPrint('Error exporting habits: $e');
      rethrow;
    }
  }

  /// Exports habits to a user-selected directory using file picker
  static Future<String> exportHabitsToCustomDirectory(List<Habit> habits) async {
    try {
      // Convert habits to CSV
      String csvData = habitsToCSV(habits);

      // Create a temporary file to hold the CSV data
      final tempDir = await getTemporaryDirectory();
      String timestamp = DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-').split('.').first;
      String fileName = 'habitap_export_$timestamp.csv';
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
  static Future<void> exportAndShareHabits(List<Habit> habits) async {
    try {
      String csvData = habitsToCSV(habits);
      final tempDir = await getTemporaryDirectory();
      String timestamp = DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-').split('.').first;
      String fileName = 'habitap_export_$timestamp.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(file.path)], text: 'HabitAp Data Export');
    } catch (e) {
      debugPrint('Error sharing habits: $e');
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
        debugPrint('Error accessing external storage: $e');
        return await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Import habits from CSV file
  static Future<List<Map<String, dynamic>>> importHabitsFromCSV(String filePath) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString();
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(contents);

      if (rowsAsListOfValues.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> importedHabits = [];
      Map<String, Map<String, dynamic>> habitsMap = {};

      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        var row = rowsAsListOfValues[i];
        if (row.length < 3) continue;

        String habitId = row[0].toString();
        String habitName = row[1].toString();
        String assignedDaysStr = row.length > 2 ? row[2].toString() : '';
        String completionDate = row.length > 3 ? row[3].toString() : '';

        if (!habitsMap.containsKey(habitId)) {
          List<String> assignedDays = assignedDaysStr.isNotEmpty
              ? assignedDaysStr.split(';').map((day) => day.trim()).toList()
              : <String>[];

          habitsMap[habitId] = {
            'id': int.tryParse(habitId) ?? DateTime.now().millisecondsSinceEpoch,
            'name': habitName,
            'assignedDays': assignedDays,
            'completedDays': <DateTime>[]
          };
        }

        if (completionDate.isNotEmpty) {
          try {
            DateTime date = DateTime.parse(completionDate);
            (habitsMap[habitId]!['completedDays'] as List<DateTime>).add(date);
          } catch (e) {
            debugPrint('Error parsing date: $completionDate');
          }
        }
      }

      importedHabits = habitsMap.values.toList();
      return importedHabits;
    } catch (e) {
      debugPrint('Error importing habits: $e');
      rethrow;
    }
  }
}
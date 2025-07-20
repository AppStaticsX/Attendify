import 'package:flutter/material.dart';
import 'package:attendify/authentication/add_pin_page.dart';
import 'package:attendify/authentication/auth_page.dart';
import 'package:attendify/components/custom_icon_button.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:attendify/database/event_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: ListView(
        children: const [
          Padding(
            padding: EdgeInsets.only(left: 24.0, top: 24.0, bottom: 0.0),
            child: Text(
              'Account',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: AccountTile(),
          ),
          Padding(
            padding: EdgeInsets.only(left: 24.0, top: 24.0, bottom: 0.0),
            child: Text(
              'Import, Export & Share Data',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: ExportCSVTile(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: BackupToStorageTile(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: ImportDataTile(),
          ),
          Padding(
            padding: EdgeInsets.only(left: 24.0, top: 24.0, bottom: 0.0),
            child: Text(
              'Security',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: AuthTile(),
          ),
          Padding(
            padding: EdgeInsets.only(left: 24.0, top: 24.0, bottom: 0.0),
            child: Text(
              'Schedule',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: ScheduleTile(),
          ),
        ],
      ),
    );
  }
}

class AuthTile extends StatelessWidget {
  const AuthTile({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(
          Iconsax.lock_copy,
          size: 26,
        ),
        title: const Text(
          'Authentication',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: CustomIconButton(
            icon: Iconsax.arrow_right_2,
            onPressed: () async {
              final String authKey = 'isAuthenticated';
              try {
                final prefs = await SharedPreferences.getInstance();
                String? savedPIN = prefs.getString('pinKEY');
                final isAuthenticated = prefs.getBool(authKey) ?? false;

                if (savedPIN != null && savedPIN.isNotEmpty && isAuthenticated) {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) {
                        return AuthPage(
                          onSuccess: () {
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) {
                                  return AddPinPage();
                                }));
                          },
                        );
                      }));
                } else {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) {
                        return AddPinPage();
                      }));
                }
              } catch (e) {
                debugPrint(e.toString());
              }
            },
            size: 24),
      ),
    );
  }
}

class ScheduleTile extends StatelessWidget {
  const ScheduleTile({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(
          Iconsax.calendar_copy,
          size: 26,
        ),
        title: const Text(
          'Manage Schedule',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: CustomIconButton(
            icon: Iconsax.arrow_right_2,
            onPressed: () {
            },
            size: 24),
      ),
    );
  }
}

class AccountTile extends StatelessWidget {
  const AccountTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.black,
              child: Icon(
                Iconsax.user_copy,
                color: Colors.white,
              ),
            ),
            title: const Text(
              'Anonymous',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class ExportCSVTile extends StatelessWidget {
  const ExportCSVTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const Icon(
          Iconsax.send_2_copy,
          size: 26,
        ),
        title: const Text(
          'Share Your Data',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => _exportHabits(context),
      ),
    );
  }

  void _exportHabits(BuildContext context) async {
    try {
      CustomToast._showCustomToast(context, 'Preparing export...', Iconsax.export_2);
      final habitDatabase = Provider.of<HabitDatabase>(context, listen: false);
      await habitDatabase.exportHabitsAsCSV();
      CustomToast._showCustomToast(context, 'Habits exported successfully!', Iconsax.tick_circle);
    } catch (e) {
      debugPrint('Export error: $e');
      CustomToast._showCustomToast(context, 'Export failed: ${e.toString().split('\n')[0]}', Iconsax.close_circle);
    }
  }
}

class BackupToStorageTile extends StatelessWidget {
  const BackupToStorageTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const Icon(
          Iconsax.document_download_copy,
          size: 26,
        ),
        title: const Text(
          'Save Backup to Storage',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Select a directory to save your backup',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.7)),
        ),
        onTap: () => _saveToStorage(context),
      ),
    );
  }

  void _saveToStorage(BuildContext context) async {
    try {
      CustomToast._showCustomToast(context, 'Collecting Data...', Iconsax.data_copy);
      final habitDatabase = Provider.of<HabitDatabase>(context, listen: false);
      final filePath = await habitDatabase.exportHabitsToCustomDirectory();
      CustomToast._showCustomToast(context, 'Backup saved to: $filePath', Iconsax.tick_circle);
    } catch (e) {
      debugPrint('Backup error: $e');
      CustomToast._showCustomToast(context, 'Backup failed: ${e.toString().split('\n')[0]}', Iconsax.close_circle);
    }
  }
}

class ImportDataTile extends StatelessWidget {
  const ImportDataTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const Icon(
          Iconsax.document_upload_copy,
          size: 26,
        ),
        title: const Text(
          'Import Data',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => _importHabits(context),
      ),
    );
  }

  void _importHabits(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Importing habits...')));
        final habitDatabase = Provider.of<HabitDatabase>(context, listen: false);
        await habitDatabase.importHabitsFromCSV(result.files.single.path!);
        CustomToast._showCustomToast(context, 'Habits imported successfully!', Iconsax.tick_circle);
      }
    } catch (e) {
      debugPrint('Import error: $e');
      CustomToast._showCustomToast(context, 'Import failed: ${e.toString().split('\n')[0]}', Iconsax.close_circle);
    }
  }
}

class CustomToast extends StatelessWidget {
  const CustomToast({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  static void _showCustomToast(BuildContext context, String message, IconData icon,
      {int durationInSeconds = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        content: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.inversePrimary),
            const SizedBox(width: 10),
            Expanded(child: Text(message,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary
              ),)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: durationInSeconds),
      ),
    );
  }
}
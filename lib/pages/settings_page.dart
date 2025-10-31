import 'package:attendify/components/name_picker_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:attendify/authentication/add_pin_page.dart';
import 'package:attendify/authentication/local_auth_page.dart';
import 'package:attendify/components/custom_icon_button.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:attendify/database/event_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: false,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Iconsax.arrow_left_2_copy)
        ),
      ),
      body: ListView(
        children: [
          const Padding(
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: AccountTile(),
          ),
          const Padding(
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: ExportCSVTile(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: BackupToStorageTile(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: ImportDataTile(),
          ),
          const Padding(
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: AuthTile(),
          ),
          const Padding(
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
          const Padding(
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
                  if (context.mounted) {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) {
                          return LocalAuthPage(
                            onSuccess: () {
                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (context) {
                                    return AddPinPage();
                                  }));
                            },
                          );
                        }));
                  }
                } else {
                  if (context.mounted) {
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) {
                          return AddPinPage();
                        }));
                  }
                }
              } catch (e) {
                debugPrint(e.toString());
              }
            },
            size: 24, toolTip: 'Go Inside'),
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
              CustomToast._showCustomToast(context, 'This feature is coming soon...', Iconsax.star);
            },
            size: 24, toolTip: 'Go Inside',),
      ),
    );
  }
}

class AccountTile extends StatefulWidget {
  const AccountTile({
    super.key,
  });

  @override
  State<AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends State<AccountTile> {

  String userName = 'Anonymous';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('userNAME');

    if (mounted) {
      setState(() {
        userName = username ?? 'Anonymous'; // Handle null case properly
      });
    }
  }

  void _updateUserName() {
    // This method will be called when name is updated
    _loadUserName();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
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
              title: Text(
                userName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return NamePickerBottomsheet(
                        onNameUpdated: _updateUserName, // Pass the callback
                      );
                    }
                );
              },
            ),
          ],
        ),
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
        onTap: () => _exportEvents(context),
      ),
    );
  }

  void _exportEvents(BuildContext context) async {
    try {
      CustomToast._showCustomToast(context, 'Preparing export...', Iconsax.export_2);
      final eventDatabase = Provider.of<EventDatabase>(context, listen: false);
      await eventDatabase.exportEventsAsCSV();
      if (context.mounted) {
        CustomToast._showCustomToast(context, 'Events exported successfully!', Iconsax.tick_circle);
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast._showCustomToast(context, 'Export failed: ${e.toString().split('\n')[0]}', Iconsax.close_circle);
      }
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
      final eventDatabase = Provider.of<EventDatabase>(context, listen: false);
      final filePath = await eventDatabase.exportEventsToCustomDirectory();
      if (context.mounted) {
        CustomToast._showCustomToast(context, 'Backup saved to: $filePath', Iconsax.tick_circle);
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast._showCustomToast(context, 'Backup failed: ${e.toString().split('\n')[0]}', Iconsax.close_circle);
      }
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
        onTap: () => _importEvents(context),
      ),
    );
  }

  void _importEvents(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Importing events...')));
        }
        if (context.mounted) {
          final eventDatabase = Provider.of<EventDatabase>(context, listen: false);
          await eventDatabase.importEventsFromCSV(result.files.single.path!);
        }

        if (context.mounted) {
          CustomToast._showCustomToast(context, 'Events imported successfully!', Iconsax.tick_circle);
        }

      }
    } catch (e) {
      if (context.mounted) {
        CustomToast._showCustomToast(context, 'Import failed: ${e.toString().split('\n')[0]}', Iconsax.close_circle);
      }

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
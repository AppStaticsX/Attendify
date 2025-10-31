import 'package:attendify/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendify/authentication/local_auth_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:attendify/components/alarm_overlay.dart';
import 'package:attendify/database/event_database.dart';
import 'package:attendify/pages/welcome_page.dart';
import 'package:attendify/pages/home_page.dart';
import 'package:attendify/themes/theme_provider.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/remainder.dart';

final NotificationService _notificationService = NotificationService();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Add this global variable
NotificationAppLaunchDetails? notificationAppLaunchDetails;

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and HabitDatabase
  await EventDatabase.initialize();

  Hive.registerAdapter(ReminderAdapter());

  // Open the Reminder box (assuming EventDatabase handles the Event box)
  await Hive.openBox<Reminder>('reminders');

  // Initialize the Notification Service with callback
  try {
    await _notificationService.init(
      onNotificationReceived: (reminderId, scheduledTime, description, title) {
        // Navigate to AlarmOverlayPage when notification is received
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => AlarmOverlayPage(
              reminderId: reminderId,
              scheduledTime: scheduledTime,
              description: description,
              title: title,
            ),
          ),
        );
      },
    );

    // Get notification launch details BEFORE runApp()
    notificationAppLaunchDetails = await _notificationService
        .flutterLocalNotificationsPlugin
        .getNotificationAppLaunchDetails();

  } catch (e) {
    // Log the error for debugging
    debugPrint('Notification Service Init Error: $e');
    // Continue running the app even if initialization fails
  }

  // Set Only Portrait Orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => EventDatabase(),
          ),
          ChangeNotifierProvider(create: (context) => ThemeProvider())
        ],
        child: const MyApp(),
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Add the global navigator key
      home: const AppInitializer(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Get the HabitDatabase instance from Provider
      final habitDb = Provider.of<EventDatabase>(context, listen: false);

      // Initialize the database
      await habitDb.saveFirstLaunchDate();

      // Load habits from database
      await habitDb.readEvents();

      // *** MODIFICATION: CHECK FOR ALARM LAUNCH FIRST ***
      final launchDetails = notificationAppLaunchDetails;
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final String? payload = launchDetails.notificationResponse?.payload;

        if (payload != null && mounted) {
          // The payload is the Reminder ID (string)
          final int reminderId = int.parse(payload);

          // Fetch reminder details from Hive
          final reminderBox = Hive.box<Reminder>('reminders');
          final reminder = reminderBox.get(reminderId);

          if (reminder != null) {
            // Navigate directly to the custom alarm page
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => AlarmOverlayPage(
                reminderId: reminder.id,
                scheduledTime: reminder.scheduledTime,
                description: reminder.description,
                title: reminder.title,
              )),
            );
            return; // Exit initialization, the alarm page is displayed
          }
        }
      }

      // Check welcome status
      await _checkWelcomeStatus();

    } catch (e) {
      debugPrint('Error initializing app: $e');
      // Even if there's an error, proceed to show the app
      await _checkWelcomeStatus();
    }
  }

  Future<void> _checkWelcomeStatus() async {

    final String authKey = 'isAuthenticated';

    try {
      final prefs = await SharedPreferences.getInstance();
      final welcomeShown = prefs.getBool('welcomeShown') ?? false;
      final isAuthenticated = prefs.getBool(authKey) ?? false;

      // Add a small delay to prevent flashing
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Navigate to appropriate page
        if (welcomeShown && !isAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else if (welcomeShown && isAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LocalAuthPage(
              onSuccess: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      return HomePage();
                    })
                );
              },
            )),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WelcomePage()),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking welcome status: $e');
      // Default to showing welcome page if there's an error
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while initializing
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 10,
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing Data...',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }
}
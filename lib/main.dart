import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendify/authentication/auth_page.dart';
import 'package:attendify/database/event_database.dart';
import 'package:attendify/pages/welcome_page.dart';
import 'package:attendify/pages/home_page.dart';
import 'package:attendify/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and HabitDatabase
  await EventDatabase.initialize();

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
      await habitDb.readHabits();

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
            MaterialPageRoute(builder: (context) => AuthPage(
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
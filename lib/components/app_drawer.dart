import 'package:flutter/material.dart';
import 'package:attendify/pages/analytics_page.dart';
import 'package:attendify/pages/settings_page.dart';
import 'package:attendify/themes/theme_provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../pages/remainder_list_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header Section with SVG
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Lottie.asset(
                    'assets/lottie/app_logo_anim.json',
                    height: 120,
                    width: 120,
                    repeat: true
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ATTENDIFY',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inverseSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  Text(
                    'TRACK YOUR ATTENDANCE',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 50),
          // Menu Items List
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // HOME menu item
                ListTile(
                  leading: const Icon(
                    Iconsax.home,
                    color: Colors.grey,
                    size: 28,
                  ),
                  title: Text(
                    'HOME',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Add navigation action here
                  },
                ),

                // SETTINGS menu item
                ListTile(
                  leading: const Icon(
                    Iconsax.setting_2,
                    color: Colors.grey,
                    size: 28,
                  ),
                  title: Text(
                    'SETTINGS',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Add navigation action here
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                  },
                ),

                // ANALYTICS menu item
                ListTile(
                  leading: const Icon(
                    Iconsax.chart_1,
                    color: Colors.grey,
                    size: 28,
                  ),
                  title: Text(
                    'ANALYTICS',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to analytics page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AnalyticsPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Iconsax.timer_start,
                    color: Colors.grey,
                    size: 28,
                  ),
                  title: Text(
                    'REMINDERS',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to analytics page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReminderListScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Iconsax.note,
                    color: Colors.grey,
                    size: 28,
                  ),
                  title: Text(
                    'MY-NOTES',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to analytics page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReminderListScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Theme toggle at bottom (replacing LOGOUT)
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: ListTile(
              leading: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => Icon(
                  themeProvider.isDarkMode ? Iconsax.moon : Iconsax.sun_1,
                  color: Colors.grey,
                  size: 38,
                ),
              ),
              title: Text(
                'THEME',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              subtitle: Consumer<ThemeProvider>( // Wrap subtitle in Consumer to access themeProvider
                builder: (context, themeProvider, _) => Text(
                  themeProvider.isDarkMode
                      ? 'Dark Mode is ON'.toUpperCase() // Dynamic text based on state
                      : 'Dark Mode is OFF'.toUpperCase(), // Dynamic text based on state
                ),
              ),
              subtitleTextStyle: TextStyle(color: Colors.grey, fontFamily: 'JetBrains Mono', fontSize: 12),
              trailing: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => Switch(
                  activeTrackColor: Colors.green,
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  activeThumbColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
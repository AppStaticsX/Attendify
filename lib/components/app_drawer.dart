import 'package:flutter/material.dart';
import 'package:attendify/pages/analytics_page.dart';
import 'package:attendify/pages/settings_page.dart';
import 'package:attendify/themes/theme_provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

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
                      color: Theme.of(context).colorScheme.inversePrimary,
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
          SizedBox(height: 50,),
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
                    'H O M E',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
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
                    'S E T T I N G S',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
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
                    'A N A L Y T I C S',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
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
                  size: 28,
                ),
              ),
              title: Text(
                'THEME',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              trailing: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => Switch(
                  activeTrackColor: Colors.green,
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  activeColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
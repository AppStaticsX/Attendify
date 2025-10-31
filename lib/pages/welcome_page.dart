import 'package:attendify/authentication/hybrid_login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:attendify/pages/home_page.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin{
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleOfflineAccountTap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcomeShown', true);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  Future<void> _handleHybridAccountTap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcomeShown', true);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HybridLoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get system brightness
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    // Define colors based on system theme
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final buttonBackgroundColor = isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A);
    final termsTextColor = isDarkMode ? Colors.grey[500]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // App Icon
              SvgPicture.asset(
                'assets/icon/app_logo.svg',
                width: 120,
                height: 120,
              ),

              const SizedBox(height: 30),

              // App Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'Attendify',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'Your personal attendance tracker',
                  style: TextStyle(
                    fontSize: 18,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Open source tag
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: const Text(
                    '#opensource',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF36C897),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // TabBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TabBar(
                  controller: _tabController,
                  labelColor: isDarkMode ? Colors.white : Colors.black,
                  unselectedLabelColor: secondaryTextColor,
                  indicatorColor: const Color(0xFF36C897),
                  indicator: BoxDecoration(
                    color: const Color(0xFF36C897).withValues(alpha: 0.2),
                  ),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorAnimation: TabIndicatorAnimation.elastic,
                  tabs: const [
                    Tab(text: 'Go Offline'),
                    Tab(text: 'Go Hybird'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 250,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: OfflineAccount(
                        offlineAccountTap: () => _handleOfflineAccountTap(context),
                        isDarkMode: isDarkMode,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        buttonBackgroundColor: buttonBackgroundColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: HybridAccount(
                        hybridAccountTap: () => _handleHybridAccountTap(context),
                        isDarkMode: isDarkMode,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        buttonBackgroundColor: buttonBackgroundColor,
                      ),
                    )
                  ],
                ),
              ),

              // Terms and conditions
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: termsTextColor,
                          fontFamily: 'JetBrains Mono',
                          height: 1.4,
                        ),
                        children: const [
                          TextSpan(text: 'By signing in, you accept our ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              )),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              color: Color(0xFF36C897),
                              fontWeight: FontWeight.w900,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' and ',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              )),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Color(0xFF36C897),
                              fontWeight: FontWeight.w900,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfflineAccount extends StatelessWidget {
  final VoidCallback offlineAccountTap;
  final bool isDarkMode;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color buttonBackgroundColor;

  const OfflineAccount({
    super.key,
    required this.offlineAccountTap,
    required this.isDarkMode,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.buttonBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter with Offline Account',
          style: TextStyle(
            fontSize: 16,
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),

        Text(
          'Your data will be stored locally on your device. If you uninstall the app or switch devices, you may lose your data. To prevent this, we recommend that you regularly export your backups.',
          style: TextStyle(
            fontSize: 12,
            color: secondaryTextColor,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 24),

        // Offline account button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: offlineAccountTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonBackgroundColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 12),
                Text(
                  'Offline Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HybridAccount extends StatelessWidget {
  final VoidCallback hybridAccountTap;
  final bool isDarkMode;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color buttonBackgroundColor;

  const HybridAccount({
    super.key,
    required this.hybridAccountTap,
    required this.isDarkMode,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.buttonBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter with Hybrid Account',
          style: TextStyle(
            fontSize: 16,
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),

        Text(
          'Your data will be stored locally + cloud storage. If you uninstall the app or switch devices, you may not lose your data. We recommend that you continue with hybrid account.',
          style: TextStyle(
            fontSize: 12,
            color: secondaryTextColor,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 24),

        // Hybrid account button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: hybridAccountTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonBackgroundColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.cloud_add,
                  size: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 12),
                Text(
                  'Hybrid Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
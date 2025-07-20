import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:attendify/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _handleOfflineAccountTap(BuildContext context) async {
    // Save welcomeShown preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcomeShown', true);

    // Navigate to HomePage
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
              Text(
                'Attendify'.toUpperCase(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Your personal attendance tracker',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 4),

              // Open source tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: const Text(
                  '#opensource',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4ECDC4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Spacer(),

              // Offline account section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENTER WITH OFFLINE ACCOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Your data will be stored locally on your device. If you uninstall the app or switch devices, you may lose your data. To prevent this, we recommend that you regularly export your backups.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
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
                      onPressed: () => _handleOfflineAccountTap(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2A2A),
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
                            Icons.person_outline,
                            size: 24,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Offline account',
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
              ),

              const SizedBox(height: 40),

              // Terms and conditions
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
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
                          color: Color(0xFF4ECDC4),
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: ' and\n',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          )),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: Color(0xFF4ECDC4),
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
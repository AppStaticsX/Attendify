import 'package:attendify/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flame_lottie/flame_lottie.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class HybridLoginPage extends StatefulWidget {
  const HybridLoginPage({super.key});

  @override
  State<HybridLoginPage> createState() => _HybridLoginPageState();
}

class _HybridLoginPageState extends State<HybridLoginPage> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _titleFocused = false;

  void _handleBackNavigation(BuildContext context) {
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
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
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: backgroundColor,
        leading: IconButton(
            onPressed: () => _handleBackNavigation(context),
            icon: Icon(
                Icons.close,
              color: primaryTextColor,
            )
        )
      ),
      body: Center(
        child: Column(
          children: [
            Lottie.asset(
              'assets/lottie/app_logo_anim.json',
              width: 130
            ),
            Text(
              'Attendify',
              style: TextStyle(
                color: primaryTextColor.withValues(alpha: 0.8),
                fontSize: 26,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildTextField(
                controller: _emailController,
                hint: 'Email',
                icon: Iconsax.send_1,
                isFocused: _titleFocused,
                maxLines: 1,
                onFocusChange: (focused) {
                  setState(() {
                    _titleFocused = focused;
                  });
                },
                focusedColor: buttonBackgroundColor,
                nonFocusedColor: buttonBackgroundColor,
                iconColor: primaryTextColor,
                textColor: primaryTextColor
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildTextField(
                controller: _emailController,
                hint: 'Email',
                icon: Iconsax.send_1,
                isFocused: _titleFocused,
                maxLines: 1,
                onFocusChange: (focused) {
                  setState(() {
                    _titleFocused = focused;
                  });
                },
                focusedColor: buttonBackgroundColor,
                nonFocusedColor: buttonBackgroundColor,
                iconColor: primaryTextColor,
                textColor: primaryTextColor
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? label,
    required String hint,
    required IconData icon,
    required bool isFocused,
    required Color iconColor,
    required Color textColor,
    required int maxLines,
    required Color focusedColor,
    required Color nonFocusedColor,
    required Function(bool) onFocusChange,
    String? Function(String?)? validator,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: TextFormField(
        maxLines: maxLines,
        controller: controller,
        validator: validator,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: isFocused
                ? Theme.of(context)
                .colorScheme
                .inversePrimary
                .withValues(alpha: 0.7)
                : Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.4),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .inversePrimary
                  .withValues(alpha: 0.7),
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
              width: 2.0,
            ),
          ),
          filled: true,
          fillColor: isFocused
              ? focusedColor
              : nonFocusedColor,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/local_auth_service.dart';

class AddPinPage extends StatefulWidget {
  const AddPinPage({super.key});

  @override
  State<AddPinPage> createState() => _AddPinPageState();
}

class _AddPinPageState extends State<AddPinPage> {

  bool isAuthenticated = false;
  final TextEditingController pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAuthState();
  }

  _loadAuthState() async {
    bool authState = await LocalAuthService.getAuthState();
    setState(() {
      isAuthenticated = authState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .surface,
      appBar: AppBar(
        title: Text(
          'Authentication'
        ),
        actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Switch(
              activeColor: Colors.white,
              activeTrackColor: Colors.green,
              value: isAuthenticated,
              onChanged: (bool value) async {
                try {
                  final prefs = await SharedPreferences.getInstance();
                  String? savedPIN = prefs.getString('pinKEY');

                  if (savedPIN != null && savedPIN.isNotEmpty) {
                    setState(() {
                      isAuthenticated = value;
                    });
                    // Save to persistent storage
                    await LocalAuthService.saveAuthState(value);
                  } else {
                    setState(() {
                      isAuthenticated = false;
                    });
                    _showCustomToast(
                        'Please set-up New PIN first.',
                        Iconsax.warning_2);
                  }
                } catch (e) {
                  setState(() {
                    isAuthenticated = false;
                  });
                  _showCustomToast(
                      'An error occurred.',
                      Iconsax.close_circle);
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Icon(Icons.password_outlined, size: 80, color: Theme
                    .of(context)
                    .colorScheme
                    .inversePrimary),
                const SizedBox(height: 32),
                Text(
                  'Add New PIN',
                  style: TextStyle(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .inversePrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please enter your 4-digit PIN',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey
                  ),
                ),
                const SizedBox(height: 32),
                Pinput(
                  controller: pinController,
                  length: 4,
                  textInputAction: TextInputAction.done,
                  obscuringWidget: Icon(Icons.circle),
                  keyboardType: TextInputType.number,
                  defaultPinTheme: PinTheme(
                    width: 56,
                    height: 56,
                    textStyle: TextStyle(fontSize: 24),
                    decoration: BoxDecoration(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .secondary,
                      border: Border.all(color: Colors.grey, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: false,
                  autofocus: true,
                  errorText: 'Entered PIN is Incorrect',
                  errorTextStyle: TextStyle(
                      color: Colors.red
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32),
                  child: ElevatedButton(
                    onPressed: () {
                      _saveEnteredPin();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2A2A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.import_2,
                            size: 24,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Save PIN',
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
                ),
              ],
            ),
          )
      ),
    );
  }

  Future<void> _saveEnteredPin() async {
    final String newPin = pinController.text.trim();

    try {
      if (newPin.length == 4) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pinKEY', newPin);
        _showCustomToast(
            'New PIN saved successfully.',
            Iconsax.tick_circle);
      } else {
        _showCustomToast(
            'PIN must have 4-digits. Please enter valid PIN',
            Iconsax.close_circle);
      }
    } catch (e) {
      debugPrint(e.toString());
      _showCustomToast(
          'An error occurred',
          Iconsax.close_circle);
    }
  }

  void _showCustomToast(String message, IconData icon,
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

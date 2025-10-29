import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthPage extends StatefulWidget {
  final VoidCallback onSuccess;

  const LocalAuthPage({
    super.key,
    required this.onSuccess
  });

  @override
  State<LocalAuthPage> createState() => _LocalAuthPageState();
}

class _LocalAuthPageState extends State<LocalAuthPage> {
  final LocalAuthentication auth = LocalAuthentication();
  String pin = '1234';
  final TextEditingController textController = TextEditingController();
  bool isBiometricAvailable = false;
  bool isLoading = false;
  bool showError = false;

  @override
  void initState() {
    super.initState();
    _getSavedPin();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      bool available = await auth.canCheckBiometrics;
      setState(() {
        isBiometricAvailable = available;
      });
    } catch (e){
      debugPrint(e.toString());
    }
  }

  Future<void> _getSavedPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedPIN = prefs.getString('pinKEY');

      if (savedPIN != null && savedPIN.isNotEmpty) {
        setState(() {
          pin = savedPIN;
        });
      } else {
        setState(() {
          pin = '1234';
        });
      }
    } catch (e) {
      setState(() {
        pin = '1234';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(),
      body: SafeArea(
          child: Center(
            child: Column(
              children: [
                Icon(Icons.lock_open_sharp, size: 80, color: Theme.of(context).colorScheme.inversePrimary),
                const SizedBox(height: 32),
                Text(
                  'Enter PIN',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
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
                  controller: textController,
                  length: 4,
                  textInputAction: TextInputAction.done,
                  obscuringWidget: Icon(Icons.circle),
                  keyboardType: TextInputType.number,
                  defaultPinTheme: PinTheme(
                    width: 56,
                    height: 56,
                    textStyle: TextStyle(fontSize: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      border: Border.all(color: Colors.grey, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: false,
                  autofocus: true,
                  forceErrorState: showError,
                  errorText: showError ? 'Entered PIN is Incorrect' : null,
                  errorTextStyle: const TextStyle(
                      color: Colors.red
                  ),
                  onCompleted: _onCompleted,
                ),
                Spacer(),
                if(isBiometricAvailable)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      children: [
                        Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.inversePrimary,
                              width: 2
                            )
                          ),
                          child: isLoading
                          ? CircularProgressIndicator(
                            strokeWidth: 5,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                          ): IconButton(
                              onPressed: () {
                                _bioMetricAuthentication();
                              },
                              icon: Icon(Icons.fingerprint_rounded, size: 36, color: Theme.of(context).colorScheme.inversePrimary,)),
                        )
                      ],
                    ),
                  )
              ],
            ),
          )
      ),
    );
  }

  void _onCompleted(String enteredPin) {
    if (enteredPin == pin) {
      setState(() {
        showError = false;
      });
      widget.onSuccess(); // Call the callback instead of direct navigation
    } else {
      setState(() {
        showError = true;
      });
      textController.clear();
      // Clear error after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            showError = false;
          });
        }
      });
    }
  }

  Future<void> _bioMetricAuthentication() async {
    if(!isBiometricAvailable) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      bool authenticate = await auth.authenticate(
        localizedReason:
        'Use your fingerprint to unlock the app',
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );

      if (authenticate) {
        widget.onSuccess();
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally{
      setState(() {
        isLoading = false;
      });
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_lottie/flame_lottie.dart';
import 'dart:ui';
import 'dart:io';

class AlarmOverlayPage extends StatefulWidget {
  final int reminderId;
  final DateTime scheduledTime;
  final String description;

  const AlarmOverlayPage({
    super.key,
    required this.reminderId,
    required this.scheduledTime,
    required this.description,
  });

  @override
  State<AlarmOverlayPage> createState() => _AlarmOverlayPageState();
}

class _AlarmOverlayPageState extends State<AlarmOverlayPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeApp() {
    if (Platform.isAndroid) {
      // For Android: This exits the app completely
      SystemNavigator.pop();
      // For a more forceful exit (optional, use with caution):
      // exit(0);
    } else if (Platform.isIOS) {
      // For iOS: Apple doesn't recommend programmatic exit
      // but this will minimize the app
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Base gradient background
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade50,
                      Colors.blue.shade50,
                      Colors.purple.shade50,
                      Colors.pink.shade50,
                    ],
                    stops: [
                      _animationController.value * 0.3,
                      0.3 + _animationController.value * 0.2,
                      0.6 + _animationController.value * 0.2,
                      0.9 + _animationController.value * 0.1,
                    ],
                  ),
                ),
              );
            },
          ),

          // Liquid floating blobs
          ...List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final offset = (index + 1) * 0.2;
                final animValue = (_animationController.value + offset) % 1.0;
                final size = MediaQuery.of(context).size;

                return Positioned(
                  left: size.width * animValue - 100,
                  top: size.height * ((index * 0.2 + animValue * 0.3) % 1.0),
                  child: Container(
                    width: 200 + (index * 50),
                    height: 200 + (index * 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.4),
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Glass morphism effect overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),

          // Additional glass layer for depth
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),

          // Content (simple, no glass effects)
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lottie Animation
                  Lottie.asset(
                    'assets/lottie/alarm_clock.json',
                    width: 300,
                    height: 300,
                    fit: BoxFit.fill,
                  ),

                  const SizedBox(height: 40),

                  // Reminder Details
                  Text(
                    '${widget.scheduledTime.hour.toString().padLeft(2, '0')}:${widget.scheduledTime.minute.toString().padLeft(2, '0')} ${widget.scheduledTime.hour >= 12 ? 'PM' : 'AM'}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      shadows: const [
                        Shadow(
                          blurRadius: 20,
                          color: Colors.black12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        shadows: const [
                          Shadow(
                            blurRadius: 15,
                            color: Colors.black12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),

                  // Dismiss Button
                  ElevatedButton(
                    onPressed: _closeApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      elevation: 8,
                      shadowColor: Colors.black26,
                    ),
                    child: const Text(
                      'DISMISS ALARM',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
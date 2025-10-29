import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  fontFamily: 'JetBrains Mono',
    colorScheme: ColorScheme.dark(
      surface: const Color(0xFF1A1A1A), //0xFF151515
      primary: Colors.grey.shade600,
      secondary: const Color(0xFF0F0F0F),
      tertiary: const Color(0xFF2C2C2C),
      inversePrimary: Colors.grey.shade300,
    ),
);
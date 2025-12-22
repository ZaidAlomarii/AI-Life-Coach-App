import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'AI Life Coach';
  static const String appVersion = '1.0.0';
  
  // Shared Preferences Keys
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyUserName = 'user_name';
  static const String keyFirstLaunch = 'first_launch';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF0055FF);
  static const Color primaryLight = Color(0xFFEDF4FF);
  static const Color primaryDark = Color(0xFF0044CC);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF00C853);
  static const Color accent = Color(0xFFFF6D00);
  
  // Neutral Colors
  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF2B2B2B);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
  
  // Mood Colors
  static const Color moodGreat = Color(0xFF4CAF50);
  static const Color moodGood = Color(0xFF8BC34A);
  static const Color moodNeutral = Color(0xFFFFEB3B);
  static const Color moodBad = Color(0xFFFF9800);
  static const Color moodTerrible = Color(0xFFE53935);
}

class AppIcons {
  // Habit Icons
  static const List<IconData> habitIcons = [
    Icons.water_drop,
    Icons.menu_book,
    Icons.fitness_center,
    Icons.self_improvement,
    Icons.directions_walk,
    Icons.bedtime,
    Icons.restaurant,
    Icons.code,
    Icons.music_note,
    Icons.brush,
    Icons.savings,
    Icons.favorite,
  ];
  
  // Habit Colors
  static const List<Color> habitColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF3F51B5), // Indigo
  ];
}

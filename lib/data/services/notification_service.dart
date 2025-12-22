import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Initialize notifications
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('✅ Notification Service initialized');
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  // Request permissions (for Android 13+)
  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  // ============================================
  // Schedule Habit Reminder
  // ============================================
  Future<void> scheduleHabitReminder({
    required int id,
    required String habitName,
    required TimeOfDay time,
    required List<int> days, // 1 = Monday, 7 = Sunday
  }) async {
    await init();

    final now = DateTime.now();
    
    for (int day in days) {
      // Calculate next occurrence of this day
      int daysUntil = day - now.weekday;
      if (daysUntil < 0) daysUntil += 7;
      if (daysUntil == 0 && (now.hour > time.hour || (now.hour == time.hour && now.minute >= time.minute))) {
        daysUntil += 7;
      }

      final scheduledDate = DateTime(
        now.year,
        now.month,
        now.day + daysUntil,
        time.hour,
        time.minute,
      );

      await _notifications.zonedSchedule(
        id + day, // Unique ID for each day
        '⏰ Habit Reminder',
        "Time for $habitName! Don't break your streak 🔥",
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Habit Reminders',
            channelDescription: 'Reminders for your daily habits',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF2196F3),
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'habit_$id',
      );
    }

    debugPrint('✅ Scheduled reminder for $habitName at ${time.hour}:${time.minute}');
  }

  // ============================================
  // Schedule Daily Motivation
  // ============================================
  Future<void> scheduleDailyMotivation({
    required TimeOfDay time,
  }) async {
    await init();

    final messages = [
      "Good morning! 🌅 Ready to crush your goals today?",
      "Rise and shine! ☀️ Your habits are waiting for you!",
      "New day, new opportunities! 💪 Let's make it count!",
      "Hey champion! 🏆 Time to build those healthy habits!",
      "You've got this! 🌟 Every small step matters!",
    ];

    final randomMessage = messages[DateTime.now().day % messages.length];

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      0, // ID for daily motivation
      '🌟 Daily Motivation',
      randomMessage,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_motivation',
          'Daily Motivation',
          channelDescription: 'Daily motivational messages',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4CAF50),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_motivation',
    );

    debugPrint('✅ Scheduled daily motivation at ${time.hour}:${time.minute}');
  }

  // ============================================
  // Schedule Mood Check-in
  // ============================================
  Future<void> scheduleMoodReminder({
    required TimeOfDay time,
  }) async {
    await init();

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      999, // ID for mood reminder
      '😊 How are you feeling?',
      'Take a moment to log your mood and track your wellbeing.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'mood_reminders',
          'Mood Reminders',
          channelDescription: 'Reminders to log your mood',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFF9800),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'mood_reminder',
    );

    debugPrint('✅ Scheduled mood reminder at ${time.hour}:${time.minute}');
  }

  // ============================================
  // Show Instant Notification
  // ============================================
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'General Notifications',
          channelDescription: 'General app notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ============================================
  // Show Habit Completed Notification
  // ============================================
  Future<void> showHabitCompletedNotification(String habitName, int streak) async {
    String message;
    if (streak >= 7) {
      message = "Amazing! You're on a $streak day streak! 🔥🔥🔥";
    } else if (streak >= 3) {
      message = "Great job! $streak days in a row! Keep it up! 🔥";
    } else {
      message = "Well done! Keep building that habit! 💪";
    }

    await showNotification(
      title: '✅ $habitName completed!',
      body: message,
      payload: 'habit_completed',
    );
  }

  // ============================================
  // Cancel Notifications
  // ============================================
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelHabitReminders(int habitId) async {
    // Cancel for all days (1-7)
    for (int day = 1; day <= 7; day++) {
      await _notifications.cancel(habitId + day);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // ============================================
  // Save/Load Settings
  // ============================================
  Future<void> saveNotificationSettings({
    required bool enabled,
    required bool dailyMotivation,
    required TimeOfDay motivationTime,
    required bool moodReminder,
    required TimeOfDay moodTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    await prefs.setBool('daily_motivation', dailyMotivation);
    await prefs.setInt('motivation_hour', motivationTime.hour);
    await prefs.setInt('motivation_minute', motivationTime.minute);
    await prefs.setBool('mood_reminder', moodReminder);
    await prefs.setInt('mood_hour', moodTime.hour);
    await prefs.setInt('mood_minute', moodTime.minute);

    // Apply settings
    if (enabled) {
      if (dailyMotivation) {
        await scheduleDailyMotivation(time: motivationTime);
      }
      if (moodReminder) {
        await scheduleMoodReminder(time: moodTime);
      }
    } else {
      await cancelAllNotifications();
    }
  }

  Future<Map<String, dynamic>> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('notifications_enabled') ?? true,
      'dailyMotivation': prefs.getBool('daily_motivation') ?? true,
      'motivationTime': TimeOfDay(
        hour: prefs.getInt('motivation_hour') ?? 9,
        minute: prefs.getInt('motivation_minute') ?? 0,
      ),
      'moodReminder': prefs.getBool('mood_reminder') ?? true,
      'moodTime': TimeOfDay(
        hour: prefs.getInt('mood_hour') ?? 20,
        minute: prefs.getInt('mood_minute') ?? 0,
      ),
    };
  }
}

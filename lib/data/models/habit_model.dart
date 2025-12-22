import 'package:flutter/material.dart';

enum GoalType { yesNo, count }

enum HabitFrequency { daily, weekly, custom }

class HabitModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final GoalType goalType;
  final int targetCount; // For count type
  final List<int> frequencyDays; // 0 = Sunday, 6 = Saturday
  final TimeOfDay? reminderTime;
  final bool reminderEnabled;
  final DateTime createdAt;
  final Map<String, HabitLog> logs; // date string -> log

  HabitModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.goalType = GoalType.yesNo,
    this.targetCount = 1,
    this.frequencyDays = const [0, 1, 2, 3, 4, 5, 6], // All days by default
    this.reminderTime,
    this.reminderEnabled = false,
    required this.createdAt,
    this.logs = const {},
  });

  // Calculate completion for today
  bool get isCompletedToday {
    final today = _dateKey(DateTime.now());
    final log = logs[today];
    if (log == null) return false;
    
    if (goalType == GoalType.yesNo) {
      return log.completed;
    } else {
      return log.count >= targetCount;
    }
  }

  // Get today's progress (0.0 - 1.0)
  double get todayProgress {
    final today = _dateKey(DateTime.now());
    final log = logs[today];
    if (log == null) return 0.0;
    
    if (goalType == GoalType.yesNo) {
      return log.completed ? 1.0 : 0.0;
    } else {
      return (log.count / targetCount).clamp(0.0, 1.0);
    }
  }

  // Get today's count
  int get todayCount {
    final today = _dateKey(DateTime.now());
    return logs[today]?.count ?? 0;
  }

  // Calculate streak
  int get currentStreak {
    int streak = 0;
    DateTime date = DateTime.now();
    
    // If not completed today, start from yesterday
    if (!isCompletedToday) {
      date = date.subtract(const Duration(days: 1));
    }
    
    while (true) {
      final key = _dateKey(date);
      final log = logs[key];
      
      // Check if this day is a scheduled day
      if (!frequencyDays.contains(date.weekday % 7)) {
        date = date.subtract(const Duration(days: 1));
        continue;
      }
      
      if (log == null || !_isLogComplete(log)) {
        break;
      }
      
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  // Calculate weekly completion rate
  double get weeklyCompletionRate {
    int completed = 0;
    int total = 0;
    
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      if (!frequencyDays.contains(date.weekday % 7)) continue;
      
      total++;
      final log = logs[_dateKey(date)];
      if (log != null && _isLogComplete(log)) {
        completed++;
      }
    }
    
    return total > 0 ? completed / total : 0.0;
  }

  // Get frequency text
  String get frequencyText {
    if (frequencyDays.length == 7) {
      return 'Every day';
    } else {
      return '${frequencyDays.length}x per week';
    }
  }

  bool _isLogComplete(HabitLog log) {
    if (goalType == GoalType.yesNo) {
      return log.completed;
    } else {
      return log.count >= targetCount;
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Copy with
  HabitModel copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    GoalType? goalType,
    int? targetCount,
    List<int>? frequencyDays,
    TimeOfDay? reminderTime,
    bool? reminderEnabled,
    DateTime? createdAt,
    Map<String, HabitLog>? logs,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      goalType: goalType ?? this.goalType,
      targetCount: targetCount ?? this.targetCount,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
      logs: logs ?? this.logs,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
      'goalType': goalType.index,
      'targetCount': targetCount,
      'frequencyDays': frequencyDays,
      'reminderHour': reminderTime?.hour,
      'reminderMinute': reminderTime?.minute,
      'reminderEnabled': reminderEnabled,
      'createdAt': createdAt.toIso8601String(),
      'logs': logs.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  // From JSON
  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'],
      name: json['name'],
      icon: IconData(json['iconCodePoint'], fontFamily: 'MaterialIcons'),
      color: Color(json['colorValue']),
      goalType: GoalType.values[json['goalType']],
      targetCount: json['targetCount'],
      frequencyDays: List<int>.from(json['frequencyDays']),
      reminderTime: json['reminderHour'] != null
          ? TimeOfDay(hour: json['reminderHour'], minute: json['reminderMinute'])
          : null,
      reminderEnabled: json['reminderEnabled'],
      createdAt: DateTime.parse(json['createdAt']),
      logs: (json['logs'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, HabitLog.fromJson(value)),
          ) ??
          {},
    );
  }
}

class HabitLog {
  final bool completed;
  final int count;
  final DateTime? completedAt;

  HabitLog({
    this.completed = false,
    this.count = 0,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'count': count,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      completed: json['completed'] ?? false,
      count: json['count'] ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

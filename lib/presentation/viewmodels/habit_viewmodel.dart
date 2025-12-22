import 'package:flutter/material.dart';
import '../../data/models/habit_model.dart';
import '../../data/services/local_storage_service.dart';

class HabitViewModel extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();

  List<HabitModel> _habits = [];
  bool _isLoading = true;

  // Getters
  List<HabitModel> get habits => _habits;
  bool get isLoading => _isLoading;

  // Today's progress
  double get todayOverallProgress {
    if (_habits.isEmpty) return 0.0;
    final total = _habits.fold<double>(0, (sum, h) => sum + h.todayProgress);
    return total / _habits.length;
  }

  // Get habits scheduled for today
  List<HabitModel> get todayHabits {
    final today = DateTime.now().weekday % 7;
    return _habits.where((h) => h.frequencyDays.contains(today)).toList();
  }

  // Initialize
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _storage.init();
    _habits = await _storage.getHabits();

    _isLoading = false;
    notifyListeners();
  }

  // Add new habit
  Future<void> addHabit({
    required String name,
    required IconData icon,
    required Color color,
    required GoalType goalType,
    int targetCount = 1,
    required List<int> frequencyDays,
    TimeOfDay? reminderTime,
    bool reminderEnabled = false,
  }) async {
    final habit = HabitModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: icon,
      color: color,
      goalType: goalType,
      targetCount: targetCount,
      frequencyDays: frequencyDays,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
      createdAt: DateTime.now(),
    );

    await _storage.addHabit(habit);
    _habits = await _storage.getHabits();
    notifyListeners();
  }

  // Update habit
  Future<void> updateHabit(HabitModel habit) async {
    await _storage.updateHabit(habit);
    _habits = await _storage.getHabits();
    notifyListeners();
  }

  // Delete habit
  Future<void> deleteHabit(String habitId) async {
    await _storage.deleteHabit(habitId);
    _habits = await _storage.getHabits();
    notifyListeners();
  }

  // Toggle habit completion for today (Yes/No type)
  Future<void> toggleHabitCompletion(String habitId) async {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    
    await _storage.logHabitCompletion(
      habitId,
      completed: !habit.isCompletedToday,
    );
    
    _habits = await _storage.getHabits();
    notifyListeners();
  }

  // Increment habit count (Count type)
  Future<void> incrementHabitCount(String habitId) async {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    final newCount = habit.todayCount + 1;
    
    await _storage.logHabitCompletion(
      habitId,
      count: newCount,
      completed: newCount >= habit.targetCount,
    );
    
    _habits = await _storage.getHabits();
    notifyListeners();
  }

  // Decrement habit count (Count type)
  Future<void> decrementHabitCount(String habitId) async {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    if (habit.todayCount <= 0) return;
    
    final newCount = habit.todayCount - 1;
    
    await _storage.logHabitCompletion(
      habitId,
      count: newCount,
      completed: newCount >= habit.targetCount,
    );
    
    _habits = await _storage.getHabits();
    notifyListeners();
  }

  // Refresh habits
  Future<void> refresh() async {
    _habits = await _storage.getHabits();
    notifyListeners();
  }
}

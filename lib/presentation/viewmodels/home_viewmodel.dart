import 'package:flutter/foundation.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/mood_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/ai_service.dart';

class HomeViewModel extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  final AIService _aiService = AIService();

  List<HabitModel> _habits = [];
  List<MoodEntry> _moods = [];
  MoodSummary? _moodSummary;
  List<Map<String, dynamic>> _suggestions = [];
  String _quote = '"Loading..."';
  String _userName = 'there';
  
  bool _isLoading = true;
  bool _isLoadingQuote = false;
  bool _isLoadingSuggestions = false;

  // Getters
  List<HabitModel> get habits => _habits;
  List<HabitModel> get topHabits => _habits.take(3).toList();
  MoodSummary? get moodSummary => _moodSummary;
  List<Map<String, dynamic>> get suggestions => _suggestions;
  String get quote => _quote;
  String get userName => _userName;
  bool get isLoading => _isLoading;
  bool get isLoadingQuote => _isLoadingQuote;
  bool get isLoadingSuggestions => _isLoadingSuggestions;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // Initialize
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _storage.init();
    await _loadData();
    
    _isLoading = false;
    notifyListeners();

    // Load AI content in background
    _loadAIContent();
  }

  Future<void> _loadData() async {
    _habits = await _storage.getHabits();
    _moods = await _storage.getMoods();
    _userName = await _storage.getUserName() ?? 'there';

    if (_moods.isNotEmpty) {
      _moodSummary = MoodSummary(entries: _moods);
    }
  }

  // Load AI content separately (quote & suggestions)
  Future<void> _loadAIContent() async {
    // Load quote from AI
    _loadQuote();
    
    // Load suggestions from AI
    _loadSuggestions();
  }

  // ============================================
  // AI Quote
  // ============================================
  Future<void> _loadQuote() async {
    _isLoadingQuote = true;
    notifyListeners();

    try {
      // Get current mood to personalize quote
      MoodType? currentMood;
      if (_moods.isNotEmpty) {
        currentMood = _moods.first.mood;
      }

      _quote = await _aiService.generateQuote(currentMood: currentMood);
    } catch (e) {
      _quote = '"Every day is a new opportunity to grow." - AI Life Coach';
    }

    _isLoadingQuote = false;
    notifyListeners();
  }

  // ============================================
  // AI Suggestions
  // ============================================
  Future<void> _loadSuggestions() async {
    if (_habits.isEmpty) {
      _suggestions = [
        {'title': 'Add your first habit', 'type': 'new'},
        {'title': 'Log your mood', 'type': 'quick'},
      ];
      return;
    }

    _isLoadingSuggestions = true;
    notifyListeners();

    try {
      final aiResponse = await _aiService.generateSmartSuggestions(
        habits: _habits,
        moods: _moods,
      );

      _suggestions = [];

      // Add habit suggestions
      if (aiResponse['habitSuggestions'] != null) {
        for (var s in aiResponse['habitSuggestions']) {
          _suggestions.add({
            'title': s['message'] ?? 'Improve your habits',
            'type': 'adjust',
          });
        }
      }

      // Add quick wins
      if (aiResponse['quickWins'] != null) {
        for (var q in aiResponse['quickWins']) {
          _suggestions.add({
            'title': q['text'] ?? 'Quick action',
            'type': 'quick',
          });
        }
      }

      // Limit to 4 suggestions
      _suggestions = _suggestions.take(4).toList();

      // Add defaults if empty
      if (_suggestions.isEmpty) {
        _suggestions = [
          {'title': 'Take a 5-minute walk', 'type': 'quick'},
          {'title': 'Drink more water', 'type': 'quick'},
        ];
      }
    } catch (e) {
      debugPrint('Load suggestions error: $e');
      _suggestions = [
        {'title': 'Take a short break', 'type': 'quick'},
        {'title': 'Stay hydrated', 'type': 'quick'},
      ];
    }

    _isLoadingSuggestions = false;
    notifyListeners();
  }

  // ============================================
  // Quick Toggle Habit
  // ============================================
  Future<void> quickToggleHabit(String habitId) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final habit = _habits[index];
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    Map<String, HabitLog> updatedLogs = Map.from(habit.logs);

    if (habit.goalType == GoalType.yesNo) {
      // Toggle completion
      if (habit.isCompletedToday) {
        updatedLogs.remove(todayKey);
      } else {
        updatedLogs[todayKey] = HabitLog(
          completed: true,
          count: 1,
          completedAt: today,
        );
      }
    }

    final updatedHabit = habit.copyWith(logs: updatedLogs);
    await _storage.updateHabit(updatedHabit);
    
    // Refresh
    _habits = await _storage.getHabits();
    notifyListeners();
  }

  // ============================================
  // Refresh
  // ============================================
  Future<void> refresh() async {
    await _loadData();
    notifyListeners();
    
    // Reload AI content
    _loadAIContent();
  }

  // Refresh quote only
  Future<void> refreshQuote() async {
    await _loadQuote();
  }
}

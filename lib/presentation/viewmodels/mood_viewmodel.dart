import 'package:flutter/foundation.dart';
import '../../data/models/mood_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/ai_service.dart';

class MoodViewModel extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  final AIService _aiService = AIService();

  List<MoodEntry> _moods = [];
  MoodSummary? _moodSummary;
  String _moodAnalysis = '';
  
  bool _isLoading = true;
  bool _isAnalyzing = false;

  // Getters
  List<MoodEntry> get moods => _moods;
  MoodSummary? get moodSummary => _moodSummary;
  MoodSummary? get summary => _moodSummary;
  String get moodAnalysis => _moodAnalysis;
  String get aiAnalysis => _moodAnalysis;
  bool get isLoading => _isLoading;
  bool get isAnalyzing => _isAnalyzing;

  // Today's mood
  MoodEntry? get todayMood {
    if (_moods.isEmpty) return null;
    final today = DateTime.now();
    try {
      return _moods.firstWhere(
        (m) => m.createdAt.year == today.year &&
               m.createdAt.month == today.month &&
               m.createdAt.day == today.day,
      );
    } catch (e) {
      return null;
    }
  }

  bool get hasLoggedToday => todayMood != null;

  // Weekly moods for calendar
  List<MoodEntry?> get weeklyMoods {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    List<MoodEntry?> week = [];
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      try {
        final mood = _moods.firstWhere(
          (m) => m.createdAt.year == day.year &&
                 m.createdAt.month == day.month &&
                 m.createdAt.day == day.day,
        );
        week.add(mood);
      } catch (e) {
        week.add(null);
      }
    }
    return week;
  }

  // Initialize
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _storage.init();
    await _loadMoods();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadMoods() async {
    _moods = await _storage.getMoods();
    _moods.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (_moods.isNotEmpty) {
      _moodSummary = MoodSummary(entries: _moods);
    }
  }

  // ============================================
  // Log Mood
  // ============================================
  Future<void> logMood(MoodType mood, {String? note, List<String>? tags}) async {
    final entry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mood: mood,
      note: note,
      tags: tags ?? [],
      createdAt: DateTime.now(),
    );

    await _storage.addMood(entry);
    await _loadMoods();
    notifyListeners();
  }

  // ============================================
  // AI Analysis - تحليل المزاج بالـ AI
  // ============================================
  Future<void> analyzeMoodPatterns() async {
    if (_moods.isEmpty) {
      _moodAnalysis = "Start logging your mood to get personalized AI insights! 📊";
      notifyListeners();
      return;
    }

    _isAnalyzing = true;
    _moodAnalysis = '';
    notifyListeners();

    try {
      _moodAnalysis = await _aiService.analyzeMoodPatterns(_moods);
    } catch (e) {
      debugPrint('AI Analysis Error: $e');
      _moodAnalysis = "I'm having trouble analyzing your mood right now. Please try again later! 🔄";
    }

    _isAnalyzing = false;
    notifyListeners();
  }

  Future<void> getAIAnalysis() async {
    await analyzeMoodPatterns();
  }

  // Refresh
  Future<void> refresh() async {
    await _loadMoods();
    notifyListeners();
  }
}

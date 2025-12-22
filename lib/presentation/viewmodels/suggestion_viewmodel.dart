import 'package:flutter/foundation.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/mood_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/ai_service.dart';

class SuggestionViewModel extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  final AIService _aiService = AIService();

  List<HabitModel> _habits = [];
  List<MoodEntry> _moods = [];
  
  List<HabitSuggestion> _habitSuggestions = [];
  List<NewHabitSuggestion> _newHabitSuggestions = [];
  List<QuickWin> _quickWins = [];
  String _insight = '';
  
  bool _isLoading = true;
  bool _isGenerating = false;
  String _lastError = '';

  // Getters
  List<HabitSuggestion> get habitSuggestions => _habitSuggestions;
  List<NewHabitSuggestion> get newHabitSuggestions => _newHabitSuggestions;
  List<QuickWin> get quickWins => _quickWins;
  String get insight => _insight;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String get lastError => _lastError;

  // Initialize
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _storage.init();
    await _loadData();
    await generateAISuggestions();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadData() async {
    _habits = await _storage.getHabits();
    _moods = await _storage.getMoods();
  }

  // ============================================
  // توليد اقتراحات من AI
  // ============================================
  Future<void> generateAISuggestions() async {
    _isGenerating = true;
    _lastError = '';
    notifyListeners();

    try {
      // أولاً: توليد Fine-tune suggestions محلياً (لا تحتاج AI)
      _habitSuggestions = _generateLocalHabitSuggestions();

      // ثانياً: محاولة الحصول على اقتراحات من AI
      try {
        final aiResponse = await _aiService.generateSmartSuggestions(
          habits: _habits,
          moods: _moods,
        );

        // Parse new habits from AI
        _newHabitSuggestions = [];
        if (aiResponse['newHabits'] != null) {
          for (var h in aiResponse['newHabits']) {
            _newHabitSuggestions.add(NewHabitSuggestion(
              name: h['name'] ?? '',
              icon: h['icon'] ?? '✨',
              description: h['reason'] ?? '',
            ));
          }
        }

        // Parse quick wins from AI
        _quickWins = [];
        if (aiResponse['quickWins'] != null) {
          for (var q in aiResponse['quickWins']) {
            _quickWins.add(QuickWin(
              icon: q['icon'] ?? '⚡',
              text: q['text'] ?? '',
            ));
          }
        }

        // Get insight
        _insight = aiResponse['insight'] ?? '';
        
      } catch (e) {
        debugPrint('AI not available, using local suggestions: $e');
        // استخدام اقتراحات محلية
      }

      // Add fallbacks if empty
      if (_newHabitSuggestions.isEmpty) {
        _newHabitSuggestions = _getDefaultNewHabits();
      }
      if (_quickWins.isEmpty) {
        _quickWins = _getDefaultQuickWins();
      }
      if (_insight.isEmpty) {
        _insight = 'Keep building healthy habits! Every small step counts 🌟';
      }

    } catch (e) {
      debugPrint('Suggestions Error: $e');
      _lastError = 'Using offline suggestions';
      _setDefaultSuggestions();
    }

    _isGenerating = false;
    notifyListeners();
  }

  // ============================================
  // توليد Fine-tune suggestions محلياً مع Tracking
  // ============================================
  List<HabitSuggestion> _generateLocalHabitSuggestions() {
    List<HabitSuggestion> suggestions = [];
    final now = DateTime.now();

    for (var habit in _habits) {
      final rate = habit.weeklyCompletionRate;
      final ratePercent = (rate * 100).round();
      final daysCompleted = (rate * 7).round();

      // 1. Check if habit is OVERDUE (time passed, not completed)
      if (!habit.isCompletedToday && habit.reminderEnabled && habit.reminderTime != null) {
        final reminderHour = habit.reminderTime!.hour;
        final reminderMinute = habit.reminderTime!.minute;
        
        if (now.hour > reminderHour || 
            (now.hour == reminderHour && now.minute > reminderMinute)) {
          suggestions.add(HabitSuggestion(
            habitName: habit.name,
            habitIcon: _getEmojiForHabit(habit.name),
            currentProgress: 'Overdue!',
            message: "⏰ It's past your ${habit.name} time! Don't break your streak.",
            actionText: 'Do it now',
            actionType: SuggestionActionType.setReminder,
          ));
          continue; // Don't add other suggestions for this habit
        }
      }

      // 2. عادة ضعيفة (أقل من 40%)
      if (rate < 0.4 && rate > 0) {
        String message;
        String action;
        SuggestionActionType actionType;
        int? newTarget;

        if (habit.goalType == GoalType.count) {
          newTarget = (habit.targetCount * 0.6).round();
          if (newTarget < 1) newTarget = 1;
          message = 'Only $daysCompleted/7 days completed. Try lowering target to $newTarget.';
          action = 'Reduce target';
          actionType = SuggestionActionType.reduceTarget;
        } else {
          message = 'Only $daysCompleted/7 days. Maybe try every other day?';
          action = 'Set reminder';
          actionType = SuggestionActionType.setReminder;
        }

        suggestions.add(HabitSuggestion(
          habitName: habit.name,
          habitIcon: _getEmojiForHabit(habit.name),
          currentProgress: '$daysCompleted / 7 days',
          message: message,
          actionText: action,
          actionType: actionType,
          suggestedValue: newTarget,
        ));
      }
      // 3. عادة قوية (أكثر من 80%)
      else if (rate >= 0.8 && habit.currentStreak >= 5) {
        String message;
        String action;
        SuggestionActionType actionType;
        int? newTarget;

        if (habit.goalType == GoalType.count) {
          newTarget = (habit.targetCount * 1.3).round();
          message = "🔥 Amazing $ratePercent%! You're on fire! Increase to $newTarget?";
          action = 'Level up';
          actionType = SuggestionActionType.increaseTarget;
        } else {
          message = "🔥 Incredible! ${habit.currentStreak} day streak! You're crushing it!";
          action = 'Keep going!';
          actionType = SuggestionActionType.setReminder;
        }

        suggestions.add(HabitSuggestion(
          habitName: habit.name,
          habitIcon: _getEmojiForHabit(habit.name),
          currentProgress: '$daysCompleted / 7 days',
          message: message,
          actionText: action,
          actionType: actionType,
          suggestedValue: newTarget,
        ));
      }
      // 4. عادة متوسطة (40-60%)
      else if (rate >= 0.4 && rate < 0.6) {
        suggestions.add(HabitSuggestion(
          habitName: habit.name,
          habitIcon: _getEmojiForHabit(habit.name),
          currentProgress: '$daysCompleted / 7 days',
          message: "You're at $ratePercent%! A reminder could help you stay consistent.",
          actionText: 'Set reminder',
          actionType: SuggestionActionType.setReminder,
        ));
      }
      // 5. عادة جديدة (لم تبدأ بعد)
      else if (rate == 0 && habit.logs.isEmpty) {
        suggestions.add(HabitSuggestion(
          habitName: habit.name,
          habitIcon: _getEmojiForHabit(habit.name),
          currentProgress: 'Not started',
          message: "Start today! The first step is always the hardest. 💪",
          actionText: 'Start now',
          actionType: SuggestionActionType.setReminder,
        ));
      }
    }

    // Sort: Overdue first, then low completion, then others
    suggestions.sort((a, b) {
      if (a.currentProgress == 'Overdue!') return -1;
      if (b.currentProgress == 'Overdue!') return 1;
      if (a.currentProgress == 'Not started') return -1;
      if (b.currentProgress == 'Not started') return 1;
      return 0;
    });

    return suggestions.take(4).toList();
  }

  // ============================================
  // Helpers
  // ============================================
  String _getActionText(String? action) {
    switch (action) {
      case 'reduce_target':
        return 'Reduce target';
      case 'increase_target':
        return 'Increase target';
      case 'set_reminder':
        return 'Set reminder';
      default:
        return 'Apply';
    }
  }

  SuggestionActionType _parseActionType(String? action) {
    switch (action) {
      case 'reduce_target':
        return SuggestionActionType.reduceTarget;
      case 'increase_target':
        return SuggestionActionType.increaseTarget;
      case 'set_reminder':
        return SuggestionActionType.setReminder;
      default:
        return SuggestionActionType.setReminder;
    }
  }

  void _setDefaultSuggestions() {
    _habitSuggestions = [];
    _newHabitSuggestions = _getDefaultNewHabits();
    _quickWins = _getDefaultQuickWins();
    _insight = 'Keep building healthy habits! Every small step counts 🌟';
  }

  List<NewHabitSuggestion> _getDefaultNewHabits() {
    List<NewHabitSuggestion> suggestions = [];
    
    // تحليل المزاج الأخير
    MoodType? recentMood;
    if (_moods.isNotEmpty) {
      recentMood = _moods.first.mood;
    }

    // اقتراحات حسب المزاج
    if (recentMood == MoodType.terrible || recentMood == MoodType.bad) {
      // مزاج سيء = اقتراحات للاسترخاء
      suggestions.addAll([
        NewHabitSuggestion(
          name: '2-min Breathing',
          icon: '🧘',
          description: 'You seem stressed. Deep breathing can help calm your mind.',
        ),
        NewHabitSuggestion(
          name: 'Gratitude Journal',
          icon: '📝',
          description: 'Write 3 things you\'re grateful for to shift your perspective.',
        ),
        NewHabitSuggestion(
          name: 'Short Walk',
          icon: '🚶',
          description: 'A quick walk can boost your mood and clear your mind.',
        ),
      ]);
    } else if (recentMood == MoodType.great || recentMood == MoodType.good) {
      // مزاج جيد = تحديات أكبر
      suggestions.addAll([
        NewHabitSuggestion(
          name: 'Morning Workout',
          icon: '💪',
          description: 'Great energy! Channel it into a workout routine.',
        ),
        NewHabitSuggestion(
          name: 'Learn Something New',
          icon: '📚',
          description: 'Your positive mood is perfect for learning!',
        ),
        NewHabitSuggestion(
          name: 'Meditation',
          icon: '🧘',
          description: 'Maintain this great energy with daily meditation.',
        ),
      ]);
    } else {
      // مزاج محايد = اقتراحات عامة
      suggestions.addAll([
        NewHabitSuggestion(
          name: 'Drink Water',
          icon: '💧',
          description: 'Stay hydrated for better focus and energy.',
        ),
        NewHabitSuggestion(
          name: '2-min Breathing',
          icon: '🧘',
          description: 'Quick breathing exercises to reduce stress.',
        ),
        NewHabitSuggestion(
          name: 'Daily Walk',
          icon: '🚶',
          description: 'Boost your mood with a short daily walk.',
        ),
      ]);
    }

    // تجنب اقتراح عادات موجودة
    final existingNames = _habits.map((h) => h.name.toLowerCase()).toSet();
    suggestions = suggestions.where((s) => 
      !existingNames.any((name) => s.name.toLowerCase().contains(name) || name.contains(s.name.toLowerCase()))
    ).toList();

    // إضافة اقتراحات إضافية إذا لزم الأمر
    if (suggestions.length < 2) {
      if (!existingNames.any((n) => n.contains('sleep'))) {
        suggestions.add(NewHabitSuggestion(
          name: 'Sleep Early',
          icon: '🌙',
          description: 'Quality sleep improves everything.',
        ));
      }
      if (!existingNames.any((n) => n.contains('read'))) {
        suggestions.add(NewHabitSuggestion(
          name: 'Read 10 Pages',
          icon: '📖',
          description: 'Expand your knowledge daily.',
        ));
      }
    }

    return suggestions.take(4).toList();
  }

  List<QuickWin> _getDefaultQuickWins() {
    List<QuickWin> wins = [];
    final now = DateTime.now();
    
    // 1. Add OVERDUE habits first (highest priority)
    for (var habit in _habits) {
      if (!habit.isCompletedToday && habit.reminderEnabled && habit.reminderTime != null) {
        final reminderHour = habit.reminderTime!.hour;
        final reminderMinute = habit.reminderTime!.minute;
        
        if (now.hour > reminderHour || 
            (now.hour == reminderHour && now.minute > reminderMinute)) {
          wins.add(QuickWin(
            icon: '⏰',
            text: '${habit.name} is overdue! Do it now',
            habitId: habit.id,
          ));
        }
      }
    }

    // 2. Add incomplete habits for today
    for (var habit in _habits) {
      if (!habit.isCompletedToday && 
          !wins.any((w) => w.habitId == habit.id)) {
        wins.add(QuickWin(
          icon: _getEmojiForHabit(habit.name),
          text: 'Complete ${habit.name}',
          habitId: habit.id,
        ));
      }
    }

    // 3. Add general quick wins based on time of day
    if (now.hour < 12) {
      // Morning
      wins.addAll([
        QuickWin(icon: '💧', text: 'Start your day with a glass of water'),
        QuickWin(icon: '🧘', text: 'Take 3 deep breaths'),
      ]);
    } else if (now.hour < 17) {
      // Afternoon
      wins.addAll([
        QuickWin(icon: '🚶', text: 'Take a 5-minute walk'),
        QuickWin(icon: '💧', text: 'Stay hydrated - drink water'),
      ]);
    } else {
      // Evening
      wins.addAll([
        QuickWin(icon: '🙏', text: "Write 1 thing you're grateful for"),
        QuickWin(icon: '📵', text: 'Put your phone away for 15 min'),
      ]);
    }

    return wins.take(4).toList();
  }

  String _getEmojiForHabit(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('water') || nameLower.contains('drink')) return '💧';
    if (nameLower.contains('read')) return '📖';
    if (nameLower.contains('exercise') || nameLower.contains('gym')) return '💪';
    if (nameLower.contains('walk')) return '🚶';
    if (nameLower.contains('meditat') || nameLower.contains('breath')) return '🧘';
    if (nameLower.contains('sleep') || nameLower.contains('bed')) return '🌙';
    if (nameLower.contains('journal') || nameLower.contains('writ')) return '📝';
    return '✨';
  }

  // ============================================
  // Apply suggestion
  // ============================================
  Future<void> applySuggestion(HabitSuggestion suggestion) async {
    // Find habit by name
    final habitIndex = _habits.indexWhere(
      (h) => h.name.toLowerCase() == suggestion.habitName.toLowerCase()
    );
    if (habitIndex == -1) return;

    final habit = _habits[habitIndex];
    HabitModel? updatedHabit;

    switch (suggestion.actionType) {
      case SuggestionActionType.reduceTarget:
        if (habit.goalType == GoalType.count && suggestion.suggestedValue != null) {
          updatedHabit = habit.copyWith(targetCount: suggestion.suggestedValue);
        }
        break;
      case SuggestionActionType.increaseTarget:
        if (habit.goalType == GoalType.count && suggestion.suggestedValue != null) {
          updatedHabit = habit.copyWith(targetCount: suggestion.suggestedValue);
        }
        break;
      case SuggestionActionType.setReminder:
        updatedHabit = habit.copyWith(reminderEnabled: true);
        break;
    }

    if (updatedHabit != null) {
      await _storage.updateHabit(updatedHabit);
    }

    // Refresh
    await _loadData();
    await generateAISuggestions();
  }

  // Refresh
  Future<void> refresh() async {
    await _loadData();
    await generateAISuggestions();
  }
}

// ============================================
// Models
// ============================================
class HabitSuggestion {
  final String habitName;
  final String habitIcon;
  final String currentProgress;
  final String message;
  final String actionText;
  final SuggestionActionType actionType;
  final int? suggestedValue;

  HabitSuggestion({
    required this.habitName,
    this.habitIcon = '✨',
    required this.currentProgress,
    required this.message,
    required this.actionText,
    required this.actionType,
    this.suggestedValue,
  });
}

class NewHabitSuggestion {
  final String name;
  final String icon;
  final String description;

  NewHabitSuggestion({
    required this.name,
    required this.icon,
    required this.description,
  });
}

class QuickWin {
  final String icon;
  final String text;
  final String? habitId;

  QuickWin({
    required this.icon,
    required this.text,
    this.habitId,
  });
}

enum SuggestionActionType {
  reduceTarget,
  increaseTarget,
  setReminder,
}

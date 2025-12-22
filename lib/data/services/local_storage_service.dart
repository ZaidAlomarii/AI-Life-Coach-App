import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit_model.dart';
import '../models/mood_model.dart';
import '../models/chat_message.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _habitsKey = 'habits';
  static const String _moodsKey = 'moods';
  static const String _chatHistoryKey = 'chat_history';
  static const String _userNameKey = 'user_name';
  static const String _onboardingKey = 'onboarding_completed';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============ HABITS ============

  Future<List<HabitModel>> getHabits() async {
    await _ensureInitialized();
    final String? habitsJson = _prefs?.getString(_habitsKey);
    if (habitsJson == null) return [];

    try {
      final List<dynamic> habitsList = jsonDecode(habitsJson);
      return habitsList.map((h) => HabitModel.fromJson(h)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveHabits(List<HabitModel> habits) async {
    await _ensureInitialized();
    final habitsJson = jsonEncode(habits.map((h) => h.toJson()).toList());
    await _prefs?.setString(_habitsKey, habitsJson);
  }

  Future<void> addHabit(HabitModel habit) async {
    final habits = await getHabits();
    habits.add(habit);
    await saveHabits(habits);
  }

  Future<void> updateHabit(HabitModel habit) async {
    final habits = await getHabits();
    final index = habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      habits[index] = habit;
      await saveHabits(habits);
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final habits = await getHabits();
    habits.removeWhere((h) => h.id == habitId);
    await saveHabits(habits);
  }

  Future<void> logHabitCompletion(String habitId, {bool? completed, int? count}) async {
    final habits = await getHabits();
    final index = habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    final habit = habits[index];
    final today = _dateKey(DateTime.now());
    
    final newLogs = Map<String, HabitLog>.from(habit.logs);
    final currentLog = newLogs[today] ?? HabitLog();
    
    newLogs[today] = HabitLog(
      completed: completed ?? currentLog.completed,
      count: count ?? currentLog.count,
      completedAt: DateTime.now(),
    );

    habits[index] = habit.copyWith(logs: newLogs);
    await saveHabits(habits);
  }

  // ============ MOODS ============

  Future<List<MoodEntry>> getMoods() async {
    await _ensureInitialized();
    final String? moodsJson = _prefs?.getString(_moodsKey);
    if (moodsJson == null) return [];

    try {
      final List<dynamic> moodsList = jsonDecode(moodsJson);
      return moodsList.map((m) => MoodEntry.fromJson(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveMoods(List<MoodEntry> moods) async {
    await _ensureInitialized();
    final moodsJson = jsonEncode(moods.map((m) => m.toJson()).toList());
    await _prefs?.setString(_moodsKey, moodsJson);
  }

  Future<void> addMood(MoodEntry mood) async {
    final moods = await getMoods();
    moods.insert(0, mood); // Add to beginning (most recent first)
    await saveMoods(moods);
  }

  Future<MoodEntry?> getTodayMood() async {
    final moods = await getMoods();
    final today = _dateKey(DateTime.now());
    
    try {
      return moods.firstWhere((m) => _dateKey(m.createdAt) == today);
    } catch (e) {
      return null;
    }
  }

  // ============ CHAT HISTORY ============

  Future<List<ChatMessage>> getChatHistory() async {
    await _ensureInitialized();
    final String? chatJson = _prefs?.getString(_chatHistoryKey);
    if (chatJson == null) return [];

    try {
      final List<dynamic> chatList = jsonDecode(chatJson);
      return chatList.map((c) => ChatMessage.fromJson(c)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    await _ensureInitialized();
    // Keep only last 100 messages
    final recentMessages = messages.length > 100 
        ? messages.sublist(messages.length - 100) 
        : messages;
    final chatJson = jsonEncode(recentMessages.map((c) => c.toJson()).toList());
    await _prefs?.setString(_chatHistoryKey, chatJson);
  }

  Future<void> addChatMessage(ChatMessage message) async {
    final messages = await getChatHistory();
    messages.add(message);
    await saveChatHistory(messages);
  }

  Future<void> clearChatHistory() async {
    await _ensureInitialized();
    await _prefs?.remove(_chatHistoryKey);
  }

  // ============ USER SETTINGS ============

  Future<String?> getUserName() async {
    await _ensureInitialized();
    return _prefs?.getString(_userNameKey);
  }

  Future<void> setUserName(String name) async {
    await _ensureInitialized();
    await _prefs?.setString(_userNameKey, name);
  }

  Future<bool> isOnboardingCompleted() async {
    await _ensureInitialized();
    return _prefs?.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _ensureInitialized();
    await _prefs?.setBool(_onboardingKey, completed);
  }

  // ============ HELPERS ============

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> clearAllData() async {
    await _ensureInitialized();
    await _prefs?.clear();
  }
}

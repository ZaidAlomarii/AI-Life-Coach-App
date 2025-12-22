import 'package:flutter/foundation.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/mood_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/ai_service.dart';

class ChatViewModel extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  final AIService _aiService = AIService();

  List<ChatMessage> _messages = [];
  List<HabitModel> _habits = [];
  List<MoodEntry> _moods = [];
  
  bool _isLoading = true;
  bool _isTyping = false;

  // Getters
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;

  // Initialize
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _storage.init();
    _messages = await _storage.getChatHistory();
    _habits = await _storage.getHabits();
    _moods = await _storage.getMoods();

    // Add welcome message if empty
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(
        id: 'welcome',
        text: "Hi! 👋 I'm your AI Life Coach. I'm here to help you build healthy habits and improve your wellbeing. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
      await _storage.saveChatHistory(_messages);
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============================================
  // Send Message to AI
  // ============================================
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    // Show typing indicator
    _isTyping = true;
    notifyListeners();

    try {
      // Refresh data for context
      _habits = await _storage.getHabits();
      _moods = await _storage.getMoods();

      // Get AI response with context
      final response = await _aiService.sendMessage(
        text,
        habits: _habits,
        recentMoods: _moods.take(7).toList(),
      );

      // Add AI response
      final aiMessage = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMessage);

      // Save to storage
      await _storage.saveChatHistory(_messages);
    } catch (e) {
      debugPrint('Chat Error: $e');
      
      // Add error message
      final errorMessage = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_error',
        text: "I'm having trouble connecting right now. Please try again! 🔄",
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    }

    _isTyping = false;
    notifyListeners();
  }

  // ============================================
  // Quick Actions
  // ============================================
  Future<void> askForHabitAdvice() async {
    await sendMessage("Can you give me advice on my habits?");
  }

  Future<void> askForMoodAnalysis() async {
    await sendMessage("Can you analyze my mood patterns?");
  }

  Future<void> askForMotivation() async {
    await sendMessage("I need some motivation today!");
  }

  Future<void> askForWeeklySummary() async {
    await sendMessage("Give me a summary of my week");
  }

  // ============================================
  // Clear History
  // ============================================
  Future<void> clearHistory() async {
    _messages = [
      ChatMessage(
        id: 'welcome',
        text: "Hi! 👋 I'm your AI Life Coach. I'm here to help you build healthy habits and improve your wellbeing. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
    await _storage.saveChatHistory(_messages);
    notifyListeners();
  }

  // Refresh
  Future<void> refresh() async {
    _habits = await _storage.getHabits();
    _moods = await _storage.getMoods();
    notifyListeners();
  }
}

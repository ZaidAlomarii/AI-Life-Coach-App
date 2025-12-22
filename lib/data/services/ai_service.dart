import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/habit_model.dart';
import '../models/mood_model.dart';
import '../../core/constants/api_constants.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // System prompt for the AI Life Coach
  static const String _systemPrompt = '''
You are an AI Life Coach assistant in a mobile app. Your role is to:
1. Help users build and maintain healthy habits
2. Provide motivational support and encouragement
3. Give practical advice for personal development
4. Analyze mood patterns and suggest improvements
5. Offer smart suggestions based on user's habits and mood

IMPORTANT GUIDELINES:
- Be friendly, supportive, and concise
- Use emojis to add warmth 😊
- Keep responses brief (2-3 sentences max unless more detail is needed)
- Always be positive and encouraging
- Give actionable advice
- Speak in a conversational tone
- Respond in the same language the user uses
''';

  // ============================================
  // 1. CHAT - محادثة مع المستخدم
  // ============================================
  Future<String> sendMessage(String message, {
    List<HabitModel>? habits,
    List<MoodEntry>? recentMoods,
    String? userName,
  }) async {
    try {
      String context = _systemPrompt;
      
      if (userName != null) {
        context += '\n\nUser\'s name: $userName';
      }
      
      if (habits != null && habits.isNotEmpty) {
        context += '\n\n📊 USER\'S CURRENT HABITS:';
        for (var h in habits) {
          context += '\n- ${h.name}: ${(h.weeklyCompletionRate * 100).round()}% this week, streak: ${h.currentStreak} days';
        }
      }
      
      if (recentMoods != null && recentMoods.isNotEmpty) {
        final moodSummary = MoodSummary(entries: recentMoods);
        context += '\n\n😊 USER\'S RECENT MOOD:';
        context += '\n- Dominant mood: ${moodSummary.dominantMood.label} ${moodSummary.dominantMood.emoji}';
        context += '\n- Average score: ${moodSummary.weeklyAverage.toStringAsFixed(1)}/5';
      }

      final response = await _callGroqAPI(context, message);
      return response;
    } catch (e) {
      debugPrint('AI Chat Error: $e');
      return "I'm having trouble connecting right now. Please try again! 🔄";
    }
  }

  // ============================================
  // 2. SMART SUGGESTIONS - اقتراحات ذكية
  // ============================================
  Future<Map<String, dynamic>> generateSmartSuggestions({
    required List<HabitModel> habits,
    required List<MoodEntry> moods,
  }) async {
    try {
      String habitsData = '';
      for (var h in habits) {
        final rate = (h.weeklyCompletionRate * 100).round();
        final streak = h.currentStreak;
        final completed = h.isCompletedToday ? 'done today' : 'not done today';
        habitsData += '- ${h.name}: $rate% weekly, $streak day streak, $completed\n';
      }

      String moodData = '';
      final recentMoods = moods.take(7).toList();
      for (var m in recentMoods) {
        moodData += '- ${m.mood.label} (${m.mood.emoji})\n';
      }

      final prompt = '''
Analyze user data and generate JSON suggestions.

HABITS:
$habitsData

MOODS (last 7):
$moodData

Return ONLY valid JSON (no markdown):
{
  "habitSuggestions": [
    {"habitName": "name", "icon": "emoji", "currentRate": "X/7", "message": "advice", "action": "reduce_target|increase_target|set_reminder"}
  ],
  "newHabits": [
    {"name": "habit", "icon": "emoji", "reason": "why suggested"}
  ],
  "quickWins": [
    {"icon": "emoji", "text": "quick action"}
  ],
  "insight": "one sentence insight"
}

Max 3 items per array. Be specific and actionable.
''';

      final response = await _callGroqAPI(_systemPrompt, prompt);
      
      try {
        String cleanResponse = response
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final data = jsonDecode(cleanResponse);
        return data as Map<String, dynamic>;
      } catch (e) {
        debugPrint('JSON Parse Error: $e');
        return _getDefaultSuggestionsMap();
      }
    } catch (e) {
      debugPrint('Smart Suggestions Error: $e');
      return _getDefaultSuggestionsMap();
    }
  }

  // ============================================
  // 3. QUOTE OF THE DAY - اقتباس اليوم
  // ============================================
  Future<String> generateQuote({MoodType? currentMood, String? userName}) async {
    try {
      String moodContext = '';
      if (currentMood != null) {
        moodContext = 'User is feeling: ${currentMood.label} ${currentMood.emoji}. ';
      }
      if (userName != null) {
        moodContext += 'User\'s name is $userName. ';
      }

      final prompt = '''
$moodContext
Generate a short, inspiring quote about personal growth, habits, or self-improvement.
Return ONLY the quote in this format: "Quote text" - Author
Keep it under 15 words. If original, use "- AI Life Coach".
''';

      final response = await _callGroqAPI(_systemPrompt, prompt);
      return response.trim();
    } catch (e) {
      debugPrint('Quote Error: $e');
      return '"Small steps every day lead to big changes over time." - AI Life Coach';
    }
  }

  // ============================================
  // 4. MOOD ANALYSIS - تحليل المزاج
  // ============================================
  Future<String> analyzeMoodPatterns(List<MoodEntry> moods, {String? userName}) async {
    if (moods.isEmpty) {
      return "Start logging your mood to get personalized insights! 📊";
    }

    try {
      String moodData = '';
      for (var m in moods.take(14)) {
        final day = _getDayName(m.createdAt.weekday);
        moodData += '- $day: ${m.mood.label} ${m.mood.emoji}';
        if (m.note != null && m.note!.isNotEmpty) {
          moodData += ' (note: ${m.note})';
        }
        moodData += '\n';
      }

      final prompt = '''
Analyze these mood entries (last 2 weeks):
$moodData

${userName != null ? 'User name: $userName' : ''}

Provide brief analysis (3-4 sentences):
1. Overall pattern/trend
2. Notable patterns (certain days worse/better)
3. One specific actionable suggestion

Be supportive and use emojis.
''';

      return await _callGroqAPI(_systemPrompt, prompt);
    } catch (e) {
      debugPrint('Mood Analysis Error: $e');
      return "Keep tracking your mood to discover patterns! 📈";
    }
  }

  // ============================================
  // 5. HABIT ADVICE - نصيحة للعادة
  // ============================================
  Future<String> getHabitAdvice(HabitModel habit) async {
    try {
      final rate = (habit.weeklyCompletionRate * 100).round();
      final streak = habit.currentStreak;

      final prompt = '''
Give brief advice for this habit:

Habit: ${habit.name}
Weekly completion: $rate%
Current streak: $streak days
Completed today: ${habit.isCompletedToday ? 'Yes' : 'No'}

Provide 2-3 sentences of specific, actionable advice.
Be encouraging! Use emojis.
''';

      return await _callGroqAPI(_systemPrompt, prompt);
    } catch (e) {
      return "Keep going! Consistency is key to building lasting habits 💪";
    }
  }

  // ============================================
  // 6. WEEKLY SUMMARY - ملخص أسبوعي
  // ============================================
  Future<String> generateWeeklySummary({
    required List<HabitModel> habits,
    required List<MoodEntry> moods,
    String? userName,
  }) async {
    try {
      String habitsData = '';
      int totalCompleted = 0;
      int totalPossible = 0;
      
      for (var h in habits) {
        final completed = (h.weeklyCompletionRate * 7).round();
        totalCompleted += completed;
        totalPossible += 7;
        habitsData += '- ${h.name}: $completed/7 days, streak: ${h.currentStreak}\n';
      }

      String moodData = 'No mood data';
      final weekMoods = moods.where((m) => 
        m.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))
      ).toList();
      
      if (weekMoods.isNotEmpty) {
        final avgMood = weekMoods.map((m) => m.mood.value).reduce((a, b) => a + b) / weekMoods.length;
        moodData = 'Average mood: ${avgMood.toStringAsFixed(1)}/5';
      }

      final prompt = '''
Generate weekly summary for ${userName ?? 'user'}:

HABITS:
$habitsData
Overall: $totalCompleted/$totalPossible completed

MOOD: $moodData

Write motivating 3-4 sentence summary:
1. Highlight wins
2. Acknowledge challenges  
3. Encourage for next week

Use emojis, be warm and supportive!
''';

      return await _callGroqAPI(_systemPrompt, prompt);
    } catch (e) {
      return "Great job this week! Keep building those healthy habits 🌟";
    }
  }

  // ============================================
  // 7. DAILY PLANNER - خطة اليوم (NEW!)
  // ============================================
  Future<String> generateDailyPlan({
    required List<HabitModel> habits,
    MoodType? currentMood,
    String? userName,
  }) async {
    try {
      String habitsData = habits.map((h) => 
        '- ${h.name} (${h.isCompletedToday ? "done" : "pending"})'
      ).join('\n');

      final prompt = '''
Create a simple daily plan for ${userName ?? 'user'}.

Pending habits:
$habitsData

Current mood: ${currentMood?.label ?? 'Unknown'}

Suggest optimal order and timing for habits.
Keep it brief (4-5 lines max). Use emojis.
''';

      return await _callGroqAPI(_systemPrompt, prompt);
    } catch (e) {
      return "Start with your easiest habit to build momentum! 💪";
    }
  }

  // ============================================
  // 8. STREAK MOTIVATION - تحفيز (NEW!)
  // ============================================
  Future<String> getStreakMotivation(HabitModel habit) async {
    try {
      final streak = habit.currentStreak;
      
      final prompt = '''
User has a $streak day streak for "${habit.name}".
Give a short, exciting motivational message (1-2 sentences).
${streak >= 7 ? 'Celebrate this achievement!' : 'Encourage them to keep going!'}
Use emojis!
''';

      return await _callGroqAPI(_systemPrompt, prompt);
    } catch (e) {
      if (habit.currentStreak >= 7) {
        return "🔥 Amazing! ${habit.currentStreak} days strong! You're unstoppable!";
      }
      return "Keep going! Every day counts! 💪";
    }
  }

  // ============================================
  // 9. HABIT DIFFICULTY ANALYSIS (NEW!)
  // ============================================
  Future<Map<String, String>> analyzeHabitDifficulty(List<HabitModel> habits) async {
    Map<String, String> difficulties = {};
    
    for (var habit in habits) {
      final rate = habit.weeklyCompletionRate;
      if (rate >= 0.8) {
        difficulties[habit.name] = '⭐ Easy';
      } else if (rate >= 0.5) {
        difficulties[habit.name] = '⭐⭐ Medium';
      } else if (rate > 0) {
        difficulties[habit.name] = '⭐⭐⭐ Hard';
      } else {
        difficulties[habit.name] = '🆕 New';
      }
    }
    
    return difficulties;
  }

  // ============================================
  // PRIVATE: Groq API Call
  // ============================================
  Future<String> _callGroqAPI(String systemPrompt, String userMessage) async {
    try {
      final url = Uri.parse(ApiConstants.chatEndpoint);
      
      final body = jsonEncode({
        'model': ApiConstants.groqModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': 0.7,
        'max_tokens': 1024,
      });

      debugPrint('🔵 Calling Groq API...');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.groqApiKey}',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('🔴 API Timeout');
          throw Exception('Request timeout');
        },
      );

      debugPrint('🟢 API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'];
        return text ?? "I couldn't generate a response. Please try again.";
      } else {
        debugPrint('🔴 Groq API Error: ${response.statusCode} - ${response.body}');
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 API Exception: $e');
      rethrow;
    }
  }

  // ============================================
  // HELPERS
  // ============================================
  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  Map<String, dynamic> _getDefaultSuggestionsMap() {
    return {
      'habitSuggestions': [],
      'newHabits': [
        {'name': 'Drink Water', 'icon': '💧', 'reason': 'Stay hydrated for better focus'},
        {'name': '2-min Breathing', 'icon': '🧘', 'reason': 'Reduce stress and anxiety'},
      ],
      'quickWins': [
        {'icon': '🚶', 'text': 'Take a 5-minute walk'},
        {'icon': '💧', 'text': 'Drink a glass of water'},
        {'icon': '🙏', 'text': 'Write one thing you\'re grateful for'},
      ],
      'insight': 'Keep building healthy habits! Every small step counts 🌟',
    };
  }
}

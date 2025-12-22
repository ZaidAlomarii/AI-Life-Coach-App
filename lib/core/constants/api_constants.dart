import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Groq API - جلب المفتاح من ملف .env بدلاً من كتابته هنا
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqModel = 'llama-3.3-70b-versatile';
  
  // API Endpoints
  static String get chatEndpoint => '$groqBaseUrl/chat/completions';
}
/*class ApiConstants {
  // Groq API
  static const String groqApiKey = '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';
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqModel = 'llama-3.3-70b-versatile';
  
  // API Endpoints
  static String get chatEndpoint => '$groqBaseUrl/chat/completions';
}
*/
enum MessageType { text, suggestion, action }

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final MessageType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.type = MessageType.text,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      text: json['text'],
      isUser: json['isUser'],
      type: MessageType.values[json['type'] ?? 0],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }
}

class Suggestion {
  final String id;
  final String title;
  final String description;
  final SuggestionType type;
  final String? actionText;
  final Map<String, dynamic>? actionData;

  Suggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.actionText,
    this.actionData,
  });
}

enum SuggestionType {
  habitAdjustment,
  newHabit,
  quickWin,
  moodBased,
}

extension SuggestionTypeExtension on SuggestionType {
  String get icon {
    switch (this) {
      case SuggestionType.habitAdjustment:
        return '🔧';
      case SuggestionType.newHabit:
        return '✨';
      case SuggestionType.quickWin:
        return '⚡';
      case SuggestionType.moodBased:
        return '💭';
    }
  }
}

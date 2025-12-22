enum MoodType {
  great,
  good,
  neutral,
  bad,
  terrible,
}

extension MoodTypeExtension on MoodType {
  String get emoji {
    switch (this) {
      case MoodType.great:
        return '😄';
      case MoodType.good:
        return '🙂';
      case MoodType.neutral:
        return '😐';
      case MoodType.bad:
        return '😟';
      case MoodType.terrible:
        return '😢';
    }
  }

  String get label {
    switch (this) {
      case MoodType.great:
        return 'Great';
      case MoodType.good:
        return 'Good';
      case MoodType.neutral:
        return 'Okay';
      case MoodType.bad:
        return 'Bad';
      case MoodType.terrible:
        return 'Terrible';
    }
  }

  int get value {
    switch (this) {
      case MoodType.great:
        return 5;
      case MoodType.good:
        return 4;
      case MoodType.neutral:
        return 3;
      case MoodType.bad:
        return 2;
      case MoodType.terrible:
        return 1;
    }
  }
}

class MoodEntry {
  final String id;
  final MoodType mood;
  final String? note;
  final List<String> tags;
  final DateTime createdAt;

  MoodEntry({
    required this.id,
    required this.mood,
    this.note,
    this.tags = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood': mood.index,
      'note': note,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'],
      mood: MoodType.values[json['mood']],
      note: json['note'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  MoodEntry copyWith({
    String? id,
    MoodType? mood,
    String? note,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MoodSummary {
  final List<MoodEntry> entries;

  MoodSummary({required this.entries});

  // Get average mood for the week
  double get weeklyAverage {
    if (entries.isEmpty) return 3.0;
    
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekEntries = entries.where((e) => e.createdAt.isAfter(weekAgo)).toList();
    
    if (weekEntries.isEmpty) return 3.0;
    
    final sum = weekEntries.fold<int>(0, (sum, e) => sum + e.mood.value);
    return sum / weekEntries.length;
  }

  // Get dominant mood for the week
  MoodType get dominantMood {
    if (entries.isEmpty) return MoodType.neutral;
    
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekEntries = entries.where((e) => e.createdAt.isAfter(weekAgo)).toList();
    
    if (weekEntries.isEmpty) return MoodType.neutral;
    
    final counts = <MoodType, int>{};
    for (final entry in weekEntries) {
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
    }
    
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Get mood description
  String get weeklyDescription {
    final avg = weeklyAverage;
    if (avg >= 4.5) return "You've been feeling amazing this week!";
    if (avg >= 3.5) return "You've been mostly calm and focused this week.";
    if (avg >= 2.5) return "It's been an okay week with some ups and downs.";
    if (avg >= 1.5) return "This week has been a bit challenging.";
    return "It's been a tough week. Remember, it's okay to ask for help.";
  }

  // Get recent emojis (last 7 entries)
  List<String> get recentEmojis {
    return entries
        .take(7)
        .map((e) => e.mood.emoji)
        .toList();
  }
}

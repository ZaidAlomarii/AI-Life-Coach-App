import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/mood_model.dart';

class MoodSummaryCard extends StatelessWidget {
  final MoodSummary? moodSummary;

  const MoodSummaryCard({super.key, this.moodSummary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mood Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Emoji row
          Row(
            children: (moodSummary?.recentEmojis.isEmpty ?? true)
                ? [
                    Text(
                      '—',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ]
                : moodSummary!.recentEmojis
                    .take(6)
                    .map((emoji) => Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Text(emoji, style: const TextStyle(fontSize: 18)),
                        ))
                    .toList(),
          ),
          const SizedBox(height: 12),
          Text(
            (moodSummary?.entries.isEmpty ?? true)
                ? 'Start tracking your mood!'
                : moodSummary!.weeklyDescription,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

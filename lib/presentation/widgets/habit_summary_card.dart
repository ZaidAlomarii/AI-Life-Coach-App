import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/habit_model.dart';

class HabitSummaryCard extends StatelessWidget {
  final List<HabitModel> habits;

  const HabitSummaryCard({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Habit\nSummary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (habits.isEmpty)
            Text(
              'No habits yet',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            )
          else
            ...habits.take(2).map((habit) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Text('— ', style: TextStyle(color: AppColors.primary)),
                      Expanded(
                        child: Text(
                          habit.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          if (habits.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildProgressBar(habits.first),
            const SizedBox(height: 4),
            Text(
              '${(habits.first.weeklyCompletionRate * 7).round()}/7 days',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(HabitModel habit) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: habit.weeklyCompletionRate,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

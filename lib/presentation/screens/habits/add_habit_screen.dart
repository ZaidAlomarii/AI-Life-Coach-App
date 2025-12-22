import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/habit_model.dart';
import '../../../data/models/mood_model.dart';
import '../../viewmodels/habit_viewmodel.dart';
import '../../viewmodels/mood_viewmodel.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  GoalType _goalType = GoalType.yesNo;
  int _targetCount = 3;
  List<int> _selectedDays = [0, 1, 2, 3, 4, 5, 6];
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _reminderEnabled = true;
  int _selectedIconIndex = 0;
  int _selectedColorIndex = 0;

  final List<String> _dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  // Suggested Habits based on Mood
  List<SuggestedHabit> _getSuggestedHabits(MoodType? currentMood) {
    final allSuggestions = [
      // For stressed/bad mood
      SuggestedHabit(
        name: '2-min Breathing',
        icon: Icons.self_improvement,
        color: const Color(0xFF9C27B0),
        forMoods: [MoodType.bad, MoodType.terrible],
        description: 'Reduce stress with deep breathing',
      ),
      SuggestedHabit(
        name: 'Take a Walk',
        icon: Icons.directions_walk,
        color: const Color(0xFF4CAF50),
        forMoods: [MoodType.bad, MoodType.terrible, MoodType.neutral],
        description: 'Clear your mind with a short walk',
      ),
      SuggestedHabit(
        name: 'Gratitude Journal',
        icon: Icons.edit_note,
        color: const Color(0xFFFF9800),
        forMoods: [MoodType.bad, MoodType.terrible],
        description: 'Write 3 things you\'re grateful for',
      ),
      // For neutral mood
      SuggestedHabit(
        name: 'Drink Water',
        icon: Icons.water_drop,
        color: const Color(0xFF2196F3),
        forMoods: [MoodType.neutral, MoodType.good, MoodType.great],
        description: 'Stay hydrated throughout the day',
      ),
      SuggestedHabit(
        name: 'Read 10 Pages',
        icon: Icons.menu_book,
        color: const Color(0xFFFF5722),
        forMoods: [MoodType.neutral, MoodType.good],
        description: 'Expand your knowledge daily',
      ),
      // For good/great mood
      SuggestedHabit(
        name: 'Exercise',
        icon: Icons.fitness_center,
        color: const Color(0xFFE91E63),
        forMoods: [MoodType.good, MoodType.great],
        description: 'Build strength and energy',
      ),
      SuggestedHabit(
        name: 'Meditation',
        icon: Icons.self_improvement,
        color: const Color(0xFF00BCD4),
        forMoods: [MoodType.good, MoodType.great, MoodType.neutral],
        description: 'Find inner peace',
      ),
      SuggestedHabit(
        name: 'Learn Something New',
        icon: Icons.school,
        color: const Color(0xFF3F51B5),
        forMoods: [MoodType.great],
        description: 'Challenge yourself daily',
      ),
      // General
      SuggestedHabit(
        name: 'Sleep Early',
        icon: Icons.bedtime,
        color: const Color(0xFF673AB7),
        forMoods: null, // for all
        description: 'Get quality rest',
      ),
      SuggestedHabit(
        name: 'No Social Media',
        icon: Icons.phone_android,
        color: const Color(0xFF607D8B),
        forMoods: null,
        description: 'Digital detox for focus',
      ),
    ];

    if (currentMood == null) {
      return allSuggestions.take(6).toList();
    }

    // Filter by mood and add general ones
    final moodBased = allSuggestions
        .where((s) => s.forMoods?.contains(currentMood) ?? true)
        .take(6)
        .toList();

    return moodBased;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectSuggestedHabit(SuggestedHabit habit) {
    setState(() {
      _nameController.text = habit.name;
      _selectedIconIndex = AppIcons.habitIcons.indexWhere(
        (icon) => icon.codePoint == habit.icon.codePoint,
      );
      if (_selectedIconIndex == -1) _selectedIconIndex = 0;
      
      _selectedColorIndex = AppIcons.habitColors.indexWhere(
        (color) => color.value == habit.color.value,
      );
      if (_selectedColorIndex == -1) _selectedColorIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodViewModel>(
      builder: (context, moodViewModel, child) {
        final currentMood = moodViewModel.todayMood?.mood;
        final suggestedHabits = _getSuggestedHabits(currentMood);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Add Habit',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Suggested Habits
                  _buildSuggestedHabits(suggestedHabits, currentMood),
                  
                  const SizedBox(height: 24),

                  // Or create custom
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or create your own',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Habit Name
                  _buildSectionTitle('Habit Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Drink water',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a habit name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Frequency
                  _buildFrequencySection(),

                  const SizedBox(height: 24),

                  // Reminder Time
                  _buildReminderSection(),

                  const SizedBox(height: 24),

                  // Goal Type
                  _buildGoalTypeSection(),

                  const SizedBox(height: 24),

                  // Icon & Color
                  _buildIconColorSection(),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveHabit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Save Habit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestedHabits(List<SuggestedHabit> habits, MoodType? mood) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              mood != null
                  ? 'Suggested for your mood ${mood.emoji}'
                  : 'Popular Habits',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return GestureDetector(
                onTap: () => _selectSuggestedHabit(habit),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: habit.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: habit.color.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(habit.icon, color: habit.color, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: habit.color,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Frequency'),
            Switch(
              value: _selectedDays.length == 7,
              onChanged: (value) {
                setState(() {
                  _selectedDays = value ? [0, 1, 2, 3, 4, 5, 6] : [];
                });
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final isSelected = _selectedDays.contains(index);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDays.remove(index);
                  } else {
                    _selectedDays.add(index);
                  }
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _dayNames[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Reminder Time'),
            Switch(
              value: _reminderEnabled,
              onChanged: (value) {
                setState(() {
                  _reminderEnabled = value;
                });
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _reminderEnabled ? _selectTime : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: _reminderEnabled ? AppColors.primary : Colors.grey[400],
                ),
                const SizedBox(width: 12),
                Text(
                  _reminderTime.format(context),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _reminderEnabled ? AppColors.textPrimary : Colors.grey[400],
                  ),
                ),
                const Spacer(),
                if (_reminderEnabled)
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Goal Type'),
        const SizedBox(height: 8),
        Text(
          _goalType == GoalType.yesNo
              ? 'Yes/No for simple habits like Reading, Exercise...'
              : 'Use Count for glasses of water, pages read, etc.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildGoalTypeButton('Yes/No', GoalType.yesNo),
            const SizedBox(width: 12),
            _buildGoalTypeButton('Count', GoalType.count),
          ],
        ),
        if (_goalType == GoalType.count) ...[
          const SizedBox(height: 16),
          _buildSectionTitle('Target per day'),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCountButton(Icons.remove, () {
                if (_targetCount > 1) {
                  setState(() => _targetCount--);
                }
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '$_targetCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildCountButton(Icons.add, () {
                setState(() => _targetCount++);
              }),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGoalTypeButton(String label, GoalType type) {
    final isSelected = _goalType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _goalType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  Widget _buildIconColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Icon & Color'),
        const SizedBox(height: 4),
        Text(
          'Tap to customize how this habit looks',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppIcons.habitColors[_selectedColorIndex].withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                AppIcons.habitIcons[_selectedIconIndex],
                color: AppIcons.habitColors[_selectedColorIndex],
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppIcons.habitColors[_selectedColorIndex],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: _showIconColorPicker,
              child: const Text(
                'Change',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  void _showIconColorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose Icon',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(AppIcons.habitIcons.length, (index) {
                      final isSelected = _selectedIconIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => _selectedIconIndex = index);
                          setState(() {});
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            AppIcons.habitIcons[index],
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Choose Color',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(AppIcons.habitColors.length, (index) {
                      final isSelected = _selectedColorIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => _selectedColorIndex = index);
                          setState(() {});
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppIcons.habitColors[index],
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: Colors.black, width: 3)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _saveHabit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    context.read<HabitViewModel>().addHabit(
          name: _nameController.text,
          icon: AppIcons.habitIcons[_selectedIconIndex],
          color: AppIcons.habitColors[_selectedColorIndex],
          goalType: _goalType,
          targetCount: _targetCount,
          frequencyDays: _selectedDays,
          reminderTime: _reminderEnabled ? _reminderTime : null,
          reminderEnabled: _reminderEnabled,
        );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Habit added successfully! 🎉'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class SuggestedHabit {
  final String name;
  final IconData icon;
  final Color color;
  final List<MoodType>? forMoods;
  final String description;

  SuggestedHabit({
    required this.name,
    required this.icon,
    required this.color,
    this.forMoods,
    required this.description,
  });
}

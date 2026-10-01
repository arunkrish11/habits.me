import 'package:flutter/material.dart';

import '../data/app_database.dart';

const habitIcons = <IconData>[
  Icons.check_circle_outline,
  Icons.menu_book,
  Icons.fitness_center,
  Icons.directions_run,
  Icons.self_improvement,
  Icons.water_drop,
  Icons.bedtime,
  Icons.wb_sunny,
  Icons.music_note,
  Icons.code,
  Icons.brush,
  Icons.savings,
  Icons.restaurant,
  Icons.school,
  Icons.work,
  Icons.language,
  Icons.favorite,
  Icons.pets,
  Icons.edit_note,
  Icons.cleaning_services,
  Icons.directions_bike,
  Icons.smoke_free,
  Icons.no_drinks,
  Icons.phone_android,
];

// Shows the habit's emoji if it has one, otherwise its icon
class HabitIcon extends StatelessWidget {
  const HabitIcon(this.habit, {super.key, this.size = 24});
  final Habit habit;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (habit.emoji.isNotEmpty) {
      return Text(habit.emoji, style: TextStyle(fontSize: size));
    }
    return Icon(
      habitIcons[habit.icon.clamp(0, habitIcons.length - 1)],
      size: size,
    );
  }
}

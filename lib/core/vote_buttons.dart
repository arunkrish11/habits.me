import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import 'date_utils.dart';
import 'theme.dart';

class VoteButtons extends ConsumerWidget {
  const VoteButtons({
    super.key,
    required this.habitId,
    required this.status, // status of the shown day: 1, -1 or 0
    required this.percent,
    this.day, // yyyy-MM-dd, defaults to today
  });
  final int habitId;
  final int status;
  final int percent;
  final String? day;

  Widget _box(
    IconData icon,
    bool active,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? activeColor : AppColors.background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(dbProvider);
    final target = day ?? dayKey(DateTime.now());
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _box(
          Icons.arrow_downward,
          status == -1,
          const Color(0xFF8B2E3C),
          () => db.setStatus(habitId, target, -1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('$percent%'),
        ),
        _box(
          Icons.arrow_upward,
          status == 1,
          AppColors.accent,
          () => db.setStatus(habitId, target, 1),
        ),
      ],
    );
  }
}

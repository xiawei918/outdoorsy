import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class WeeklyActivity extends ConsumerWidget {
  const WeeklyActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final history = ref.watch(historyProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return history.when(
      data: (entries) {
        final dateMap = <DateTime, int>{};
        for (final entry in entries) {
          final date = DateTime(
            entry.date.year,
            entry.date.month,
            entry.date.day,
          );
          dateMap[date] = (dateMap[date] ?? 0) + entry.duration;
        }
        
        // Generate 7 days centered on today (3 days before, today, 3 days after)
        final days = List.generate(7, (index) {
          final date = today.subtract(Duration(days: 3 - index));
          final duration = dateMap[date] ?? 0;
          final isActive = duration >= settings.dailyGoal;
          return {
            'date': date,
            'hasActivity': isActive,
          };
        });

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: days.map((day) {
            final date = day['date'] as DateTime;
            final isToday = date.isAtSameMomentAs(today);
            
            return Column(
              children: [
                Text(
                  isToday ? 'Today' : _getDayName(date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (day['hasActivity'] as bool)
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error: $error',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
} 
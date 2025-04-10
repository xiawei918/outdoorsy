import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GoalAchievedModal extends StatelessWidget {
  const GoalAchievedModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 64,
              color: Colors.amber,
            ).animate().scale(
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
            ),
            const SizedBox(height: 24),
            Text(
              'Congratulations!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),
            const SizedBox(height: 16),
            Text(
              'You\'ve met your daily outdoor time goal!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep it up!'),
            ).animate().fadeIn().scale(),
          ],
        ),
      ),
    );
  }
} 
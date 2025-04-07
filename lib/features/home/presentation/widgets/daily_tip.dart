import 'package:flutter/material.dart';

class DailyTip extends StatelessWidget {
  final String tip;

  const DailyTip({
    super.key,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tip,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';

class SunsetDisplay extends StatelessWidget {
  final String sunsetTime;

  const SunsetDisplay({
    super.key,
    required this.sunsetTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wb_sunny, size: 24),
        const SizedBox(width: 8),
        Text(
          'Sunset at $sunsetTime',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
} 
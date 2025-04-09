import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/tips_provider.dart';

class DailyTip extends ConsumerWidget {
  const DailyTip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipState = ref.watch(tipsProvider);
    
    return SizedBox(
      height: 96, // Fixed height (80 * 1.2 = 96)
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    tipState.tip,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () {
                  ref.read(tipsProvider.notifier).refreshTip();
                },
                tooltip: 'Get another tip',
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
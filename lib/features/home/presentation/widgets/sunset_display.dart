import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sunset_provider.dart';
import '../../../settings/presentation/providers/location_provider.dart';

class SunsetDisplay extends ConsumerWidget {
  const SunsetDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final sunsetTimeAsync = ref.watch(sunsetProvider);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wb_twilight, size: 24),
        const SizedBox(width: 8),
        if (locationState.isLoading || sunsetTimeAsync.isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          sunsetTimeAsync.when(
            data: (sunsetTime) => Text(
              'Sunset at $sunsetTime',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => Text(
              'Sunset Unavailable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
      ],
    );
  }
} 
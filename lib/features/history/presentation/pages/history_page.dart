import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import '../widgets/time_entry_card.dart';
import '../widgets/add_entry_dialog.dart';
import '../../domain/models/time_entry.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  void _showAddEntryDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddEntryDialog(
        initialDate: DateTime.now(),
      ),
    );

    if (result != null) {
      ref.read(historyProvider.notifier).addTimeEntry(
        date: result['date'] as DateTime,
        duration: result['duration'] as int,
        isManual: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Outdoor time added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(historyProvider);
    final groupedEntries = <String, List<TimeEntry>>{};

    // Sort entries by date (newest first)
    final sortedEntries = List<TimeEntry>.from(entries)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Group entries by date
    for (final entry in sortedEntries) {
      final date = entry.date;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final entryDate = DateTime(date.year, date.month, date.day);

      String dateKey;
      if (entryDate.isAtSameMomentAs(today)) {
        dateKey = 'Today';
      } else if (entryDate.isAtSameMomentAs(yesterday)) {
        dateKey = 'Yesterday';
      } else {
        dateKey = DateFormat('EEEE, MMMM d, yyyy').format(date);
      }

      if (!groupedEntries.containsKey(dateKey)) {
        groupedEntries[dateKey] = [];
      }
      groupedEntries[dateKey]!.add(entry);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _showAddEntryDialog,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (groupedEntries.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No outdoor time entries yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start tracking your time outside or add time manually',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: groupedEntries.length,
                    itemBuilder: (context, index) {
                      final dateKey = groupedEntries.keys.elementAt(index);
                      final dateEntries = groupedEntries[dateKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                dateKey,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...dateEntries.map((entry) => TimeEntryCard(
                            entry: entry,
                            onDelete: () {
                              ref.read(historyProvider.notifier).deleteEntry(entry.id);
                            },
                            onEdit: (newDuration) {
                              ref.read(historyProvider.notifier).editEntry(
                                entry.id,
                                newDuration,
                              );
                            },
                          )),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 
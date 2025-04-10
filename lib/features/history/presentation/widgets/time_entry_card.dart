import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';
import '../../domain/models/time_entry.dart';

class TimeEntryCard extends StatelessWidget {
  final TimeEntry entry;
  final VoidCallback onDelete;
  final Function(int) onEdit;

  const TimeEntryCard({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d').format(entry.date);
    final formattedTime = DateFormat('h:mm a').format(entry.date);
    
    // Format duration to show hours, minutes and seconds
    final hours = (entry.duration / 3600).floor();
    final minutes = ((entry.duration % 3600) / 60).floor();
    final seconds = entry.duration % 60;
    
    String duration;
    if (entry.duration > 0) {
      if (hours > 0) {
        duration = '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        duration = '$minutes:${seconds.toString().padLeft(2, '0')}';
      }
    } else {
      duration = '< 1 minute';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$duration outside',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () {
                        _showEditDialog(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Entry'),
                            content: const Text(
                              'Are you sure you want to delete this entry?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  onDelete();
                                  Navigator.pop(context);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditDialog(BuildContext context) {
    int hours = (entry.duration / 3600).floor();
    int minutes = ((entry.duration % 3600) / 60).floor();
    int seconds = entry.duration % 60;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.edit_outlined),
              const SizedBox(width: 8),
              const Text('Edit Time Entry'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How long were you outside?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTimePicker(
                    value: hours,
                    onChanged: (value) => setState(() => hours = value),
                    label: 'Hours',
                    maxValue: 23,
                    context: context,
                  ),
                  _buildTimePicker(
                    value: minutes,
                    onChanged: (value) => setState(() => minutes = value),
                    label: 'Minutes',
                    maxValue: 59,
                    context: context,
                  ),
                  _buildTimePicker(
                    value: seconds,
                    onChanged: (value) => setState(() => seconds = value),
                    label: 'Seconds',
                    maxValue: 59,
                    context: context,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (hours > 0 || minutes > 0 || seconds > 0) {
                  onEdit(hours * 3600 + minutes * 60 + seconds);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimePicker({
    required int value,
    required ValueChanged<int> onChanged,
    required String label,
    required int maxValue,
    required BuildContext context,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 60,
          child: NumberPicker(
            value: value,
            minValue: 0,
            maxValue: maxValue,
            onChanged: onChanged,
            itemWidth: 45,
            itemHeight: 36,
            textStyle: const TextStyle(fontSize: 14),
            selectedTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            haptics: true,
            infiniteLoop: true,
          ),
        ),
      ],
    );
  }
} 
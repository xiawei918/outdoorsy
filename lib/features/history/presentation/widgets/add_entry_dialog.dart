import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';

class AddEntryDialog extends StatefulWidget {
  final DateTime initialDate;

  const AddEntryDialog({
    super.key,
    required this.initialDate,
  });

  @override
  State<AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> {
  late DateTime _selectedDate;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.timer_outlined),
          const SizedBox(width: 8),
          const Text('Add Outdoor Time'),
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
                value: _hours,
                onChanged: (value) => setState(() => _hours = value),
                label: 'Hours',
                maxValue: 23,
              ),
              _buildTimePicker(
                value: _minutes,
                onChanged: (value) => setState(() => _minutes = value),
                label: 'Minutes',
                maxValue: 59,
              ),
              _buildTimePicker(
                value: _seconds,
                onChanged: (value) => setState(() => _seconds = value),
                label: 'Seconds',
                maxValue: 59,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: const Text('Date'),
              subtitle: Text(
                DateFormat('MMMM d, yyyy').format(_selectedDate),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
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
            if (_hours > 0 || _minutes > 0 || _seconds > 0) {
              Navigator.pop(context, {
                'date': _selectedDate,
                'duration': _hours * 3600 + _minutes * 60 + _seconds,
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid time'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
  
  Widget _buildTimePicker({
    required int value,
    required ValueChanged<int> onChanged,
    required String label,
    required int maxValue,
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
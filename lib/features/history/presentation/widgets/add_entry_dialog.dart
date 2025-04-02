import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final _minutesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
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
      title: const Text('Add Outdoor Time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _minutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              hintText: 'How many minutes?',
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Date'),
            subtitle: Text(
              DateFormat('MMMM d, yyyy').format(_selectedDate),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context),
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
            final minutes = int.tryParse(_minutesController.text);
            if (minutes != null && minutes > 0) {
              Navigator.pop(context, {
                'date': _selectedDate,
                'duration': minutes * 60,
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid time in minutes'),
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
} 
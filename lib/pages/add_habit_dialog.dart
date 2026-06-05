import 'package:flutter/material.dart';

class AddHabitDialog extends StatefulWidget {
  final String routineType;

  const AddHabitDialog({
    Key? key,
    required this.routineType,
  }) : super(key: key);

  @override
  _AddHabitDialogState createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _duration = 10;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Habit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Habit Name',
                hintText: 'Enter habit name',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter habit description',
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('Duration: '),
                Expanded(
                  child: Slider(
                    value: _duration.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '$_duration minutes',
                    onChanged: (value) {
                      setState(() {
                        _duration = value.round();
                      });
                    },
                  ),
                ),
                Text('$_duration min'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please enter a habit name')),
              );
              return;
            }
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'description': _descriptionController.text.trim(),
              'duration': _duration,
            });
          },
          child: Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
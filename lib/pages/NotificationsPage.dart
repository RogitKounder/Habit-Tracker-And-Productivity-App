import 'package:flutter/material.dart';
import '../utils/NotificationHelper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationHelper notificationHelper = NotificationHelper();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Initialize FCM listeners
    notificationHelper.setupFCMListeners();
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Reminders'),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Text('Please log in to view reminders'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Reminders'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: _clearAllReminders,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _restoreReminders(user.uid),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('habits')
            .where('userId', isEqualTo: user.uid)
            .where('reminderTime', isNotEqualTo: null)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading reminders: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final habits = snapshot.data?.docs ?? [];

          if (habits.isEmpty) {
            return Center(
              child: Text('No reminders set'),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index].data() as Map<String, dynamic>;
              return ReminderCard(
                habitId: habits[index].id,
                habitName: habit['name'] ?? 'Unnamed Habit',
                reminderTime: habit['reminderTime'] ?? '',
                onDelete: () => _deleteReminder(habits[index].id),
                onEdit: () => _editReminder(habits[index].id, habit),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteReminder(String habitId) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Reminder'),
          content: Text('Are you sure you want to delete this reminder?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await notificationHelper.cancelHabitNotifications(habitId);
        await firestore.collection('habits').doc(habitId).update({
          'reminderTime': null,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete reminder. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editReminder(String habitId, Map<String, dynamic> habit) async {
    try {
      final TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: int.parse(habit['reminderTime'].split(':')[0]),
          minute: int.parse(habit['reminderTime'].split(':')[1]),
        ),
      );

      if (selectedTime != null) {
        final timeString =
            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

        await firestore.collection('habits').doc(habitId).update({
          'reminderTime': timeString,
        });

        await notificationHelper.scheduleHabitReminder(
          habitId: habitId,
          habitName: habit['name'],
          reminderTime: selectedTime,
          isDaily: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating reminder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update reminder. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearAllReminders() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Clear All Reminders'),
          content: Text('Are you sure you want to delete all reminders?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: Text('Clear All', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final user = auth.currentUser;
        if (user != null) {
          final habits = await firestore
              .collection('habits')
              .where('userId', isEqualTo: user.uid)
              .where('reminderTime', isNotEqualTo: null)
              .get();

          await notificationHelper.cancelAllNotifications();
          for (var doc in habits.docs) {
            await doc.reference.update({'reminderTime': null});
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All reminders cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error clearing reminders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear reminders. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreReminders(String userId) async {
    try {
      final habits = await firestore
          .collection('habits')
          .where('userId', isEqualTo: userId)
          .where('reminderTime', isNotEqualTo: null)
          .get();

      for (var doc in habits.docs) {
        final habit = doc.data();
        final parts = habit['reminderTime'].split(':');
        final reminderTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

        await notificationHelper.scheduleHabitReminder(
          habitId: doc.id,
          habitName: habit['name'],
          reminderTime: reminderTime,
          isDaily: true,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminders restored'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error restoring reminders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to restore reminders. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class ReminderCard extends StatelessWidget {
  final String habitId;
  final String habitName;
  final String reminderTime;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ReminderCard({
    required this.habitId,
    required this.habitName,
    required this.reminderTime,
    required this.onDelete,
    required this.onEdit,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.alarm, color: Colors.deepPurple),
        title: Text(habitName),
        subtitle: Text('Daily at $reminderTime'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class AllHabitsPage extends StatefulWidget {
  const AllHabitsPage({Key? key}) : super(key: key);

  @override
  _AllHabitsPageState createState() => _AllHabitsPageState();
}

class _AllHabitsPageState extends State<AllHabitsPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String selectedRoutine = 'All'; // Default routine filter
  String selectedDateFilter = 'Weekly'; // Default date filter
  DateTime? specificDate; // For specific date filter
  List<Map<String, dynamic>> habits = [];
  List<String> routines = ['All', 'morning', 'evening', 'workout', 'study'];

  @override
  void initState() {
    super.initState();
    _fetchHabits();
  }

  // Fetch all habits from Firestore
  void _fetchHabits() async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await firestore.collection('habits').where('userId', isEqualTo: user.uid).get();
      setState(() {
        habits = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching habits: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching habits: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Helper method to convert lastCompleted to DateTime
  DateTime? _convertToDateTime(dynamic lastCompleted) {
    try {
      if (lastCompleted == null) {
        return null;
      } else if (lastCompleted is Timestamp) {
        return lastCompleted.toDate();
      } else if (lastCompleted is String) {
        return DateTime.parse(lastCompleted);
      } else {
        debugPrint('Unexpected type for lastCompleted: ${lastCompleted.runtimeType}');
        return null;
      }
    } catch (e) {
      debugPrint('Error converting lastCompleted: $e');
      return null;
    }
  }

  // Filter habits based on routine and date
  List<Map<String, dynamic>> _filterHabits() {
    List<Map<String, dynamic>> filteredHabits = List.from(habits);

    // Filter by routine
    if (selectedRoutine != 'All') {
      filteredHabits = filteredHabits.where((habit) => habit['routineType'] == selectedRoutine).toList();
    }

    // Filter by date
    final now = DateTime.now();
    if (selectedDateFilter == 'Weekly') {
      final weekAgo = now.subtract(const Duration(days: 7));
      filteredHabits = filteredHabits.where((habit) {
        final lastCompleted = _convertToDateTime(habit['lastCompleted']);
        return lastCompleted != null && lastCompleted.isAfter(weekAgo);
      }).toList();
    } else if (selectedDateFilter == 'Monthly') {
      final monthAgo = now.subtract(const Duration(days: 30));
      filteredHabits = filteredHabits.where((habit) {
        final lastCompleted = _convertToDateTime(habit['lastCompleted']);
        return lastCompleted != null && lastCompleted.isAfter(monthAgo);
      }).toList();
    } else if (selectedDateFilter == 'Specific Date' && specificDate != null) {
      filteredHabits = filteredHabits.where((habit) {
        final lastCompleted = _convertToDateTime(habit['lastCompleted']);
        return lastCompleted != null &&
            lastCompleted.year == specificDate!.year &&
            lastCompleted.month == specificDate!.month &&
            lastCompleted.day == specificDate!.day;
      }).toList();
    }

    return filteredHabits;
  }

  // Show date picker for specific date filter
  Future<void> _selectSpecificDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: specificDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != specificDate) {
      setState(() {
        specificDate = picked;
        selectedDateFilter = 'Specific Date';
      });
    }
  }

  // Helper method to capitalize the first letter of a string
  String capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final filteredHabits = _filterHabits();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Habits'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Routine Filter Dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Routine:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedRoutine,
                  items: routines.map((routine) {
                    return DropdownMenuItem<String>(
                      value: routine,
                      child: Text(capitalize(routine)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRoutine = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          // Date Filter Options
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text('Weekly'),
                  selected: selectedDateFilter == 'Weekly',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedDateFilter = 'Weekly';
                        specificDate = null;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Monthly'),
                  selected: selectedDateFilter == 'Monthly',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedDateFilter = 'Monthly';
                        specificDate = null;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: Text(
                    specificDate != null
                        ? DateFormat('MMM d, yyyy').format(specificDate!)
                        : 'Specific Date',
                  ),
                  selected: selectedDateFilter == 'Specific Date',
                  onSelected: (selected) {
                    if (selected) {
                      _selectSpecificDate(context);
                    }
                  },
                ),
              ],
            ),
          ),
          // Habits List
          Expanded(
            child: habits.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredHabits.isEmpty
                ? const Center(child: Text('No habits found for this filter.'))
                : ListView.builder(
              itemCount: filteredHabits.length,
              itemBuilder: (context, index) {
                final habit = filteredHabits[index];
                final lastCompleted = _convertToDateTime(habit['lastCompleted']);
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(
                      habit['name'] ?? 'Unnamed Habit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: habit['completed'] == true
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Routine: ${capitalize(habit['routineType'] ?? 'None')}'),
                        Text('Streak: ${habit['streak'] ?? 0}'),
                        Text(
                          'Last Completed: ${lastCompleted != null ? DateFormat('MMM d, yyyy').format(lastCompleted) : 'Never'}',
                        ),
                      ],
                    ),
                    trailing: Icon(
                      habit['completed'] == true ? Icons.check_circle : Icons.circle_outlined,
                      color: habit['completed'] == true ? Colors.green : Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
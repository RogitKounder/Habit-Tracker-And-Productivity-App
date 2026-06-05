import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/SharedPreferencesHelper.dart'; // Assuming this exists in your project

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedPeriod = 'Day'; // Custom period: Day, Week, Month
  CalendarFormat _calendarFormat = CalendarFormat.month; // Default calendar view
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late SharedPreferencesHelper _prefs;
  String? _userId;
  String _selectedRoutine = 'morning'; // Default routine
  bool _isLoading = true;

  // List of available routines and periods
  final List<String> _routines = ['morning', 'evening', 'workout', 'study'];
  final List<String> _periods = ['Day', 'Week', 'Month'];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _prefs = await SharedPreferencesHelper.getInstance();
      _selectedRoutine = _prefs.getString('selected_routine') ?? 'morning';
      _userId = _auth.currentUser?.uid;
      if (_userId == null) {
        debugPrint('No user logged in');
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error initializing ProgressPage: $e');
      setState(() => _isLoading = false);
    }
  }

  // Stream of habits from Firestore for the selected period and routine
  Stream<Map<String, double>> _streamHabitsForPeriod() {
    if (_userId == null) {
      return Stream.value({"Not logged in": 0.0});
    }

    DateTime startDate;
    DateTime endDate;

    switch (_selectedPeriod) {
      case 'Day':
        startDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'Week':
        startDate = _selectedDay!.subtract(Duration(days: _selectedDay!.weekday - 1)); // Monday start
        endDate = startDate.add(const Duration(days: 7));
        break;
      case 'Month':
        startDate = DateTime(_selectedDay!.year, _selectedDay!.month, 1);
        endDate = DateTime(_selectedDay!.year, _selectedDay!.month + 1, 1);
        break;
      default:
        startDate = _selectedDay!;
        endDate = startDate.add(const Duration(days: 1));
    }

    return _firestore
        .collection('habits')
        .where('userId', isEqualTo: _userId)
        .where('routineType', isEqualTo: _selectedRoutine)
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThan: endDate)
        .snapshots()
        .map((snapshot) {
      Map<String, List<double>> habitProgress = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String? ?? 'Unknown';
        final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
        habitProgress[name] = (habitProgress[name] ?? [])..add(progress.clamp(0.0, 1.0));
      }

      Map<String, double> averagedHabits = {};
      habitProgress.forEach((name, progressList) {
        final average = progressList.isEmpty ? 0.0 : progressList.reduce((a, b) => a + b) / progressList.length;
        averagedHabits[name] = average;
      });

      return averagedHabits.isEmpty ? {"No habits recorded": 0.0} : averagedHabits;
    }).handleError((e) {
      debugPrint('Error streaming habits: $e');
      return {"Error loading habits": 0.0};
    });
  }

  // Helper to get icon for habit
  IconData _getIconForHabit(String habitName) {
    final icons = {
      'Early Rise': Icons.wb_sunny,
      'Morning Meditation': Icons.self_improvement,
      'Morning Exercise': Icons.fitness_center,
      'Healthy Breakfast': Icons.local_drink,
      'Plan Your Day': Icons.calendar_today,
      'Morning Reading': Icons.book,
      'Evening Walk': Icons.directions_walk,
      'Dinner Prep': Icons.kitchen,
      'Journal Writing': Icons.edit,
      'Evening Stretch': Icons.accessibility_new,
      'Reading Time': Icons.book,
      'Sleep Prep': Icons.bedtime,
      'Warm Up': Icons.directions_run,
      'Cardio': Icons.favorite,
      'Strength Training': Icons.fitness_center,
      'Core Workout': Icons.sports,
      'Cool Down': Icons.spa,
      'Recovery': Icons.healing,
      'Setup Workspace': Icons.work,
      'Focus Block': Icons.school,
      'Quick Break': Icons.free_breakfast,
      'Review Notes': Icons.note,
      'Practice Problems': Icons.calculate,
      'Summarize': Icons.list,
    };
    String normalizedName = habitName.toLowerCase();
    return icons.entries.firstWhere(
          (entry) => normalizedName.contains(entry.key.toLowerCase()),
      orElse: () => const MapEntry('', Icons.check_circle_outline),
    ).value;
  }

  // Helper to get routine display name
  String _getRoutineDisplayName(String routine) {
    switch (routine) {
      case 'morning':
        return 'Morning Routine';
      case 'evening':
        return 'Evening Routine';
      case 'workout':
        return 'Workout';
      case 'study':
        return 'Study Session';
      default:
        return routine.capitalize();
    }
  }

  // Helper to get period label
  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'Day':
        return "Day (${_selectedDay?.toString().split(" ")[0]})";
      case 'Week':
        final startOfWeek = _selectedDay!.subtract(Duration(days: _selectedDay!.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return "Week (${startOfWeek.toString().split(" ")[0]} - ${endOfWeek.toString().split(" ")[0]})";
      case 'Month':
        return "Month (${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')})";
      default:
        return "Period";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Progress'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedRoutine,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              dropdownColor: Colors.deepPurple,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              underline: Container(),
              onChanged: (String? newValue) async {
                if (newValue != null && newValue != _selectedRoutine) {
                  setState(() {
                    _selectedRoutine = newValue;
                    _isLoading = true;
                  });
                  await _prefs.setString('selected_routine', newValue);
                  setState(() => _isLoading = false);
                }
              },
              items: _routines.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    _getRoutineDisplayName(value),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              dropdownColor: Colors.deepPurple,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              underline: Container(),
              onChanged: (String? newValue) {
                if (newValue != null && newValue != _selectedPeriod) {
                  setState(() {
                    _selectedPeriod = newValue;
                    // Sync calendar format with period
                    switch (newValue) {
                      case 'Day':
                        _calendarFormat = CalendarFormat.month; // Show month view for day selection
                        break;
                      case 'Week':
                        _calendarFormat = CalendarFormat.week;
                        break;
                      case 'Month':
                        _calendarFormat = CalendarFormat.month;
                        break;
                    }
                  });
                }
              },
              items: _periods.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: EdgeInsets.zero,
        children: [
          // Calendar Widget
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                    // Update period based on calendar format change
                    if (format == CalendarFormat.week) {
                      _selectedPeriod = 'Week';
                    } else if (format == CalendarFormat.month && _selectedPeriod != 'Day') {
                      _selectedPeriod = 'Month';
                    }
                  });
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: Colors.deepPurpleAccent,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: isSameDay(_selectedDay, DateTime.now()) ? Colors.deepPurpleAccent : Colors.grey.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
                  weekendDecoration: const BoxDecoration(shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          // Top Habits Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 15, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Top Habits for ${_getPeriodLabel()} (${_getRoutineDisplayName(_selectedRoutine)})",
                style: TextStyle(
                  color: Colors.grey[900],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: StreamBuilder<Map<String, double>>(
                stream: _streamHabitsForPeriod(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("Error loading habits"),
                    );
                  }
                  final habits = snapshot.data ?? {"No data": 0.0};
                  final topHabits = habits.entries
                      .where((entry) => entry.value >= 0.5)
                      .toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  return Column(
                    children: topHabits.isNotEmpty
                        ? topHabits.map((habit) {
                      return Column(
                        children: [
                          ListTile(
                            leading: CircularProgressIndicator(
                              color: Colors.deepPurpleAccent,
                              strokeWidth: 7.5,
                              backgroundColor: const Color.fromARGB(255, 192, 170, 250),
                              value: habit.value,
                            ),
                            title: Text(
                              habit.key,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Avg Progress: ${(habit.value * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Icon(_getIconForHabit(habit.key)),
                          ),
                          if (habit != topHabits.last) const Divider(),
                        ],
                      );
                    }).toList()
                        : [
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("No top habits for this period."),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Worst Habits Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 25, 15, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Worst Habits for ${_getPeriodLabel()} (${_getRoutineDisplayName(_selectedRoutine)})",
                style: TextStyle(
                  color: Colors.grey[900],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: StreamBuilder<Map<String, double>>(
                stream: _streamHabitsForPeriod(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("Error loading habits"),
                    );
                  }
                  final habits = snapshot.data ?? {"No data": 0.0};
                  final worstHabits = habits.entries
                      .where((entry) => entry.value < 0.5)
                      .toList()
                    ..sort((a, b) => a.value.compareTo(b.value));

                  return Column(
                    children: worstHabits.isNotEmpty
                        ? worstHabits.map((habit) {
                      return Column(
                        children: [
                          ListTile(
                            leading: CircularProgressIndicator(
                              color: Colors.deepPurpleAccent,
                              strokeWidth: 7.5,
                              backgroundColor: const Color.fromARGB(255, 192, 170, 250),
                              value: habit.value,
                            ),
                            title: Text(
                              habit.key,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Avg Progress: ${(habit.value * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Icon(_getIconForHabit(habit.key)),
                          ),
                          if (habit != worstHabits.last) const Divider(),
                        ],
                      );
                    }).toList()
                        : [
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("No worst habits for this period."),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' show max;

class HabitsPage extends StatefulWidget {
  const HabitsPage({Key? key}) : super(key: key);

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  List<Map<String, dynamic>> habits = [];
  StreamSubscription<QuerySnapshot>? _habitsSubscription;
  String selectedRoutine = 'morning';
  DateTime selectedDate = DateTime.now(); // Default to current day
  Map<String, int> habitStats = {
    'totalHabits': 0,
    'completedHabits': 0,
    'streakDays': 0,
  };
  Map<String, dynamic>? selectedHabit; // For selected habit progress

  @override
  void initState() {
    super.initState();
    _setupHabitsListener();
  }

  @override
  void dispose() {
    _habitsSubscription?.cancel();
    super.dispose();
  }

  void _setupHabitsListener() {
    setState(() => isLoading = true);

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    _habitsSubscription?.cancel();

    // Fetch habits for the selected routine
    _habitsSubscription = _firestore
        .collection('habits')
        .where('userId', isEqualTo: user.uid)
        .where('routineType', isEqualTo: selectedRoutine)
        .snapshots()
        .listen(
          (snapshot) async {
        if (mounted) {
          final habitsList = snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            };
          }).toList();

          setState(() {
            habits = habitsList;
            _calculateStats(habitsList);
            isLoading = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Error in habits stream: $error');
        if (mounted) {
          setState(() => isLoading = false);
        }
      },
    );
  }

  void _calculateStats(List<Map<String, dynamic>> habits) {
    int total = habits.length;
    int completed = habits.where((h) => h['completed'] == true).length;
    int maxStreak = habits.fold(0, (prev, h) => max(prev, h['streak'] ?? 0));

    setState(() {
      habitStats = {
        'totalHabits': total,
        'completedHabits': completed,
        'streakDays': maxStreak,
      };
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        isLoading = true;
      });
      _setupHabitsListener();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : CustomScrollView(
          slivers: [
            _buildHeader(),
            _buildRoutineSelector(),
            _buildHabitStats(),
            _buildHabitsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple,
              Colors.deepPurple.shade300,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habits - ${DateFormat('MMM d, yyyy').format(selectedDate)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Track your daily habits',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.calendar_today, color: Colors.white),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineSelector() {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(vertical: 8), // Keep vertical padding, remove horizontal
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute chips evenly across the screen
          children: [
            _buildRoutineChip('morning', 'Morning Routine', Icons.wb_sunny),
            _buildRoutineChip('evening', 'Evening Routine', Icons.nights_stay),
            _buildRoutineChip('workout', 'Workout', Icons.fitness_center),
            _buildRoutineChip('study', 'Study', Icons.book),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineChip(String routine, String label, IconData icon) {
    final isSelected = selectedRoutine == routine;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            selectedRoutine = routine;
            isLoading = true;
          });
          _setupHabitsListener();
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.deepPurple,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildHabitStats() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Total Habits',
                  habitStats['totalHabits'].toString(),
                  Icons.list_alt,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Completed',
                  habitStats['completedHabits'].toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'Best Streak',
                  '${habitStats['streakDays']} days',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsList() {
    if (habits.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.format_list_bulleted, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No habits tracked for ${selectedRoutine.capitalize()} on ${DateFormat('MMM d').format(selectedDate)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final habit = habits[index];
          final isSelected = selectedHabit != null && selectedHabit!['id'] == habit['id'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedHabit = null; // Deselect if already selected
                      } else {
                        selectedHabit = habit; // Select the clicked habit
                      }
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit['name'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          habit['description'] ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: habit['progress'] ?? 0.0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProgressColor(habit['progress'] ?? 0.0),
                          ),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isSelected) ...[
                // Progress section below the selected habit card
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habit Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 150,
                              height: 150,
                              child: CircularProgressIndicator(
                                value: habit['progress'] ?? 0.0,
                                strokeWidth: 15,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getProgressColor(habit['progress'] ?? 0.0),
                                ),
                              ),
                            ),
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${((habit['progress'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _getProgressColor(habit['progress'] ?? 0.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Progress for ${habit['name']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
        childCount: habits.length,
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.6) return Colors.green;
    return Colors.deepPurple;
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
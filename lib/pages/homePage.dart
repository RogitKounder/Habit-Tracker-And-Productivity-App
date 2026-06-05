import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/SharedPreferencesHelper.dart';
import '../utils/NotificationHelper.dart';
import '../utils/BackgroundHelper.dart';
import 'dart:convert';
import '../models/daily_stats.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../pages/NotificationsPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  late SharedPreferencesHelper prefs;
  late NotificationHelper notificationHelper;
  late BackgroundHelper backgroundHelper;

  List<Map<String, dynamic>> habits = [];
  String backgroundImage = '';
  Timer? habitTimer;
  int remainingTime = 600; // 10 minutes
  bool isTimerRunning = false;
  String selectedHabit = "";
  String userName = "";
  bool isLoading = true;
  int completedHabits = 0;
  String selectedRoutine = 'morning';

  final Map<String, List<Map<String, dynamic>>> routineHabits = {
    'morning': [
      {'name': 'Early Rise', 'durationMinutes': 5, 'description': 'Wake up at 6 AM', 'image': 'https://images.unsplash.com/photo-1506368249639-73a05d6f6488'},
      {'name': 'Morning Meditation', 'durationMinutes': 10, 'description': 'Start with mindfulness', 'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773'},
      {'name': 'Morning Exercise', 'durationMinutes': 30, 'description': 'Quick workout routine', 'image': 'https://images.unsplash.com/photo-1599058945522-28d584b6f0ff'},
      {'name': 'Healthy Breakfast', 'durationMinutes': 20, 'description': 'Nutritious morning meal', 'image': 'https://images.unsplash.com/photo-1525351484163-7529414344d8'},
      {'name': 'Plan Your Day', 'durationMinutes': 10, 'description': 'Set daily goals', 'image': 'https://images.unsplash.com/photo-1517971053567-8bde93bc6a58'},
      {'name': 'Morning Reading', 'durationMinutes': 15, 'description': 'Read something inspiring', 'image': 'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6'},
    ],
    'evening': [
      {'name': 'Evening Walk', 'durationMinutes': 30, 'description': 'Relaxing outdoor time', 'image': 'https://images.unsplash.com/photo-1542332213-9b5a5a3fad35'},
      {'name': 'Dinner Prep', 'durationMinutes': 45, 'description': 'Cook a healthy dinner', 'image': 'https://images.unsplash.com/photo-1556911220-bff31c812dba'},
      {'name': 'Journal Writing', 'durationMinutes': 15, 'description': 'Reflect on your day', 'image': 'https://images.unsplash.com/photo-1517842645767-c639042777db'},
      {'name': 'Evening Stretch', 'durationMinutes': 10, 'description': 'Light stretching', 'image': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b'},
      {'name': 'Reading Time', 'durationMinutes': 20, 'description': 'Wind down with a book', 'image': 'https://images.unsplash.com/photo-1488868935619-4483ed49a3a7'},
      {'name': 'Sleep Prep', 'durationMinutes': 15, 'description': 'Prepare for bed', 'image': 'https://images.unsplash.com/photo-1511295742362-92c96b5adb36'},
    ],
    'workout': [
      {'name': 'Warm Up', 'durationMinutes': 10, 'description': 'Dynamic stretching', 'image': 'https://images.unsplash.com/photo-1601422407692-ec4eeec1d9b3'},
      {'name': 'Cardio', 'durationMinutes': 30, 'description': 'High-intensity cardio', 'image': 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c'},
      {'name': 'Strength Training', 'durationMinutes': 40, 'description': 'Weight training', 'image': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48'},
      {'name': 'Core Workout', 'durationMinutes': 15, 'description': 'Ab exercises', 'image': 'https://images.unsplash.com/photo-1571945153237-4929e783af4a'},
      {'name': 'Cool Down', 'durationMinutes': 10, 'description': 'Static stretching', 'image': 'https://images.unsplash.com/photo-1518611012118-696072aa579a'},
      {'name': 'Recovery', 'durationMinutes': 15, 'description': 'Light mobility work', 'image': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b'},
    ],
    'study': [
      {'name': 'Setup Workspace', 'durationMinutes': 5, 'description': 'Prepare study area', 'image': 'https://images.unsplash.com/photo-1598831292947-495063148562'},
      {'name': 'Focus Block', 'durationMinutes': 25, 'description': 'Deep work session', 'image': 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173'},
      {'name': 'Quick Break', 'durationMinutes': 5, 'description': 'Short refresher', 'image': 'https://images.unsplash.com/photo-1495954484750-af469f2f9be5'},
      {'name': 'Review Notes', 'durationMinutes': 20, 'description': 'Active recall', 'image': 'https://images.unsplash.com/photo-1488190211105-8b0e65b80b4e'},
      {'name': 'Practice Problems', 'durationMinutes': 30, 'description': 'Apply learning', 'image': 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40'},
      {'name': 'Summarize', 'durationMinutes': 15, 'description': 'Create key points', 'image': 'https://images.unsplash.com/photo-1501504905252-473c47e087f8'},
    ],
  };

  Map<String, DailyStats> routineStats = {};
  DateTime? lastStatsReset;
  Map<String, int> pausedTimes = {};

  @override
  void initState() {
    super.initState();
    notificationHelper = NotificationHelper();
    backgroundHelper = BackgroundHelper();
    _initializeApp();
  }

  DateTime _parseDate(dynamic date) {
    debugPrint('Parsing date: $date, type: ${date.runtimeType}');
    if (date == null) {
      return DateTime.now();
    }
    if (date is Timestamp) {
      return date.toDate();
    }
    if (date is String) {
      return DateTime.parse(date);
    }
    if (date is DateTime) {
      return date;
    }
    throw FormatException('Unsupported date format: $date');
  }

  Future<void> _initializeApp() async {
    try {
      prefs = await SharedPreferencesHelper.getInstance();
      await _loadPausedTimes();

      selectedRoutine = prefs.getString('selected_routine') ?? 'morning';
      debugPrint('Initial selectedRoutine: $selectedRoutine');

      await notificationHelper.initializeNotifications();
      final hasPermission = await notificationHelper.requestPermissions();

      await _loadDailyStats();
      await _initializeStats();
      await _loadUserData();
      await _loadHabits();

      final routines = ['morning', 'evening', 'workout', 'study'];
      for (var routine in routines) {
        if (!habits.any((h) => h['routineType'] == routine)) {
          await _loadRoutineHabits(routine);
        }
      }

      await _loadInitialBackground();

      if (hasPermission) {
        _restoreReminders();
      }

      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error initializing app: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startRoutine(String routineType) async {
    if (routineType == selectedRoutine) return;
    setState(() => isLoading = true);
    try {
      final newBackground = await backgroundHelper.getBackgroundForHabit(routineType);
      setState(() {
        selectedRoutine = routineType;
        backgroundImage = newBackground;
      });
      await prefs.setString('selected_routine', routineType);
      debugPrint('Switched to routine: $selectedRoutine');
    } catch (e) {
      debugPrint('Error starting routine: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting routine: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _initializeStats() async {
    try {
      final now = DateTime.now();
      routineStats = {
        'morning': DailyStats(date: now, completedHabits: 0, totalMinutes: 0),
        'evening': DailyStats(date: now, completedHabits: 0, totalMinutes: 0),
        'workout': DailyStats(date: now, completedHabits: 0, totalMinutes: 0),
        'study': DailyStats(date: now, completedHabits: 0, totalMinutes: 0),
      };
      lastStatsReset = now;
      final statsMap = routineStats.map((key, value) => MapEntry(key, value.toMap()));
      await prefs.setString('daily_stats', jsonEncode(statsMap));
      await prefs.setString('last_stats_reset', now.toIso8601String());
    } catch (e) {
      debugPrint('Error initializing stats: $e');
      routineStats = {
        'morning': DailyStats(date: DateTime.now()),
        'evening': DailyStats(date: DateTime.now()),
        'workout': DailyStats(date: DateTime.now()),
        'study': DailyStats(date: DateTime.now()),
      };
      lastStatsReset = DateTime.now();
    }
  }

  @override
  void dispose() {
    habitTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = auth.currentUser;
      if (user != null) {
        final userData = await firestore.collection('users').doc(user.uid).get();
        setState(() {
          userName = userData.data()?['name'] ?? 'User';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadHabits() async {
    try {
      setState(() => isLoading = true);

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final isRunning = prefs.getTimerRunning() ?? false;
      final savedTime = prefs.getTimerRemainingTime() ?? 0;
      final savedHabit = prefs.getSelectedHabit() ?? "";

      final user = auth.currentUser;
      if (user != null) {
        final QuerySnapshot snapshot = await firestore
            .collection('habits')
            .where('userId', isEqualTo: user.uid)
            .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
            .where('createdAt', isLessThan: endOfDay)
            .orderBy('createdAt', descending: true)
            .get();

        if (mounted) {
          final firestoreHabits = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'name': data['name'] ?? '',
              'description': data['description'] ?? '',
              'completed': data['completed'] ?? false,
              'streak': data['streak'] ?? 0,
              'createdAt': _parseDate(data['createdAt']),
              'durationMinutes': data['durationMinutes'] ?? 10,
              'routineType': data['routineType'] ?? 'morning',
              'progress': data['progress'] ?? 0.0,
              'reminderTime': data['reminderTime'],
              'countedInStats': data['countedInStats'] ?? false,
              'lastCompleted': data['lastCompleted'] != null ? _parseDate(data['lastCompleted']) : null,
            };
          }).toList();

          if (lastStatsReset == null || !_isSameDay(lastStatsReset!, now)) {
            await _resetDailyStats();
          }

          setState(() {
            habits = firestoreHabits;
          });

          if (savedHabit.isNotEmpty && savedTime > 0) {
            final habitExists = habits.any((h) => h['name'] == savedHabit);
            if (habitExists) {
              final habit = habits.firstWhere((h) => h['name'] == savedHabit);
              setState(() {
                selectedHabit = savedHabit;
                remainingTime = savedTime;
                isTimerRunning = isRunning && !habit['completed'];
                habit['progress'] = 1 - (remainingTime / ((habit['durationMinutes'] as int? ?? 10) * 60));
                habit['progress'] = habit['progress'].clamp(0.0, 1.0);
              });

              if (isRunning && !habit['completed']) {
                _restartTimer(savedHabit, savedTime);
              } else {
                pausedTimes[savedHabit] = savedTime;
              }
            } else {
              prefs.saveTimerState(false, 0, "");
            }
          }

          await _saveHabitsToLocal();
          await _loadDailyStats();
          debugPrint('Loaded ${habits.length} habits across all routines');
          habits.forEach((habit) => debugPrint('Habit: ${habit['name']}, Routine: ${habit['routineType']}'));
        }
      }
    } catch (e) {
      debugPrint('Error loading habits: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading habits: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startTimer(String habitName) {
    if (isTimerRunning && selectedHabit == habitName) {
      pausedTimes[habitName] = remainingTime;
      _stopTimer(habitName);
      return;
    }

    habitTimer?.cancel();

    final habit = habits.firstWhere(
          (h) => h['name'] == habitName,
      orElse: () => {'durationMinutes': 10},
    );
    final duration = habit['durationMinutes'] as int? ?? 10;

    setState(() {
      selectedHabit = habitName;
      isTimerRunning = true;
      remainingTime = pausedTimes[habitName] ?? (duration * 60);
    });

    _updateBackground(habitName);

    prefs.saveTimerState(true, remainingTime, habitName);

    habitTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
          final progress = 1 - (remainingTime / (duration * 60));
          final index = habits.indexWhere((h) => h['name'] == habitName);
          if (index != -1) {
            habits[index]['progress'] = progress;
            firestore.collection('habits').doc(habits[index]['id']).update({'progress': progress});
            if (progress >= 0.6 && !habits[index]['countedInStats']) {
              habits[index]['countedInStats'] = true;
              firestore.collection('habits').doc(habits[index]['id']).update({'countedInStats': true});
              _updateDailyStats(habitName);
            }
            if (progress >= 1.0 && !habits[index]['completed']) {
              _completeTimer(habitName);
            }
          }
        });
        prefs.saveTimerState(true, remainingTime, habitName);
        _savePausedTimes();
      } else {
        timer.cancel();
        _completeTimer(habitName);
      }
    });

    _saveHabitsToLocal();
  }

  void _completeTimer(String habitName) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final habitIndex = habits.indexWhere((h) => h['name'] == habitName);
    if (habitIndex == -1) return; // Habit not found, exit early

    final habit = habits[habitIndex];
    int streak = habit['streak'] as int? ?? 0;
    final lastCompleted = habit['lastCompleted'] != null ? _parseDate(habit['lastCompleted']) : null;

    // Calculate new streak (unchanged from your original logic)
    if (lastCompleted != null) {
      final daysSinceLast = today.difference(DateTime(lastCompleted.year, lastCompleted.month, lastCompleted.day)).inDays;
      debugPrint('Days since last completion for $habitName: $daysSinceLast, Previous Streak: $streak');
      if (daysSinceLast > 1) {
        streak = 1; // Reset streak if more than 1 day gap
      } else if (daysSinceLast == 1) {
        streak++; // Increment streak for consecutive days
      } else if (daysSinceLast == 0) {
        // Same day completion: no increment (adjust if multiple completions should count)
        debugPrint('Same day completion for $habitName, streak remains $streak');
      }
    } else {
      streak = 1; // First completion
    }

    // Update local habit state (unchanged from your original)
    setState(() {
      isTimerRunning = false;
      selectedHabit = "";
      pausedTimes.remove(habitName);
      habits[habitIndex]['progress'] = 1.0;
      habits[habitIndex]['completed'] = true;
      habits[habitIndex]['lastCompleted'] = now;
      habits[habitIndex]['streak'] = streak;
    });

    // Persist habit completion to Firestore 'habits' collection (unchanged from your original)
    try {
      await firestore.collection('habits').doc(habit['id']).update({
        'progress': 1.0,
        'completed': true,
        'lastCompleted': now.toIso8601String(),
        'streak': streak,
      });
      debugPrint('Firestore updated for $habitName with streak: $streak');
    } catch (e) {
      debugPrint('Error updating Firestore for $habitName: $e');
    }

    // NEW: Update achievements in Firestore 'achievements' collection
    final user = auth.currentUser;
    if (user != null) {
      try {
        final achievementsRef = firestore.collection('achievements').doc(user.uid);
        final achievementsDoc = await achievementsRef.get();
        final achievementsData = achievementsDoc.data() ?? {
          'streak': 0,
          'habitsTracked': habits.length, // Initialize with current habit count if not set
          'habitsCompleted': 0,
          'morningRoutinesCompleted': 0,
          'routineHabitsCompleted': 0,
          'loginDays': 0,
          'weeklyGoalsMet': 0,
          'habitsShared': 0,
        };

        // Check if this is the first completion today to avoid double-counting
        bool isFirstCompletionToday = lastCompleted == null || !_isSameDay(lastCompleted, now);

        // Prepare updated achievements data
        final updatedAchievements = {
          'streak': streak, // Using habit-specific streak; adjust if you want an overall app streak
          'habitsTracked': achievementsData['habitsTracked'] ?? habits.length, // No change unless new habits added
          'habitsCompleted': isFirstCompletionToday
              ? (achievementsData['habitsCompleted'] ?? 0) + 1
              : (achievementsData['habitsCompleted'] ?? 0),
          'morningRoutinesCompleted': habit['routineType'] == 'morning' && isFirstCompletionToday
              ? (achievementsData['morningRoutinesCompleted'] ?? 0) + 1
              : (achievementsData['morningRoutinesCompleted'] ?? 0),
          'routineHabitsCompleted': isFirstCompletionToday
              ? (achievementsData['routineHabitsCompleted'] ?? 0) + 1
              : (achievementsData['routineHabitsCompleted'] ?? 0),
          'loginDays': achievementsData['loginDays'] ?? 0, // Not affected here
          'weeklyGoalsMet': achievementsData['weeklyGoalsMet'] ?? 0, // Not affected here
          'habitsShared': achievementsData['habitsShared'] ?? 0, // Not affected here
        };

        // Update Firestore achievements collection
        await achievementsRef.set(updatedAchievements, SetOptions(merge: true));
        debugPrint('Achievements updated for $habitName: $updatedAchievements');
      } catch (e) {
        debugPrint('Error updating achievements for $habitName: $e');
      }
    }

    // Save to SharedPreferences (unchanged from your original)
    await prefs.saveStreak(habit['id'], streak);
    prefs.saveTimerState(false, 0, "");
    await _savePausedTimes();
    await _saveHabitsToLocal();

    debugPrint('Completed $habitName with streak: $streak');

    // Force UI refresh to ensure streak is displayed (unchanged from your original)
    setState(() {}); // Trigger rebuild to reflect updated streak in stats
  }
  Future<void> _completeHabit(String habitName) async {
    try {
      final habit = habits.firstWhere((h) => h['name'] == habitName, orElse: () => throw Exception('Habit not found'));
      if (habit['id'] == null) throw Exception('Habit ID is missing');

      final docRef = firestore.collection('habits').doc(habit['id']);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({'completed': true, 'lastCompleted': DateTime.now(), ...habit});
      } else {
        await docRef.update({'completed': true, 'lastCompleted': DateTime.now()});
      }

      setState(() {
        habit['completed'] = true;
        isTimerRunning = false;
      });

      await prefs.updateStreak(habit['id']);
      final streak = prefs.getStreak(habit['id']);
      await prefs.clearTimerState();

      await notificationHelper.scheduleCompletionCelebration(habitName: habitName, streak: streak, context: context);
    } catch (e) {
      debugPrint('Error completing habit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error completing habit: $e'), backgroundColor: Colors.red));
      }
    }
    _saveHabitsToLocal();
  }

    Future<void> _updateBackground(String habitName) async {
    try {
      final newBackground = await backgroundHelper.getBackgroundForHabit(habitName);
      setState(() {
        backgroundImage = newBackground;
      });
    } catch (e) {
      print('Error updating background: $e');
    }
  }

  void _scheduleNotification(String habitName) async {
    await notificationHelper.scheduleHabitReminder(
      habitId: habits.firstWhere((h) => h['name'] == habitName)['id'],
      habitName: habitName,
      reminderTime: TimeOfDay.now().replacing(minute: TimeOfDay.now().minute + 1),
      isDaily: true,
    );
  }

  Future<void> _loadInitialBackground() async {
    try {
      final defaultBackground = await backgroundHelper.getBackgroundForHabit('meditation');
      setState(() {
        backgroundImage = defaultBackground;
      });
    } catch (e) {
      debugPrint('Error loading initial background: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.wallpaper, color: Colors.grey[900]),
          onPressed: () => showModalBottomSheet(context: context, builder: (context) => _buildBackgroundSheet()),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white.withOpacity(0.0)),
            highlightColor: Colors.transparent, // Removes hover highlight
            splashColor: Colors.transparent,
            onPressed: () => showModalBottomSheet(context: context, builder: (context) => _buildSettingsSheet()),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white.withOpacity(0.0)),
            highlightColor: Colors.transparent, // Removes hover highlight
            splashColor: Colors.transparent,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        elevation: 6,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('New Habit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAddHabitDialog(),
      ).animate().fade(duration: 500.ms),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHabits,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Stack(children: [_buildBackground(), _buildHeader()]),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressSection(),
                        SizedBox(height: 24),
                        _buildHabitStats(),
                        SizedBox(height: 24),
                        _buildQuickActions(),
                        SizedBox(height: 24),
                        _buildHabitsList(),
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: SizedBox.shrink(), // Keeps the space but removes content
    ),
  );

  Widget _buildProgressSection() {
    final totalHabits = _calculateTotalHabits();
    final completedCount = _calculateCompletedHabits();
    final progress = totalHabits > 0 ? completedCount / totalHabits : 0.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('$completedCount/$totalHabits', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: double.infinity,
              height: 8,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                  ),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: MediaQuery.of(context).size.width * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.deepPurple, Colors.deepPurple.shade300]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineProgress(String title, String routineType) {
    final totalHabits = routineHabits[routineType]?.length ?? 0;
    final completedHabits = habits.where((habit) => habit['completed'] == true && routineHabits[routineType]?.any((r) => r['name'] == habit['name']) == true).length;
    final progress = totalHabits > 0 ? completedHabits / totalHabits : 0.0;

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text('$completedHabits/$totalHabits', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: MediaQuery.of(context).size.width * progress,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.deepPurple, Colors.deepPurple.shade300]), borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitStats() => Container(
    margin: EdgeInsets.symmetric(horizontal: 16),
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(icon: Icons.local_fire_department, color: Colors.orange, value: '${_calculateLongestStreak()}', label: 'Longest Streak'),
                _buildStatItem(icon: Icons.check_circle, color: Colors.green, value: '${_calculateCompletedHabits()}', label: 'Completed Today'),
                _buildStatItem(icon: Icons.timeline, color: Colors.blue, value: '${_calculateTotalMinutes()}', label: 'Minutes Total'),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildQuickActions() => Container(
    height: 100,
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute cards evenly across full width
      children: [
        _buildQuickActionCard(
          icon: Icons.wb_sunny,
          title: 'Morning Routine',
          routineType: 'morning',
          onTap: () => _startRoutine('morning'),
        ),
        _buildQuickActionCard(
          icon: Icons.nightlight_round,
          title: 'Evening Routine',
          routineType: 'evening',
          onTap: () => _startRoutine('evening'),
        ),
        _buildQuickActionCard(
          icon: Icons.fitness_center,
          title: 'Workout',
          routineType: 'workout',
          onTap: () => _startRoutine('workout'),
        ),
        _buildQuickActionCard(
          icon: Icons.book,
          title: 'Study Session',
          routineType: 'study',
          onTap: () => _startRoutine('study'),
        ),
      ],
    ),
  );
// Updated _buildQuickActionCard with highlighting
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String routineType,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedRoutine == routineType;

    return Card(
      elevation: isSelected ? 6 : 2, // Higher elevation for selected
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isSelected ? Colors.deepPurple.withOpacity(0.9) : Colors.white, // Highlight selected
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.deepPurple, // White icon when selected
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87, // White text when selected
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitsList() => Container(
    height: MediaQuery.of(context).size.height * 0.5,
    child: ListView.builder(
      shrinkWrap: true,
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: habits.where((habit) => habit['routineType'] == selectedRoutine).length,
      itemBuilder: (context, index) {
        final filteredHabits = habits.where((habit) => habit['routineType'] == selectedRoutine).toList();
        if (filteredHabits.isEmpty) {
          debugPrint('No habits found for $selectedRoutine');
        } else {
          debugPrint('Displaying habit: ${filteredHabits[index]['name']}, Routine: $selectedRoutine');
        }
        final habit = filteredHabits[index];
        return _buildHabitCard(habit);
      },
    ),
  );
  Widget _buildHabitCard(Map<String, dynamic> habit) {
    final progress = habit['progress'] ?? 0.0;
    final isSelected = selectedHabit == habit['name'];

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: isSelected ? 4 : 1,
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: habit['completed'] ? Colors.green : Colors.deepPurple,
              child: Icon(habit['completed'] ? Icons.check : Icons.timer, color: Colors.white),
            ),
            title: Text(
              habit['name'],
              style: TextStyle(decoration: habit['completed'] ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(habit['description'] ?? ''),
                SizedBox(height: 4),
                Row(children: [Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]), SizedBox(width: 4), Text('${habit['durationMinutes']} minutes', style: TextStyle(color: Colors.grey[600]))]),
                if (isSelected && isTimerRunning) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, size: 16, color: Colors.deepPurple),
                        SizedBox(width: 4),
                        Text('${(remainingTime ~/ 60).toString().padLeft(2, '0')}:${(remainingTime % 60).toString().padLeft(2, '0')}', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            trailing: Container(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!habit['completed']) ...[
                    IconButton(
                      icon: Icon(isSelected && isTimerRunning ? Icons.stop : Icons.play_arrow, color: isSelected && isTimerRunning ? Colors.red : Colors.green),
                      onPressed: () => _startTimer(habit['name']),
                    ),
                    IconButton(
                      icon: Icon(habit['reminderTime'] != null ? Icons.alarm_on : Icons.alarm_add, color: habit['reminderTime'] != null ? Colors.deepPurple : Colors.grey),
                      onPressed: () => _showReminderOptions(habit),
                    ),
                  ] else
                    Icon(Icons.check_circle, color: Colors.green),
                  IconButton(icon: Icon(Icons.delete_outline, color: Colors.red[300]), onPressed: () => _showDeleteConfirmation(habit)),
                ],
              ),
            ),
          ),
          if (!habit['completed'])
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${(progress * 100).toInt()}%', style: TextStyle(color: _getProgressColor(progress), fontWeight: FontWeight.bold))]),
                  SizedBox(height: 4),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(progress)), minHeight: 8),
                      ),
                      if (isSelected && isTimerRunning)
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.2), Colors.transparent], stops: [0.0, 0.5, 1.0]),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimerButton(Map<String, dynamic> habit) {
    final isSelected = selectedHabit == habit['name'];
    return IconButton(
      icon: Icon(isSelected ? Icons.stop_circle : Icons.play_circle, color: isSelected ? Colors.red : Colors.green, size: 28),
      onPressed: () {
        if (!isSelected) {
          setState(() => selectedHabit = habit['name']);
          _startTimer(habit['name']);
        } else {
          _startTimer(habit['name']);
        }
      },
    );
  }

  Widget _buildReminderButton(Map<String, dynamic> habit) {
    return IconButton(
      icon: Icon(habit['reminderTime'] != null ? Icons.alarm_on : Icons.alarm_add, color: habit['reminderTime'] != null ? Colors.deepPurple : Colors.grey),
      onPressed: () async {
        if (habit['reminderTime'] != null) {
          _showReminderOptions(habit);
        } else {
          final TimeOfDay? selectedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
          if (selectedTime != null) {
            await _updateHabitReminder(habit, selectedTime);
          }
        }
      },
    );
  }

  void _showReminderOptions(Map<String, dynamic> habit) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('Edit Reminder'),
              subtitle: Text('Current time: ${habit['reminderTime'] ?? 'Not set'}'),
              onTap: () async {
                Navigator.pop(context);
                final TimeOfDay? selectedTime = await showTimePicker(
                  context: context,
                  initialTime: habit['reminderTime'] != null
                      ? TimeOfDay(hour: int.parse(habit['reminderTime'].split(':')[0]), minute: int.parse(habit['reminderTime'].split(':')[1]))
                      : TimeOfDay.now(),
                );
                if (selectedTime != null) {
                  await _updateHabitReminder(habit, selectedTime);
                }
              },
            ),
            if (habit['reminderTime'] != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete Reminder'),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteHabitReminder(habit);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateHabitReminder(Map<String, dynamic> habit, TimeOfDay time) async {
    try {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      await firestore.collection('habits').doc(habit['id']).update({'reminderTime': timeString});
      setState(() => habit['reminderTime'] = timeString);
      await notificationHelper.scheduleHabitReminder(habitId: habit['id'], habitName: habit['name'], reminderTime: time, isDaily: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder set for ${habit['name']}'), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint('Error updating reminder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error setting reminder'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteHabitReminder(Map<String, dynamic> habit) async {
    try {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete Reminder'),
          content: Text('Are you sure you want to delete this reminder?'),
          actions: [
            TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
            TextButton(child: Text('Delete', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.pop(context, true)),
          ],
        ),
      );

      if (confirm == true) {
        await notificationHelper.cancelHabitNotifications(habit['id']);
        await firestore.collection('habits').doc(habit['id']).update({'reminderTime': null});
        setState(() => habit['reminderTime'] = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder removed'), backgroundColor: Colors.orange));
        }
      }
    } catch (e) {
      debugPrint('Error removing reminder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error removing reminder'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildBackground() => Container(
    height: MediaQuery.of(context).size.height * 0.5,
    width: MediaQuery.of(context).size.width,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.deepPurple.withOpacity(0.8), Colors.deepPurple.withOpacity(0.2)],
      ),
    ),
    child: backgroundImage.isNotEmpty
        ? Image.network(backgroundImage, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.deepPurple.withOpacity(0.1)))
        : Container(color: Colors.deepPurple.withOpacity(0.1)),
  );

  IconData _getHabitIcon(String habitName) {
    final icons = {
      'meditation': Icons.self_improvement,
      'exercise': Icons.fitness_center,
      'reading': Icons.book,
      'studying': Icons.school,
      'yoga': Icons.spa,
      'walking': Icons.directions_walk,
      'writing': Icons.edit,
      'drinking': Icons.local_drink,
      'running': Icons.directions_run,
      'sleeping': Icons.bedtime,
      'coding': Icons.code,
      'swimming': Icons.pool,
      'cycling': Icons.directions_bike,
      'workout': Icons.fitness_center,
      'stretching': Icons.accessibility_new,
      'morning': Icons.wb_sunny,
      'evening': Icons.nights_stay,
    };
    String normalizedName = habitName.toLowerCase();
    return icons.entries.firstWhere((entry) => normalizedName.contains(entry.key), orElse: () => MapEntry('', Icons.check_circle_outline)).value;
  }

  Widget _buildSettingsSheet() => Container(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.notifications),
          title: Text('Notifications'),
          trailing: Switch(
            value: true,
            onChanged: (value) async {
              if (value) {
                await notificationHelper.requestPermissions();
              } else {
                await notificationHelper.cancelAllNotifications();
              }
              setState(() {});
            },
          ),
        ),
      ],
    ),
  );

  void _showDurationPicker(Map<String, dynamic> habit) {
    showDialog(
      context: context,
      builder: (context) {
        int selectedDuration = habit['durationMinutes'] ?? 10;
        return AlertDialog(
          title: Text('Set Duration'),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Minutes: $selectedDuration'),
                Slider(
                  min: 1,
                  max: 60,
                  divisions: 59,
                  value: selectedDuration.toDouble(),
                  onChanged: (value) => setState(() => selectedDuration = value.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(child: Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                await firestore.collection('habits').doc(habit['id']).update({'durationMinutes': selectedDuration});
                setState(() => habit['durationMinutes'] = selectedDuration);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackgroundSheet() => Container(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Change Background', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.refresh),
          title: Text('Random Background'),
          onTap: () async {
            final newBackground = await backgroundHelper.getRandomBackground();
            setState(() => backgroundImage = newBackground);
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.image),
          title: Text('Habit-based Background'),
          onTap: () async {
            if (selectedHabit.isNotEmpty) {
              final newBackground = await backgroundHelper.getBackgroundForHabit(selectedHabit);
              setState(() => backgroundImage = newBackground);
            }
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );

  void _showAddHabitDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    int selectedMinutes = 5;
    TimeOfDay? reminderTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add New Habit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Habit Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: Colors.deepPurple, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedMinutes,
                            onChanged: (value) => setState(() => selectedMinutes = value!),
                            items: [1, 5, 10, 15, 20, 25, 30, 45, 60]
                                .map<DropdownMenuItem<int>>(
                                  (int value) => DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value minutes'),
                              ),
                            )
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.notifications, color: Colors.deepPurple),
                  title: Text(reminderTime != null
                      ? 'Daily reminder at ${reminderTime!.format(context)}'
                      : 'Set daily reminder'),
                  trailing: reminderTime != null
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => setState(() => reminderTime = null),
                  )
                      : null,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) setState(() => reminderTime = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await _addHabit(
                    nameController.text,
                    descriptionController.text,
                    selectedMinutes,
                    reminderTime,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addHabit(String name, String description, int durationMinutes, TimeOfDay? reminderTime) async {
    try {
      setState(() => isLoading = true);
      final user = auth.currentUser;
      if (user != null) {
        final habitData = {
          'userId': user.uid,
          'name': name.trim(),
          'description': description.trim(),
          'completed': false,
          'countedInStats': false,
          'streak': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'durationMinutes': durationMinutes,
          'routineType': selectedRoutine,
          'progress': 0.0,
          'reminderTime': reminderTime != null ? '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}' : null,
          'lastCompleted': null,
        };
        final docRef = await firestore.collection('habits').add(habitData);
        final habitId = docRef.id;

        if (reminderTime != null) {
          await notificationHelper.scheduleHabitReminder(habitId: habitId, habitName: name, reminderTime: reminderTime, isDaily: true);
        }

        setState(() {
          habits.add({'id': habitId, ...habitData, 'createdAt': DateTime.now()});
        });
        await _loadDailyStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Habit added successfully!'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      debugPrint('Error adding habit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add habit: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit['name']}"?'),
        actions: [
          TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await _deleteHabit(habit);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHabit(Map<String, dynamic> habit) async {
    try {
      await firestore.collection('habits').doc(habit['id']).delete();
      setState(() => habits.removeWhere((h) => h['id'] == habit['id']));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Habit deleted successfully'), backgroundColor: Colors.green));
      }
      await notificationHelper.cancelHabitNotifications(habit['id']);
    } catch (e) {
      debugPrint('Error deleting habit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting habit: $e'), backgroundColor: Colors.red));
      }
    }
    _saveHabitsToLocal();
  }

  int _calculateLongestStreak() {
    int longest = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var habit in habits) {
      int streak = habit['streak'] as int? ?? 0;
      final lastCompleted = habit['lastCompleted'] != null ? _parseDate(habit['lastCompleted']) : null;

      if (lastCompleted != null) {
        final daysSinceLast = today.difference(DateTime(lastCompleted.year, lastCompleted.month, lastCompleted.day)).inDays;
        debugPrint('Calculating streak for ${habit['name']}: Last Completed: $lastCompleted, Days Since: $daysSinceLast, Current Streak: $streak');
        if (daysSinceLast > 1 && streak > 0) {
          streak = 0; // Reset streak if broken
          habit['streak'] = 0;
          firestore.collection('habits').doc(habit['id']).update({'streak': 0}).then((_) {
            debugPrint('Reset streak for ${habit['name']} to 0 in Firestore');
          }).catchError((e) {
            debugPrint('Error resetting streak for ${habit['name']} in Firestore: $e');
          });
        }
      }
      if (streak > longest) longest = streak;
      debugPrint('Habit: ${habit['name']}, Streak: $streak');
    }
    debugPrint('Longest Streak Calculated: $longest');
    return longest;
  }
  Future<void> _updateHabitStreak(String habitName) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final habit = habits.firstWhere((h) => h['name'] == habitName, orElse: () => throw Exception('Habit not found'));
    final lastCompleted = habit['lastCompleted'] != null ? _parseDate(habit['lastCompleted']) : null;
    int streak = habit['streak'] as int? ?? 0;

    // Calculate new streak
    if (lastCompleted != null) {
      final daysSinceLast = today.difference(DateTime(lastCompleted.year, lastCompleted.month, lastCompleted.day)).inDays;
      debugPrint('Updating streak for $habitName - Days since last: $daysSinceLast, Current Streak: $streak');
      if (daysSinceLast > 1) {
        streak = 1; // Reset streak if more than 1 day gap
      } else if (daysSinceLast == 1) {
        streak++; // Increment streak for consecutive days
      } else if (daysSinceLast == 0) {
        debugPrint('Same day completion for $habitName, streak remains $streak');
        return; // No increment if already completed today
      }
    } else {
      streak = 1; // First completion
    }

    // Update local state
    setState(() {
      habit['streak'] = streak;
      habit['lastCompleted'] = now;
    });

    // Persist to Firestore
    try {
      await firestore.collection('habits').doc(habit['id']).update({
        'streak': streak,
        'lastCompleted': now.toIso8601String(),
      });
      debugPrint('Firestore streak updated for $habitName to $streak');
    } catch (e) {
      debugPrint('Error updating streak in Firestore for $habitName: $e');
    }

    // Save to SharedPreferences
    await prefs.saveStreak(habit['id'], streak);
    await _saveHabitsToLocal();

    debugPrint('Streak updated for $habitName: $streak');

    // Force UI refresh
    setState(() {});
  }
  int _calculateCompletedHabits() {
    return habits.where((h) => h['routineType'] == selectedRoutine && h['completed'] == true).length;
  }

  int _calculateTotalMinutes() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return habits
        .where((h) => h['routineType'] == selectedRoutine && h['completed'] == true && h['lastCompleted'] != null && _parseDate(h['lastCompleted']).isAfter(startOfDay))
        .fold(0, (sum, h) => sum + (h['durationMinutes'] as int? ?? 10));
  }

  Future<void> _updateStreakInBackground(String habitId, int streak) async {
    try {
      await firestore.collection('habits').doc(habitId).update({'streak': streak});
      await prefs.saveStreak(habitId, streak);
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }



  Widget _buildStatItem({required IconData icon, required Color color, required String value, required String label}) => Column(
    children: [
      Icon(icon, color: color, size: 28),
      SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ],
  );

  Future<void> _loadRoutineHabits(String routineType) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      debugPrint('Checking habits for $routineType');

      final existingSnapshot = await firestore
          .collection('habits')
          .where('userId', isEqualTo: user.uid)
          .where('routineType', isEqualTo: routineType)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThan: endOfDay)
          .get();

      if (existingSnapshot.docs.isEmpty) {
        final predefinedHabits = routineHabits[routineType] ?? [];
        debugPrint('Adding ${predefinedHabits.length} predefined habits for $routineType');
        final newHabits = await Future.wait(
          predefinedHabits.map((habit) async {
            final docRef = firestore.collection('habits').doc();
            final habitData = {
              'id': docRef.id,
              'userId': user.uid,
              'name': habit['name'],
              'description': habit['description'],
              'durationMinutes': habit['durationMinutes'],
              'completed': false,
              'countedInStats': false,
              'streak': 0,
              'createdAt': DateTime.now(),
              'routineType': routineType,
              'progress': 0.0,
              'image': habit['image'],
              'lastCompleted': null,
            };
            await docRef.set(habitData);
            return habitData;
          }),
        );
        setState(() {
          habits.addAll(newHabits);
          debugPrint('After adding $routineType, total habits: ${habits.length}');
        });
        await _saveHabitsToLocal();
        debugPrint('Added ${newHabits.length} habits for $routineType');
      } else {
        debugPrint('Found ${existingSnapshot.docs.length} existing habits for $routineType');
      }
    } catch (e) {
      debugPrint('Error loading routine habits for $routineType: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading routine habits: $e'), backgroundColor: Colors.red));
      }
    }
  }
  void _stopTimer(String habitName) {
    habitTimer?.cancel();
    setState(() {
      isTimerRunning = false;
    });
    prefs.saveTimerState(false, remainingTime, habitName);
    _savePausedTimes();
    debugPrint('Stopped timer: remainingTime=$remainingTime, selectedHabit=$selectedHabit');
  }

  int _getHabitDuration() => selectedHabit.isEmpty
      ? 600
      : (habits.firstWhere((h) => h['name'] == selectedHabit, orElse: () => {'durationMinutes': 10})['durationMinutes'] ?? 10) * 60;

  String _getRoutineTitle(String routineType) {
    switch (routineType) {
      case 'morning':
        return 'Morning Routine';
      case 'evening':
        return 'Evening Routine';
      case 'workout':
        return 'Workout';
      case 'study':
        return 'Study Session';
      default:
        return 'Daily Progress';
    }
  }

  Future<void> _updateDailyStats(String habitName) async {
    try {
      final habit = habits.firstWhere((h) => h['name'] == habitName);
      final routineType = habit['routineType'] ?? 'morning';
      final now = DateTime.now();

      if (lastStatsReset == null || !_isSameDay(lastStatsReset!, now)) {
        await _resetDailyStats();
      }
      if (!habit['countedInStats']) {
        setState(() {
          routineStats[routineType] ??= DailyStats(date: now);
          routineStats[routineType]!.completedHabits++;
          routineStats[routineType]!.totalMinutes += habit['durationMinutes'] as int? ?? 10;
        });
        habit['countedInStats'] = true;
        await firestore.collection('habits').doc(habit['id']).update({
          'countedInStats': true,
          'lastUpdated': now.toIso8601String(),
        });
        await _saveDailyStats();
      }
    } catch (e) {
      debugPrint('Error updating daily stats: $e');
    }
  }

  Future<void> _resetDailyStats() async {
    final now = DateTime.now();
    setState(() {
      routineStats = {
        'morning': DailyStats(date: now, completedHabits: 0, totalMinutes: 0),
        'evening': DailyStats(date: now, completedHabits: 0, totalMinutes: 0),
        'workout': DailyStats(date: now, completedHabits: 0, totalMinutes: 0),
        'study': DailyStats(date: now, completedHabits: 0, totalMinutes: 0),
      };
      lastStatsReset = now;
      for (var habit in habits) {
        habit['countedInStats'] = false;
        firestore.collection('habits').doc(habit['id']).update({'countedInStats': false});
      }
    });
    await _saveDailyStats();
    await prefs.setString('last_stats_reset', now.toIso8601String());
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final startOfDayA = DateTime(a.year, a.month, a.day);
    final startOfDayB = DateTime(b.year, b.month, b.day);
    return startOfDayA.year == startOfDayB.year && startOfDayA.month == startOfDayB.month && startOfDayA.day == startOfDayB.day;
  }

  Future<void> _saveDailyStats() async {
    try {
      final statsMap = routineStats.map((key, value) => MapEntry(key, value.toMap()));
      await prefs.setString('daily_stats', jsonEncode(statsMap));
      await prefs.setString('last_stats_reset', lastStatsReset?.toIso8601String() ?? '');
    } catch (e) {
      debugPrint('Error saving daily stats: $e');
    }
  }

  List<Map<String, dynamic>> _getSortedHabits() {
    final activeHabits = habits.where((h) => !h['completed']).toList();
    final completedHabits = habits.where((h) => h['completed']).toList();
    activeHabits.sort((a, b) => a['name'].compareTo(b['name']));
    completedHabits.sort((a, b) => (b['lastCompleted'] ?? DateTime.now()).compareTo(a['lastCompleted'] ?? DateTime.now()));
    return [...activeHabits, ...completedHabits];
  }

  void _restoreReminders() {
    try {
      for (var habit in habits) {
        if (habit['reminderTime'] != null) {
          final timeStr = habit['reminderTime'] as String;
          final parts = timeStr.split(':');
          if (parts.length == 2) {
            final reminderTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
            notificationHelper.scheduleHabitReminder(habitId: habit['id'], habitName: habit['name'], reminderTime: reminderTime, isDaily: true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error restoring reminders: $e');
    }
  }

  Future<void> _loadDailyStats() async {
    try {
      final statsString = prefs.getString('daily_stats');
      final resetString = prefs.getString('last_stats_reset');
      final now = DateTime.now();

      if (statsString != null && resetString != null) {
        final lastReset = DateTime.parse(resetString);
        if (_isSameDay(lastReset, now)) {
          final statsMap = jsonDecode(statsString) as Map<String, dynamic>;
          routineStats = statsMap.map((key, value) => MapEntry(key, DailyStats.fromMap(value as Map<String, dynamic>)));
          lastStatsReset = lastReset;
        } else {
          await _resetDailyStats();
        }
      } else {
        await _resetDailyStats();
      }
    } catch (e) {
      debugPrint('Error loading daily stats: $e');
      await _resetDailyStats();
    }
  }

  Color _getProgressColor(double progress) => progress >= 1.0 ? Colors.green : progress >= 0.6 ? Colors.green : Colors.deepPurple;

  void _restartTimer(String habitName, int savedTime) {
    habitTimer?.cancel();

    final habit = habits.firstWhere((h) => h['name'] == habitName, orElse: () => {'durationMinutes': 10});
    final duration = habit['durationMinutes'] as int? ?? 10;

    remainingTime = savedTime;

    debugPrint('Restarting timer: habit=$habitName, remainingTime=$remainingTime');

    habitTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
          final progress = 1 - (remainingTime / (duration * 60));
          final index = habits.indexWhere((h) => h['name'] == habitName);
          if (index != -1) {
            habits[index]['progress'] = progress;
            firestore.collection('habits').doc(habits[index]['id']).update({'progress': progress});
            if (progress >= 0.6 && !habits[index]['countedInStats']) {
              habits[index]['countedInStats'] = true;
              firestore.collection('habits').doc(habits[index]['id']).update({'countedInStats': true});
              _updateDailyStats(habitName);
            }
            if (progress >= 1.0 && !habits[index]['completed']) {
              _completeTimer(habitName);
            }
          }
        });
        prefs.saveTimerState(true, remainingTime, habitName);
      } else {
        timer.cancel();
        _completeTimer(habitName);
      }
    });
  }

  int _calculateTotalHabits() => habits.where((h) => h['routineType'] == selectedRoutine).length;

  Future<void> _saveHabitsToLocal() async {
    try {
      final habitsJson = habits.map((habit) {
        return {
          ...habit,
          'createdAt': _parseDate(habit['createdAt']).toIso8601String(),
          'lastCompleted': habit['lastCompleted'] != null ? _parseDate(habit['lastCompleted']).toIso8601String() : null,
          'progress': habit['progress'] ?? 0.0,
          'completed': habit['completed'] ?? false,
        };
      }).toList();
      await prefs.setString('habits_data', jsonEncode(habitsJson));
    } catch (e) {
      debugPrint('Error saving habits to local: $e');
    }
  }

  bool _hasHabitsChanged(List<Map<String, dynamic>> newHabits) {
    if (habits.length != newHabits.length) return true;
    for (int i = 0; i < habits.length; i++) {
      if (habits[i]['id'] != newHabits[i]['id'] || habits[i]['progress'] != newHabits[i]['progress'] || habits[i]['completed'] != newHabits[i]['completed']) return true;
    }
    return false;
  }

  Future<void> _savePausedTimes() async => await prefs.setString('paused_times', jsonEncode(pausedTimes));

  Future<void> _loadPausedTimes() async {
    final savedTimes = prefs.getString('paused_times');
    if (savedTimes != null) {
      final decoded = jsonDecode(savedTimes) as Map<String, dynamic>;
      pausedTimes = decoded.map((key, value) => MapEntry(key, value as int));
    }
    debugPrint('Loaded paused times: $pausedTimes');
  }
}
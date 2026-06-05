import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({Key? key}) : super(key: key);

  void _showAchievementHelp(BuildContext context, String title, String type, String goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(
          'Type: $type\nGoal: $goal\n\nComplete habits daily or track more habits to unlock this achievement!',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Stream<Map<String, dynamic>> _fetchAchievementsData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value({
        'streak': 0,
        'habitsTracked': 0,
        'habitsCompleted': 0,
        'morningRoutinesCompleted': 0,
        'routineHabitsCompleted': 0,
        'loginDays': 0,
        'weeklyGoalsMet': 0,
        'habitsShared': 0,
      });
    }

    return FirebaseFirestore.instance
        .collection('achievements')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data() ?? {
      'streak': 0,
      'habitsTracked': 0,
      'habitsCompleted': 0,
      'morningRoutinesCompleted': 0,
      'routineHabitsCompleted': 0,
      'loginDays': 0,
      'weeklyGoalsMet': 0,
      'habitsShared': 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Achievements"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _fetchAchievementsData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final int streak = snapshot.data?['streak'] ?? 0;
          final int habitsTracked = snapshot.data?['habitsTracked'] ?? 0;
          final int habitsCompleted = snapshot.data?['habitsCompleted'] ?? 0;
          final int morningRoutinesCompleted = snapshot.data?['morningRoutinesCompleted'] ?? 0;
          final int routineHabitsCompleted = snapshot.data?['routineHabitsCompleted'] ?? 0;
          final int loginDays = snapshot.data?['loginDays'] ?? 0;
          final int weeklyGoalsMet = snapshot.data?['weeklyGoalsMet'] ?? 0;
          final int habitsShared = snapshot.data?['habitsShared'] ?? 0;

          List<Map<String, dynamic>> allAchievements = [
            // Existing Achievements (from your original structure)
            {'title': 'Habit Starter', 'type': 'Streak-Based', 'description': 'Complete your first habit!', 'goal': 'Achieve a 1-day streak by completing a habit.', 'progress': 1, 'current': streak, 'unlocked': streak >= 1},
            {'title': 'Streak Master', 'type': 'Streak-Based', 'description': 'Achieve a 7-day streak!', 'goal': 'Complete a habit daily for 7 consecutive days.', 'progress': 7, 'current': streak, 'unlocked': streak >= 7},
            {'title': 'Habit Legend', 'type': 'Streak-Based', 'description': 'Achieve a 30-day streak!', 'goal': 'Complete a habit daily for 30 consecutive days.', 'progress': 30, 'current': streak, 'unlocked': streak >= 30},
            {'title': 'Habit Beginner', 'type': 'Habit-Tracking-Based', 'description': 'Track 5+ habits!', 'goal': 'Track 5 different habits.', 'progress': 5, 'current': habitsTracked, 'unlocked': habitsTracked >= 5},
            {'title': 'First Step', 'type': 'Completion-Based', 'description': 'Complete a habit!', 'goal': 'Complete any habit once.', 'progress': 1, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 1},
            {'title': 'Habit Finisher', 'type': 'Completion-Based', 'description': 'Complete 10 habits!', 'goal': 'Complete habits 10 times.', 'progress': 10, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 10},
            {'title': 'Morning Person', 'type': 'Morning-Routine-Based', 'description': 'Complete morning routine once!', 'goal': 'Complete your morning routine 1 time.', 'progress': 1, 'current': morningRoutinesCompleted, 'unlocked': morningRoutinesCompleted >= 1},
            {'title': 'Routine Rookie', 'type': 'Routine-Based', 'description': 'Complete any habit in any routine!', 'goal': 'Complete 1 habit from any routine.', 'progress': 1, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 1},

            // 50 New Achievements
            // Streak-Based Achievements
            {'title': 'Streak Novice', 'type': 'Streak-Based', 'description': 'Achieve a 3-day streak!', 'goal': 'Complete a habit daily for 3 days.', 'progress': 3, 'current': streak, 'unlocked': streak >= 3},
            {'title': 'Streak Enthusiast', 'type': 'Streak-Based', 'description': 'Achieve a 10-day streak!', 'goal': 'Complete a habit daily for 10 days.', 'progress': 10, 'current': streak, 'unlocked': streak >= 10},
            {'title': 'Streak Pro', 'type': 'Streak-Based', 'description': 'Achieve a 15-day streak!', 'goal': 'Complete a habit daily for 15 days.', 'progress': 15, 'current': streak, 'unlocked': streak >= 15},
            {'title': 'Streak Veteran', 'type': 'Streak-Based', 'description': 'Achieve a 20-day streak!', 'goal': 'Complete a habit daily for 20 days.', 'progress': 20, 'current': streak, 'unlocked': streak >= 20},
            {'title': 'Streak Elite', 'type': 'Streak-Based', 'description': 'Achieve a 50-day streak!', 'goal': 'Complete a habit daily for 50 days.', 'progress': 50, 'current': streak, 'unlocked': streak >= 50},
            {'title': 'Streak Titan', 'type': 'Streak-Based', 'description': 'Achieve a 60-day streak!', 'goal': 'Complete a habit daily for 60 days.', 'progress': 60, 'current': streak, 'unlocked': streak >= 60},
            {'title': 'Streak Conqueror', 'type': 'Streak-Based', 'description': 'Achieve a 75-day streak!', 'goal': 'Complete a habit daily for 75 days.', 'progress': 75, 'current': streak, 'unlocked': streak >= 75},
            {'title': 'Streak Immortal', 'type': 'Streak-Based', 'description': 'Achieve a 100-day streak!', 'goal': 'Complete a habit daily for 100 days.', 'progress': 100, 'current': streak, 'unlocked': streak >= 100},
            {'title': 'Perfect Fortnight', 'type': 'Streak-Based', 'description': 'Achieve a 14-day streak!', 'goal': 'Complete a habit daily for 14 days.', 'progress': 14, 'current': streak, 'unlocked': streak >= 14},
            {'title': 'Month of Mastery', 'type': 'Streak-Based', 'description': 'Achieve a 31-day streak!', 'goal': 'Complete a habit daily for 31 days.', 'progress': 31, 'current': streak, 'unlocked': streak >= 31},

            // Completion-Based Achievements
            {'title': 'Habit Sprinter', 'type': 'Completion-Based', 'description': 'Complete 5 habits!', 'goal': 'Complete 5 habits total.', 'progress': 5, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 5},
            {'title': 'Habit Runner', 'type': 'Completion-Based', 'description': 'Complete 15 habits!', 'goal': 'Complete 15 habits total.', 'progress': 15, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 15},
            {'title': 'Habit Marathoner', 'type': 'Completion-Based', 'description': 'Complete 25 habits!', 'goal': 'Complete 25 habits total.', 'progress': 25, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 25},
            {'title': 'Habit Ultra', 'type': 'Completion-Based', 'description': 'Complete 50 habits!', 'goal': 'Complete 50 habits total.', 'progress': 50, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 50},
            {'title': 'Habit Century', 'type': 'Completion-Based', 'description': 'Complete 100 habits!', 'goal': 'Complete 100 habits total.', 'progress': 100, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 100},
            {'title': 'Habit Conqueror', 'type': 'Completion-Based', 'description': 'Complete 150 habits!', 'goal': 'Complete 150 habits total.', 'progress': 150, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 150},
            {'title': 'Habit Overlord', 'type': 'Completion-Based', 'description': 'Complete 200 habits!', 'goal': 'Complete 200 habits total.', 'progress': 200, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 200},
            {'title': 'Daily Doer', 'type': 'Completion-Based', 'description': 'Complete 5 habits in one day!', 'goal': 'Complete 5 habits in a single day.', 'progress': 5, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 5}, // Note: Needs daily tracking
            {'title': 'Daily Dynamo', 'type': 'Completion-Based', 'description': 'Complete 10 habits in one day!', 'goal': 'Complete 10 habits in a single day.', 'progress': 10, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 10}, // Note: Needs daily tracking
            {'title': 'Habit Titan', 'type': 'Completion-Based', 'description': 'Complete 250 habits!', 'goal': 'Complete 250 habits total.', 'progress': 250, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 250},

            // Routine-Based Achievements (General)
            {'title': 'Routine Regular', 'type': 'Routine-Based', 'description': 'Complete 5 routine habits!', 'goal': 'Complete 5 habits from any routine.', 'progress': 5, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 5},
            {'title': 'Routine Enthusiast', 'type': 'Routine-Based', 'description': 'Complete 15 routine habits!', 'goal': 'Complete 15 habits from any routine.', 'progress': 15, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 15},
            {'title': 'Routine Master', 'type': 'Routine-Based', 'description': 'Complete 25 routine habits!', 'goal': 'Complete 25 habits from any routine.', 'progress': 25, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 25},
            {'title': 'Routine Pro', 'type': 'Routine-Based', 'description': 'Complete 50 routine habits!', 'goal': 'Complete 50 habits from any routine.', 'progress': 50, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 50},
            {'title': 'Routine Legend', 'type': 'Routine-Based', 'description': 'Complete 75 routine habits!', 'goal': 'Complete 75 habits from any routine.', 'progress': 75, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 75},
            {'title': 'Routine Sovereign', 'type': 'Routine-Based', 'description': 'Complete 100 routine habits!', 'goal': 'Complete 100 habits from any routine.', 'progress': 100, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 100},
            {'title': 'Routine Virtuoso', 'type': 'Routine-Based', 'description': 'Complete 150 routine habits!', 'goal': 'Complete 150 habits from any routine.', 'progress': 150, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 150},
            {'title': 'Routine Monarch', 'type': 'Routine-Based', 'description': 'Complete 200 routine habits!', 'goal': 'Complete 200 habits from any routine.', 'progress': 200, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 200},

            // Morning Routine Achievements
            {'title': 'Morning Starter', 'type': 'Morning-Routine-Based', 'description': 'Complete morning routine 3 times!', 'goal': 'Complete your morning routine 3 times.', 'progress': 3, 'current': morningRoutinesCompleted, 'unlocked': morningRoutinesCompleted >= 3},
            {'title': 'Morning Motivator', 'type': 'Morning-Routine-Based', 'description': 'Complete morning routine 10 times!', 'goal': 'Complete your morning routine 10 times.', 'progress': 10, 'current': morningRoutinesCompleted, 'unlocked': morningRoutinesCompleted >= 10},
            {'title': 'Morning Master', 'type': 'Morning-Routine-Based', 'description': 'Complete morning routine 20 times!', 'goal': 'Complete your morning routine 20 times.', 'progress': 20, 'current': morningRoutinesCompleted, 'unlocked': morningRoutinesCompleted >= 20},
            {'title': 'Morning Champion', 'type': 'Morning-Routine-Based', 'description': 'Complete morning routine 30 times!', 'goal': 'Complete your morning routine 30 times.', 'progress': 30, 'current': morningRoutinesCompleted, 'unlocked': morningRoutinesCompleted >= 30},
            {'title': 'Morning Elite', 'type': 'Morning-Routine-Based', 'description': 'Complete morning routine 50 times!', 'goal': 'Complete your morning routine 50 times.', 'progress': 50, 'current': morningRoutinesCompleted, 'unlocked': morningRoutinesCompleted >= 50},
            {'title': 'Morning Legend', 'type': 'Morning-Routine-Based', 'description': 'Complete morning routine 75 times!', 'goal': 'Complete your morning routine 75 times.', 'progress': 75, 'current': morningRoutinesCompleted, 'unlocked': morningRoutinesCompleted >= 75},
            {'title': 'Morning Immortal', 'type': 'Morning-Routine-Based', 'description': 'Complete morning routine 100 times!', 'goal': 'Complete your morning routine 100 times.', 'progress': 100, 'current': morningRoutinesCompleted, 'unlocked': morningRoutinesCompleted >= 100},

            // Other Routine-Specific Achievements (Using routineHabitsCompleted as a proxy)
            {'title': 'Evening Explorer', 'type': 'Routine-Based', 'description': 'Complete 5 evening habits!', 'goal': 'Complete 5 habits from the evening routine.', 'progress': 5, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 5}, // Adjust if evening tracked separately
            {'title': 'Evening Expert', 'type': 'Routine-Based', 'description': 'Complete 15 evening habits!', 'goal': 'Complete 15 habits from the evening routine.', 'progress': 15, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 15},
            {'title': 'Workout Warrior', 'type': 'Routine-Based', 'description': 'Complete 10 workout habits!', 'goal': 'Complete 10 habits from the workout routine.', 'progress': 10, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 10}, // Adjust if workout tracked separately
            {'title': 'Workout Wizard', 'type': 'Routine-Based', 'description': 'Complete 25 workout habits!', 'goal': 'Complete 25 habits from the workout routine.', 'progress': 25, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 25},
            {'title': 'Study Star', 'type': 'Routine-Based', 'description': 'Complete 10 study habits!', 'goal': 'Complete 10 habits from the study routine.', 'progress': 10, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 10}, // Adjust if study tracked separately
            {'title': 'Study Scholar', 'type': 'Routine-Based', 'description': 'Complete 20 study habits!', 'goal': 'Complete 20 habits from the study routine.', 'progress': 20, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 20},
            {'title': 'Evening Master', 'type': 'Routine-Based', 'description': 'Complete 30 evening habits!', 'goal': 'Complete 30 habits from the evening routine.', 'progress': 30, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 30},
            {'title': 'Workout Champion', 'type': 'Routine-Based', 'description': 'Complete 50 workout habits!', 'goal': 'Complete 50 habits from the workout routine.', 'progress': 50, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 50},
            {'title': 'Study Master', 'type': 'Routine-Based', 'description': 'Complete 50 study habits!', 'goal': 'Complete 50 habits from the study routine.', 'progress': 50, 'current': routineHabitsCompleted, 'unlocked': routineHabitsCompleted >= 50},

            // Timer-Based Achievements (Assuming timer completions count toward habitsCompleted)
            {'title': 'Timer Trainee', 'type': 'Completion-Based', 'description': 'Complete 5 habits with the timer!', 'goal': 'Finish 5 habits using the timer.', 'progress': 5, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 5},
            {'title': 'Timer Expert', 'type': 'Completion-Based', 'description': 'Complete 15 habits with the timer!', 'goal': 'Finish 15 habits using the timer.', 'progress': 15, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 15},
            {'title': 'Timer Master', 'type': 'Completion-Based', 'description': 'Complete 30 habits with the timer!', 'goal': 'Finish 30 habits using the timer.', 'progress': 30, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 30},
            {'title': 'Timer Legend', 'type': 'Completion-Based', 'description': 'Complete 50 habits with the timer!', 'goal': 'Finish 50 habits using the timer.', 'progress': 50, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 50},
            {'title': 'Timer Supreme', 'type': 'Completion-Based', 'description': 'Complete 75 habits with the timer!', 'goal': 'Finish 75 habits using the timer.', 'progress': 75, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 75},
            {'title': 'Timer God', 'type': 'Completion-Based', 'description': 'Complete 100 habits with the timer!', 'goal': 'Finish 100 habits using the timer.', 'progress': 100, 'current': habitsCompleted, 'unlocked': habitsCompleted >= 100},
          ];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: allAchievements.length,
              itemBuilder: (context, index) {
                final achievement = allAchievements[index];
                bool isUnlocked = achievement['unlocked'];
                double progress = achievement['current'] / achievement['progress'];
                progress = progress > 1.0 ? 1.0 : progress;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  color: isUnlocked ? Colors.white : Colors.grey[200],
                  child: ListTile(
                    leading: Icon(
                      Icons.emoji_events,
                      color: isUnlocked ? Colors.amber : Colors.grey,
                    ),
                    title: Text(
                      achievement['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.black : Colors.grey,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          isUnlocked
                              ? achievement['description']
                              : 'Locked: ${achievement['description']}',
                          style: TextStyle(color: isUnlocked ? Colors.black : Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${achievement['type']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnlocked ? Colors.black54 : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[300],
                          color: isUnlocked ? Colors.green : Colors.grey,
                          minHeight: 10,
                        ),
                        Text(
                          '${achievement['current'].toStringAsFixed(0)} / ${achievement['progress']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnlocked ? Colors.black54 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.blue),
                      onPressed: () => _showAchievementHelp(
                        context,
                        achievement['title'],
                        achievement['type'],
                        achievement['goal'],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
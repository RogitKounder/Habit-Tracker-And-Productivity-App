import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'accountinfoPage.dart';
import 'achievementsPage.dart';
import 'AllHabitsPage.dart';
import 'AboutPage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  String userName = "Loading...";
  String achievementBadge = "Habit Starter";
  IconData achievementIcon = Icons.star_border;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchAchievements();
  }

  Future<void> _fetchUserData() async {
    if (user == null) return;

    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        userName = userDoc['name'] ?? "User";
      });
    }
  }

  Future<void> _fetchAchievements() async {
    if (user == null) return;

    var achievementsDoc = await FirebaseFirestore.instance
        .collection('achievements')
        .doc(user!.uid)
        .get();

    if (achievementsDoc.exists) {
      int streak = achievementsDoc['streak'] ?? 0;
      int habitsTracked = achievementsDoc['habitsTracked'] ?? 0;
      int habitsCompleted = achievementsDoc['habitsCompleted'] ?? 0;
      int morningRoutinesCompleted =
          achievementsDoc['morningRoutinesCompleted'] ?? 0;
      int routineHabitsCompleted = achievementsDoc['routineHabitsCompleted'] ?? 0;
      int loginDays = achievementsDoc['loginDays'] ?? 0;
      int weeklyGoalsMet = achievementsDoc['weeklyGoalsMet'] ?? 0;
      int habitsShared = achievementsDoc['habitsShared'] ?? 0;

      if (streak >= 90) {
        setState(() {
          achievementBadge = "Streak Champion";
          achievementIcon = Icons.verified;
        });
      } else if (habitsCompleted >= 50) {
        setState(() {
          achievementBadge = "Consistency King";
          achievementIcon = Icons.verified_user;
        });
      } else if (loginDays >= 30) {
        setState(() {
          achievementBadge = "Login Legend";
          achievementIcon = Icons.login;
        });
      } else if (morningRoutinesCompleted >= 30) {
        setState(() {
          achievementBadge = "Early Bird";
          achievementIcon = Icons.wb_sunny;
        });
      } else if (streak >= 30) {
        setState(() {
          achievementBadge = "Habit Legend";
          achievementIcon = Icons.verified;
        });
      } else if (routineHabitsCompleted >= 25) {
        setState(() {
          achievementBadge = "Routine Ruler";
          achievementIcon = Icons.rule;
        });
      } else if (habitsCompleted >= 25) {
        setState(() {
          achievementBadge = "Habit Hero";
          achievementIcon = Icons.star;
        });
      } else if (habitsTracked >= 20) {
        setState(() {
          achievementBadge = "Habit Pro";
          achievementIcon = Icons.emoji_events;
        });
      } else if (weeklyGoalsMet >= 10) {
        setState(() {
          achievementBadge = "Goal Getter";
          achievementIcon = Icons.flag;
        });
      } else if (habitsShared >= 10) {
        setState(() {
          achievementBadge = "Community Star";
          achievementIcon = Icons.group;
        });
      } else if (loginDays >= 10) {
        setState(() {
          achievementBadge = "Login Lover";
          achievementIcon = Icons.login;
        });
      } else if (routineHabitsCompleted >= 10) {
        setState(() {
          achievementBadge = "Routine Regular";
          achievementIcon = Icons.repeat;
        });
      } else if (habitsCompleted >= 10) {
        setState(() {
          achievementBadge = "Habit Finisher";
          achievementIcon = Icons.check_circle;
        });
      } else if (morningRoutinesCompleted >= 7) {
        setState(() {
          achievementBadge = "Morning Routine Master";
          achievementIcon = Icons.alarm_on;
        });
      } else if (streak >= 7) {
        setState(() {
          achievementBadge = "Streak Master";
          achievementIcon = Icons.flash_on;
        });
      } else if (habitsTracked >= 10) {
        setState(() {
          achievementBadge = "Habit Enthusiast";
          achievementIcon = Icons.emoji_events;
        });
      } else if (weeklyGoalsMet >= 5) {
        setState(() {
          achievementBadge = "Week Warrior";
          achievementIcon = Icons.calendar_today;
        });
      } else if (morningRoutinesCompleted >= 5) {
        setState(() {
          achievementBadge = "Morning Motivator";
          achievementIcon = Icons.wb_sunny_outlined;
        });
      } else if (habitsShared >= 5) {
        setState(() {
          achievementBadge = "Habit Sharer";
          achievementIcon = Icons.share;
        });
      } else if (habitsTracked >= 5) {
        setState(() {
          achievementBadge = "Habit Beginner";
          achievementIcon = Icons.emoji_events;
        });
      } else if (loginDays >= 3) {
        setState(() {
          achievementBadge = "Welcome Back";
          achievementIcon = Icons.login;
        });
      } else if (morningRoutinesCompleted >= 1) {
        setState(() {
          achievementBadge = "Morning Person";
          achievementIcon = Icons.alarm;
        });
      } else if (routineHabitsCompleted >= 1) {
        setState(() {
          achievementBadge = "Routine Rookie";
          achievementIcon = Icons.play_arrow;
        });
      } else if (habitsCompleted >= 1) {
        setState(() {
          achievementBadge = "First Step";
          achievementIcon = Icons.directions_walk;
        });
      } else if (weeklyGoalsMet >= 1) {
        setState(() {
          achievementBadge = "First Goal";
          achievementIcon = Icons.flag_outlined;
        });
      } else if (habitsShared >= 1) {
        setState(() {
          achievementBadge = "Social Butterfly";
          achievementIcon = Icons.people;
        });
      } else {
        setState(() {
          achievementBadge = "Habit Starter";
          achievementIcon = Icons.star_border;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 20),
          _buildWelcomeMessage(),
          const SizedBox(height: 20),
          const Divider(),
          _buildOptionTile(Icons.person, "My Account Info", () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountInfoPage()),
            );
            _fetchUserData(); // Refresh user data after returning
          }),
          _buildOptionTile(Icons.edit, "Edit Profile", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccountInfoPage(startInEditMode: true),
              ),
            ).then((_) => _fetchUserData()); // Refresh user data after returning
          }),
          _buildOptionTile(Icons.list, "All of my habits", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllHabitsPage()),
            );
          }),
          _buildOptionTile(Icons.info, "About This App", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutPage()),
            );
          }),
          _buildOptionTile(Icons.emoji_events, "Achievements", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AchievementsPage(),
              ),
            );
          }),
          const Divider(),
          Center(
            child: TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text(
                "Log Out",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                achievementIcon,
                size: 50,
                color: Colors.white,
              ),
              const SizedBox(height: 5),
              Text(
                achievementBadge,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          userName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeMessage() {
    String greeting;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = "Good morning, $userName!";
    } else if (hour < 17) {
      greeting = "Good afternoon, $userName!";
    } else {
      greeting = "Good evening, $userName!";
    }

    return Column(
      children: [
        Center(
          child: Text(
            greeting,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: Text(
            "Let’s make today count!",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
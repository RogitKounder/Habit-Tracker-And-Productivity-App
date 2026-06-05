import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About App"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple, // Consistent with other pages
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Icon
            ClipOval(
              child: Image.asset(
                'assets/logo.png', // Path to your logo in the assets folder
                width: 150, // Adjust the width as needed
                height: 150, // Adjust the height as needed
                fit: BoxFit.cover, // Ensures the image covers the circular area
              ),
            ),

            // App Description
            const Text(
              "Welcome to Habit!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Habit is a habit-tracking app designed to help you create and maintain positive routines. From morning rituals to fitness goals, Habitfy keeps you motivated with personalized tracking and rewarding achievements.",
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Features Section
            _buildSectionTitle("Key Features"),
            _buildFeatureItem(Icons.wb_sunny, "Daily Routines", "Track your morning and evening routines effortlessly."),
            _buildFeatureItem(Icons.fitness_center, "Habit Monitoring", "Stay on top of your habits with streaks and stats."),
            _buildFeatureItem(Icons.emoji_events, "Achievements", "Unlock badges as you reach milestones."),
            _buildFeatureItem(Icons.person, "Profile Customization", "Personalize your account details."),
            const SizedBox(height: 20),

            // Version Info
            _buildSectionTitle("Version"),
            const Text(
              "Version 1.0.0",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),

            // Credits Section
            _buildSectionTitle("Credits"),
            const Text(
              "Developed by: Rogit Shankar Kounder\n"
                  "Guided by: Ms. Srishti Dubey",
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Optional Motivational Quote
            const Text(
              "Building better habits, one step at a time.",
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Helper method to build feature items (centered)
  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepPurple, size: 40), // Larger icon for emphasis
            const SizedBox(height: 8), // Space between icon and text
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4), // Space between title and description
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
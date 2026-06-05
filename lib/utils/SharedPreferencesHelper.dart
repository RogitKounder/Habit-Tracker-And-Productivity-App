import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SharedPreferencesHelper {
  static const String _keyTimerRunning = 'timer_running';
  static const String _keyTimerRemaining = 'timer_remaining';
  static const String _keySelectedHabit = 'selected_habit';
  static const String _keyUserId = 'userId';
  static const String _keyUserName = 'userName';
  static const String _keyDarkMode = 'darkMode';
  static const String _keyLastCompletedDate = 'lastCompletedDate';
  static const String _keyStreak = 'streak';

  // Singleton instance
  static SharedPreferencesHelper? _instance;
  final SharedPreferences _prefs;

  // Private constructor
  SharedPreferencesHelper._(this._prefs);

  static Future<SharedPreferencesHelper> getInstance() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      _instance = SharedPreferencesHelper._(prefs);
    }
    return _instance!;
  }

  // Timer related methods
  Future<void> saveTimerState(bool isRunning, int remainingTime, String selectedHabit) async {
    await _prefs.setBool('timer_running', isRunning);
    await _prefs.setInt('timer_remaining', remainingTime);
    await _prefs.setString('selected_habit', selectedHabit);
    debugPrint('Saved to prefs: isRunning=$isRunning, remainingTime=$remainingTime, selectedHabit=$selectedHabit');
  }

  bool? getTimerRunning() {
    return _prefs.getBool(_keyTimerRunning);
  }

  int? getTimerRemainingTime() {
    return _prefs.getInt(_keyTimerRemaining);
  }

  String? getSelectedHabit() {
    return _prefs.getString(_keySelectedHabit);
  }

  Future<void> clearTimerState() async {
    await _prefs.remove(_keyTimerRunning);
    await _prefs.remove(_keyTimerRemaining);
    await _prefs.remove(_keySelectedHabit);
  }

  // User related methods
  Future<bool> saveUserId(String userId) async {
    try {
      return await _prefs.setString(_keyUserId, userId) ?? false;
    } catch (e) {
      debugPrint('Error saving user ID: $e');
      return false;
    }
  }

  String? getUserId() {
    try {
      return _prefs.getString(_keyUserId);
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }

  Future<bool> saveUserName(String userName) async {
    try {
      return await _prefs.setString(_keyUserName, userName) ?? false;
    } catch (e) {
      debugPrint('Error saving user name: $e');
      return false;
    }
  }

  String getUserName() {
    try {
      return _prefs.getString(_keyUserName) ?? 'User';
    } catch (e) {
      debugPrint('Error getting user name: $e');
      return 'User';
    }
  }

  // Theme related methods
  Future<bool> setDarkMode(bool isDark) async {
    try {
      return await _prefs.setBool(_keyDarkMode, isDark) ?? false;
    } catch (e) {
      debugPrint('Error setting dark mode: $e');
      return false;
    }
  }

  bool isDarkMode() {
    try {
      return _prefs.getBool(_keyDarkMode) ?? false;
    } catch (e) {
      debugPrint('Error getting dark mode: $e');
      return false;
    }
  }

  // Habit streak related methods
  Future<void> updateStreak(String habitId) async {
    final lastCompletedKey = '${_keyLastCompletedDate}_$habitId';
    final streakKey = '${_keyStreak}_$habitId';

    final lastCompleted = _prefs.getString(lastCompletedKey);
    final currentStreak = _prefs.getInt(streakKey) ?? 0;

    final now = DateTime.now();
    if (lastCompleted != null) {
      final lastDate = DateTime.parse(lastCompleted);
      final difference = now.difference(lastDate).inDays;

      if (difference == 1) {
        // Consecutive day, increment streak
        await _prefs.setInt(streakKey, currentStreak + 1);
      } else if (difference > 1) {
        // Streak broken, reset to 1
        await _prefs.setInt(streakKey, 1);
      }
    } else {
      // First completion, set streak to 1
      await _prefs.setInt(streakKey, 1);
    }

    // Update last completed date
    await _prefs.setString(lastCompletedKey, now.toIso8601String());
  }

  int getStreak(String habitId) {
    return _prefs.getInt('${_keyStreak}_$habitId') ?? 0;
  }
  Future<void> saveStreak(String habitId, int streak) async {
    await _prefs.setInt('streak_$habitId', streak);
  }

  bool isStreakMaintained(String habitId) {
    try {
      final lastCompleted = _prefs.getString('${_keyLastCompletedDate}_$habitId');
      if (lastCompleted == null) return false;

      final now = DateTime.now();
      final difference = now.difference(DateTime.parse(lastCompleted)).inDays;
      return difference <= 1;
    } catch (e) {
      debugPrint('Error checking streak maintenance: $e');
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      await _prefs.clear();
      return true;
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      return false;
    }
  }

  Future<bool> clearHabitData(String habitId) async {
    try {
      await _prefs.remove('${_keyLastCompletedDate}_$habitId');
      await _prefs.remove('${_keyStreak}_$habitId');
      return true;
    } catch (e) {
      debugPrint('Error clearing habit data: $e');
      return false;
    }
  }

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }
}
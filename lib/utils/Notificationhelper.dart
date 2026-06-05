import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:html' as html;

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize notifications for mobile and web
  Future<void> initializeNotifications() async {
    await requestPermissions();

    if (!kIsWeb) {
      tz.initializeTimeZones();
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );
    }

    if (kIsWeb) {
      try {
        debugPrint('Initializing FCM for web.');
        String? token = await _firebaseMessaging.getToken();
        if (token == null) {
          debugPrint('FCM token not available.');
        } else {
          debugPrint('FCM token retrieved: $token');
          setupFCMListeners();
        }
      } catch (e) {
        debugPrint('Error initializing FCM: $e');
        debugPrint('Falling back to html.Notification.');
      }
    }
    debugPrint('✅ Notifications initialized');
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      debugPrint('Requesting notification permissions for web.');
      try {
        final permission = await html.Notification.requestPermission();
        if (permission != 'granted') {
          debugPrint('Web notification permission denied: $permission');
          return false;
        }
        debugPrint('Web notification permission granted.');
        return true;
      } catch (e) {
        debugPrint('Error requesting web notification permission: $e');
        throw Exception('Failed to request web notification permission: $e');
      }
    }
    try {
      if (Platform.isAndroid) {
        if (await Permission.notification.isRestricted) {
          debugPrint('Notifications are restricted on this device.');
          return false;
        }
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          debugPrint('Android notification permission denied.');
          return false;
        }
        return true;
      } else if (Platform.isIOS) {
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        final granted = settings.authorizationStatus == AuthorizationStatus.authorized;
        if (!granted) {
          debugPrint('iOS notification permission denied.');
        }
        return granted;
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      throw Exception('Failed to request notification permission: $e');
    }
  }

  // Check notification permissions
  Future<bool> getNotificationPermission() async {
    if (kIsWeb) {
      final permission = html.Notification.permission;
      debugPrint('Current web notification permission: $permission');
      return permission == 'granted';
    }
    try {
      if (Platform.isAndroid) {
        final granted = await Permission.notification.isGranted;
        debugPrint('Android notification permission: $granted');
        return granted;
      } else if (Platform.isIOS) {
        debugPrint('Assuming iOS permission granted after initialization.');
        return true; // Assume true for iOS after initialization
      }
      return false;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      throw Exception('Failed to check notification permission: $e');
    }
  }

  // Set up FCM listeners
  void setupFCMListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM message received: ${message.messageId}');
      if (message.notification != null) {
        showFCMNotification(
          message.notification!.title ?? 'Notification',
          message.notification!.body ?? 'You have a new message',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM message opened app: ${message.messageId}');
    });

    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from FCM message: ${message.messageId}');
      }
    });
  }

  // Show FCM notification
  Future<void> showFCMNotification(String title, String body) async {
    if (kIsWeb) {
      debugPrint('🔔 Showing web notification via FCM fallback: $title - $body');
      try {
        if (html.Notification.permission == 'granted') {
          html.Notification(title, body: body, icon: '/flutter_logo.png');
          debugPrint('Web notification shown successfully via FCM fallback.');
        } else {
          debugPrint('Web notification permission not granted.');
          throw Exception('Web notification permission not granted.');
        }
      } catch (e) {
        debugPrint('Error showing web notification: $e');
        throw Exception('Failed to show web notification: $e');
      }
      return;
    }
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fcm_channel',
      'FCM Notifications',
      channelDescription: 'Notifications from Firebase Cloud Messaging',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformDetails,
    );
  }

  // Schedule habit reminder
  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required TimeOfDay reminderTime,
    required bool isDaily,
  }) async {
    final bool granted = await getNotificationPermission();
    debugPrint('Permissions granted: $granted');
    if (!granted) {
      debugPrint('Notification permissions not granted.');
      throw Exception('Notification permissions not granted. Please enable notifications in your browser settings.');
    }

    if (kIsWeb) {
      debugPrint('🔔 Scheduling web reminder for $habitName at $reminderTime');
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        reminderTime.hour,
        reminderTime.minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(Duration(days: 1));
      }
      final delay = scheduledDate.difference(now).inMilliseconds;
      debugPrint('Scheduled web notification in $delay ms (at $scheduledDate)');

      // Schedule the actual reminder using html.Notification
      Future.delayed(Duration(milliseconds: delay), () {
        debugPrint('Attempting to show scheduled web notification for $habitName at ${DateTime.now()}');
        if (html.Notification.permission == 'granted') {
          html.Notification('Time for $habitName', body: 'Keep up your streak! 🎯', icon: '/flutter_logo.png');
          debugPrint('Scheduled web notification shown successfully');
        } else {
          debugPrint('Scheduled web notification permission not granted at trigger time.');
          throw Exception('Web notification permission not granted at trigger time.');
        }
      });

      if (isDaily) {
        Future.delayed(Duration(milliseconds: delay + 24 * 60 * 60 * 1000), () {
          debugPrint('Rescheduling daily web reminder for $habitName');
          scheduleHabitReminder(
            habitId: habitId,
            habitName: habitName,
            reminderTime: reminderTime,
            isDaily: true,
          );
        });
      }

      // Attempt to schedule via FCM if available
      try {
        String? fcmToken = await _firebaseMessaging.getToken();
        if (fcmToken != null) {
          debugPrint('FCM token available: $fcmToken. Scheduling reminder via FCM is not implemented (requires backend).');
          // Note: Scheduling via FCM requires a backend (e.g., Cloud Function), which you previously declined.
        } else {
          debugPrint('FCM token not available. Falling back to html.Notification.');
        }
      } catch (e) {
        debugPrint('Error getting FCM token: $e. Continuing with html.Notification.');
      }
      debugPrint('Note: Web reminders require the browser tab to stay open unless FCM is fully configured with a backend.');
      return;
    }

    // Mobile logic
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(
      hours: reminderTime.hour - tz.TZDateTime.now(tz.local).hour,
      minutes: reminderTime.minute - tz.TZDateTime.now(tz.local).minute,
    ));
    final adjustedDate = scheduledDate.isBefore(tz.TZDateTime.now(tz.local))
        ? scheduledDate.add(Duration(days: 1))
        : scheduledDate;
    debugPrint('Scheduled mobile notification for $habitName at $adjustedDate');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'habit_channel',
      'Habit Reminders',
      channelDescription: 'Reminders for your habits',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      habitId.hashCode,
      'Time for $habitName',
      'Keep up your streak! 🎯',
      adjustedDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: isDaily ? DateTimeComponents.time : null,
    );
    debugPrint('Scheduled reminder for $habitName at $reminderTime');
  }

  // Cancel habit notifications
  Future<void> cancelHabitNotifications(String habitId) async {
    if (!kIsWeb) {
      await flutterLocalNotificationsPlugin.cancel(habitId.hashCode);
      debugPrint('Cancelled notifications for habit ID: $habitId');
    }
    // Web doesn't support canceling scheduled Future.delayed calls natively
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!kIsWeb) {
      await flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('Cancelled all notifications');
    }
    // Web doesn't support canceling all scheduled notifications natively
  }

  // Schedule completion celebration
  Future<void> scheduleCompletionCelebration({
    required String habitName,
    required int streak,
    required BuildContext context,
  }) async {
    if (kIsWeb) {
      debugPrint('🔔 Showing web completion celebration for $habitName');
      try {
        if (html.Notification.permission == 'granted') {
          html.Notification('Great Job!', body: 'You completed $habitName! Streak: $streak 🔥', icon: '/flutter_logo.png');
          debugPrint('Web completion celebration shown successfully.');
        } else {
          debugPrint('Web notification permission not granted for completion celebration.');
          throw Exception('Web notification permission not granted.');
        }
      } catch (e) {
        debugPrint('Error showing web completion celebration: $e');
        throw Exception('Failed to show web completion celebration: $e');
      }
      return;
    }
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'celebration_channel',
      'Habit Completion Celebrations',
      channelDescription: 'Celebrate your habit completions',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      habitName.hashCode,
      'Great Job!',
      'You completed $habitName! Streak: $streak 🔥',
      platformDetails,
    );
  }
}
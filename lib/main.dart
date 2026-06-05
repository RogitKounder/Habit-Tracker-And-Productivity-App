import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:habit_speed_code/utils/NotificationHelper.dart';
import 'firebase_options.dart'; // Ensure this file is generated
import 'pages/loginPage.dart';
import 'pages/registerPage.dart';
import 'pages/homePage.dart';
import 'pages/progressPage.dart';
import 'pages/habitsPage.dart';
import 'pages/profilePage.dart';
import 'pages/accountinfoPage.dart';
import 'pages/forgotPasswordPage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Initialize Firebase Messaging (FCM)
    if (!kIsWeb) {
      // For mobile platforms (Android/iOS)
      await NotificationHelper().initializeNotifications();
      debugPrint('Notifications initialized successfully');
    } else {
      // For web platform
      debugPrint('Initializing FCM for web.');
      final messaging = FirebaseMessaging.instance;

      // Replace with your VAPID key from Firebase Console
      const vapidKey = 'BOUw4lCim2mG7VQ-rvOwtM-j-TAQCImO0Bcy2BZeS4jOIDRA2lwaWmqKM1Y40L8IEDMt_Q-DfIxhR0aaxCAIY9I';

      // Request permission for notifications
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for notifications.');

        // Get the FCM token
        final token = await messaging.getToken(vapidKey: vapidKey);
        debugPrint('FCM Token for web: $token');

        // Listen for incoming messages while the app is in the foreground
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Message received: ${message.notification?.title}');
          // Handle the message (e.g., show a notification or update the UI)
        });
      } else {
        debugPrint('User declined or has not granted permission for notifications.');
      }
    }
  } catch (e) {
    debugPrint('Error during initialization: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROGIT 09',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const NavigationScreen(),
        '/forgot-password': (context) => ForgotPasswordPage(),
        '/my-account': (context) => AccountInfoPage(),
      },
    );
  }
}

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({Key? key}) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ProgressPage(),
    const HabitsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.deepPurpleAccent,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Calendar"),
          BottomNavigationBarItem(icon: Icon(Icons.timeline), label: "Progress"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
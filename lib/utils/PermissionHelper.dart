import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class PermissionHelper {
  static Future<bool> requestNotificationPermissions() async {
    if (kIsWeb) {
      print('Notification permissions not supported on web.');
      return false;
    }
    try {
      if (Platform.isAndroid) {
        if (await Permission.notification.isRestricted) {
          print('Notifications are restricted on this device.');
          return false;
        }
        final status = await Permission.notification.request();
        return status.isGranted;
      } else if (Platform.isIOS) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
      return false;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  static Future<bool> checkNotificationPermissions() async {
    if (kIsWeb) {
      print('Notification permissions not applicable on web.');
      return false;
    }
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.notification.status;
        return status.isGranted;
      }
      return false;
    } catch (e) {
      print('Error checking notification permission: $e');
      return false;
    }
  }
}
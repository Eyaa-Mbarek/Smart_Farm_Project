// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _notificationService = NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification Channel details (Android 8+)
  static const String channelId = 'local_threshold_alerts';
  static const String channelName = 'Threshold Alerts (Local)';
  static const String channelDescription = 'Notifications for sensor threshold alerts triggered locally by the app.';

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_notification'); // Or your custom icon

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            // onDidReceiveLocalNotification: onDidReceiveLocalNotification, // Only for older iOS foreground
        );

    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

    // Create Android Channel
    await _createAndroidChannel();

    // Request permissions on Android 13+ (can also be done elsewhere)
    await _requestAndroidPermissions();

    print("NotificationService Initialized");
  }

  Future<void> _createAndroidChannel() async {
     const AndroidNotificationChannel channel = AndroidNotificationChannel(
       channelId,
       channelName,
       description: channelDescription,
       importance: Importance.max, // High importance
       playSound: true,
     );
     await flutterLocalNotificationsPlugin
         .resolvePlatformSpecificImplementation<
             AndroidFlutterLocalNotificationsPlugin>()
         ?.createNotificationChannel(channel);
     print("Android Notification Channel Created: $channelId");
  }

   Future<void> _requestAndroidPermissions() async {
     // Request permission for Android 13+
     final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
       flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
          final bool? granted = await androidImplementation.requestNotificationsPermission();
           print("Android Notification Permission Granted: $granted");
      }
   }


  // Callback when notification is tapped
  static void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
      final String? payload = notificationResponse.payload;
      debugPrint('Local Notification Tapped - Payload: $payload');
      // Handle navigation or actions based on payload (e.g., blockId)
      // Example: navigatorKey.currentState?.pushNamed('/details', arguments: payload);
  }

  // Method to show a notification
  Future<void> showThresholdNotification({
      required String blockId,
      required String blockName,
      required double value,
      required double threshold,
      required String unit,
   }) async {
      // Unique ID for the notification (can use blockId hash or an incrementing int)
      final int notificationId = blockId.hashCode;

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        'Climate Alert: $blockName', // Title
        'Value ${value.toStringAsFixed(1)}$unit exceeds threshold ${threshold.toStringAsFixed(1)}$unit!', // Body
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId, // Use the defined channel ID
            channelName,
            channelDescription: channelDescription,
            importance: Importance.max, // Match channel importance
            priority: Priority.high,   // Match channel priority
            icon: '@drawable/ic_stat_notification', // Ensure this exists
          ),
          iOS: DarwinNotificationDetails( // Use const
            presentAlert: true, presentBadge: true, presentSound: true,
            sound: 'default',
          ),
        ),
        payload: blockId, // Pass blockId as payload
      );
       print("Showing local notification for $blockId");
   }
}
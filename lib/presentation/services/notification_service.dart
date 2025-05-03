import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern: Ensures only one instance of the service exists
  static final NotificationService _notificationService = NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }
  NotificationService._internal();

  // Instance of the plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification Channel details (Required for Android 8.0+)
  static const String channelId = 'local_threshold_alerts';
  static const String channelName = 'Threshold Alerts';
  static const String channelDescription = 'Notifications for sensor threshold alerts triggered locally.';

  // Initialization method
  Future<void> init() async {
    // Android initialization settings
    // Ensure ''@drawable/ic_stat_notification' exists in android/app/src/main/res/mipmap-* folders
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_notification');

    // iOS initialization settings
    // Requesting permissions here is fine, but can also be done separately
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            // onDidReceiveLocalNotification: onDidReceiveLocalNotification, // Callback for older iOS foreground notifications
        );

    // Combined initialization settings
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS);

    // Initialize the plugin with the settings and the callback for when a notification is tapped
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

    // Create the Android Notification Channel (important!)
    await _createAndroidChannel();

    // Request Android 13+ notification permission (if needed)
    // This might be better handled elsewhere depending on UX flow
    await _requestAndroidPermissions();

    print("NotificationService Initialized and Channel Created");
  }

  // Helper to create the Android Notification Channel
  Future<void> _createAndroidChannel() async {
     const AndroidNotificationChannel channel = AndroidNotificationChannel(
       channelId,
       channelName,
       description: channelDescription,
       importance: Importance.max, // Set importance (Max shows heads-up)
       playSound: true,            // Enable sound
       // sound: RawResourceAndroidNotificationSound('custom_sound'), // Optional custom sound
     );
     // Register the channel with the system
      try {
             await flutterLocalNotificationsPlugin
                 .resolvePlatformSpecificImplementation<
                     AndroidFlutterLocalNotificationsPlugin>()
                 ?.createNotificationChannel(channel);
             print("Android Notification Channel '$channelId' Created/Updated.");
         } catch (e) {
            print("Error creating/updating Android Notification Channel '$channelId': $e");
         }
  }

   // Helper to request Android 13+ specific notification permission
   Future<void> _requestAndroidPermissions() async {
     final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
       flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
          // Request permission - returns true/false or null if not applicable
          final bool? granted = await androidImplementation.requestNotificationsPermission();
           print("Android Notification Permission Request Result: $granted");
      }
   }


  // --- Callback Handlers ---

  // Static callback for when a notification response is received (user taps notification)
  // Needs to be static or top-level if used potentially from background isolates (though not strictly needed here)
  @pragma('vm:entry-point') // Recommended for potential background use
  static void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
      final String? payload = notificationResponse.payload;
      debugPrint('Notification Tapped - Payload: $payload');
      // Handle navigation or other actions based on payload
      // This is where you'd use a navigator key or other method if you want
      // the app to navigate somewhere specific when a notification is tapped.
      // Example:
      // if (payload != null && payload.startsWith("device:")) {
      //    String deviceId = payload.substring(7);
      //    navigatorKey.currentState?.pushNamed('/device_detail', arguments: deviceId);
      // }
  }

   // Optional: Callback for handling foreground notifications on older iOS versions (iOS 9 and below)
   /*
   @pragma('vm:entry-point')
   static void onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
     // display a dialog with the notification details, Actions etc.
     debugPrint('Older iOS Foreground Notification Received - Payload: $payload');
     // You might show an in-app banner or dialog here for older iOS versions.
   }
   */

  // --- Method to show a notification ---
  Future<void> showThresholdNotification({
      required String blockId, // Used as part of the unique ID and payload
      required String blockName, // Used in title/body
      required double value,
      required double threshold,
      required String unit,
      String? deviceId, // Optional: Include device context
   }) async {
      // Generate a unique ID for the notification. Using hashCodes is common.
      // Combining deviceId and blockId makes it more unique across devices.
      final int notificationId = (deviceId ?? "" + blockId).hashCode;

      // Define Android specific details
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            channelId, // Use the channel ID created during init
            channelName,
            channelDescription: channelDescription,
            importance: Importance.max, // Match channel importance
            icon: '@drawable/ic_stat_notification', // Standard Android icon resource name
            // Other options:
            // largeIcon: DrawableResourceAndroidBitmap('ic_large_icon'),
            // styleInformation: BigTextStyleInformation('Longer text...'),
            // ongoing: false, // Make it dismissible
            // autoCancel: true, // Dismiss when tapped
          );

      // Define iOS specific details
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true, // Show alert banner
            presentBadge: true, // Update app badge count (requires permission)
            presentSound: true, // Play sound (requires permission)
            sound: 'default', // Use default iOS sound
            // badgeNumber: 1, // Optional: Set specific badge number
          );

      // Combine platform specifics
      final NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics);

       // Construct payload (data to pass when notification is tapped)
       // Could be JSON string or simple ID
       final String payloadData = deviceId != null ? "$deviceId/$blockId" : blockId;


      // Show the notification
      try {
         await flutterLocalNotificationsPlugin.show(
           notificationId,
           blockName, // Notification title (already includes device context if needed)
           'Value ${value.toStringAsFixed(1)}$unit exceeds threshold ${threshold.toStringAsFixed(1)}$unit!', // Notification body
           platformChannelSpecifics,
           payload: payloadData, // Pass data
         );
          print("NotificationService: Showing local notification ID $notificationId for $blockId on $deviceId");
      } catch(e) {
         print("NotificationService: Error showing notification - $e");
      }
   }

   // Optional: Method to cancel a specific notification
   Future<void> cancelNotification(int id) async {
      await flutterLocalNotificationsPlugin.cancel(id);
   }

   // Optional: Method to cancel all notifications
   Future<void> cancelAllNotifications() async {
      await flutterLocalNotificationsPlugin.cancelAll();
   }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Keep for local display
import 'firebase_options.dart';
import 'presentation/screens/wrapper.dart'; // Import Wrapper
import 'presentation/services/notification_service.dart'; // Import the notification service

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Local Notifications Service
  await NotificationService().init();

  // Run the app wrapped in ProviderScope
  runApp(
     const ProviderScope(
        child: MyApp()
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Climate Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Start with the Wrapper to handle auth state and routing
      home: const Wrapper(),
    );
  }
}
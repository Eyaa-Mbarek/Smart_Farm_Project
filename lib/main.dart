import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart'; // REMOVED
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'presentation/providers/monitored_blocks_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/services/notification_service.dart'; // Import the new service

// Global navigator key (optional, if needed for navigation from tap)
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Local Notifications Service
  await NotificationService().init(); // Use the service

  // --- REMOVED ALL FCM Specific Setup (requestPermission, handlers, token logic) ---

  runApp(
     ProviderScope(
        overrides: [
          monitoredBlockIdsProvider.overrideWith(
             (ref) => MonitoredBlockIdsNotifier()..loadMonitoredBlocks(),
          ),
        ],
        child: const MyApp()
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // navigatorKey: navigatorKey, // Optional
      title: 'Farm Climate Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
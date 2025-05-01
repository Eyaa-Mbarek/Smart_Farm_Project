import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
// import 'presentation/providers/monitored_blocks_provider.dart'; // Monitored blocks now loaded via user profile
import 'presentation/screens/wrapper.dart'; // Import Wrapper
import 'presentation/services/notification_service.dart';

// --- REMOVED GLOBAL NAV KEY (handle navigation differently if needed) ---

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Local Notifications Service
  await NotificationService().init();

  // --- REMOVED FCM Specific Setup ---

  runApp(
     const ProviderScope( // Keep ProviderScope at the root
        // REMOVED override for monitoredBlockIdsProvider, let it load based on user state
        child: MyApp()
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // REMOVED navigatorKey
      title: 'Climate Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Start with the Wrapper to handle auth state
      home: const Wrapper(),
    );
  }
}


 


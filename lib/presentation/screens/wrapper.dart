import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/presentation/providers/auth_providers.dart';
import 'package:smart_farm_test/presentation/screens/auth/login_screen.dart'; // Create this
import 'package:smart_farm_test/presentation/screens/main_screen.dart'; // Create this (holds bottom nav)

class Wrapper extends ConsumerWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    print("Wrapper Build: Auth State Received -> $authState"); // <-- ADD THIS

    return authState.when(
      data: (user) {
         print("Wrapper Data: User -> ${user?.uid ?? 'null'}"); // <-- ADD THIS
        if (user != null) {
          // User is logged in, show the main app screen
          print("Wrapper: Navigating to MainScreen"); // <-- ADD THIS
          return const MainScreen();
        } else {
          // User is logged out, show the login screen
           print("Wrapper: Navigating to LoginScreen"); // <-- ADD THIS
          return const LoginScreen(); // Or an AuthToggle screen
        }
      },
      loading: () {
         print("Wrapper: Loading Auth State..."); // <-- ADD THIS
        // Show a loading indicator while checking auth state
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, stackTrace) {
         print("Wrapper: Auth Error State -> $error"); // <-- ADD THIS
         // Handle error state (e.g., show an error message)
         return Scaffold(
           body: Center(child: Text('Authentication error: $error')),
         );
      },
    );
  }
}
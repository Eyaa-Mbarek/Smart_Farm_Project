import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/presentation/providers/auth_providers.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/screens/auth/login_screen.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/screens/main_screen.dart'; // Adjust import path

class Wrapper extends ConsumerWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the authentication state
    final authState = ref.watch(authStateProvider);

    // Use .when to handle loading, error, and data states
    return authState.when(
      data: (user) {
        // If user data exists (logged in)
        if (user != null) {
          print("Wrapper: User logged in (${user.uid})");
          // Show the main application screen with bottom navigation
          return const MainScreen();
        }
        // If user data is null (logged out)
        else {
          print("Wrapper: User logged out");
          // Show the login screen
          return const LoginScreen();
        }
      },
      loading: () {
        // Show a loading indicator while the auth state is being determined
        print("Wrapper: Checking auth state...");
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, stackTrace) {
         // Handle potential errors during auth state checking
          print("Wrapper: Auth Error - $error\n$stackTrace");
         return Scaffold(
           body: Center(child: Text('Authentication error: $error')),
         );
      },
    );
  }
}
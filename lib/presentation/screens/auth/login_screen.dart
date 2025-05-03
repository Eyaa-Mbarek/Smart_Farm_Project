import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for exception handling
import 'package:smart_farm_test/presentation/providers/auth_providers.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/screens/auth/signup_screen.dart'; // Adjust import path

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    // Validate form inputs
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Don't proceed if validation fails
    }

    // Set loading state and clear previous errors
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Read the auth repository from Riverpod
      final authRepository = ref.read(authRepositoryProvider);
      // Attempt to sign in
      await authRepository.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // IMPORTANT: No navigation needed here.
      // The Wrapper widget listens to authStateProvider and will automatically
      // navigate to MainScreen when the user state changes to logged in.
      if (mounted) {
        print("Login successful, Wrapper should navigate.");
      }

    } on FirebaseAuthException catch (e) {
       // Handle specific Firebase authentication errors
       if (mounted) {
          setState(() {
            // Provide user-friendly messages based on error codes
            if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
                 _errorMessage = 'Incorrect email or password.';
             } else {
                 _errorMessage = e.message ?? 'Login failed. Please try again.';
             }
          });
       }
       print("Login Error (FirebaseAuth): ${e.code} - ${e.message}");

    } catch (e) {
      // Handle other unexpected errors
       if (mounted) {
          setState(() {
            _errorMessage = 'An unexpected error occurred during login.';
          });
       }
       print("Login Error (General): $e");

    } finally {
       // Ensure loading state is turned off, even if widget is removed
       if (mounted) {
         setState(() { _isLoading = false; });
       }
    }
  }

   @override
   void dispose() {
     _emailController.dispose();
     _passwordController.dispose();
     super.dispose();
   }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title: const Text('Login'),
         automaticallyImplyLeading: false, // No back button needed here
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons stretch
              children: [
                Text('Climate Monitor', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary), textAlign: TextAlign.center),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                     if (value == null || value.trim().isEmpty) return 'Please enter your email';
                     if (!value.contains('@') || !value.contains('.')) return 'Enter a valid email address';
                     return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter your password' : null,
                   textInputAction: TextInputAction.done,
                   onFieldSubmitted: (_) => _isLoading ? null : _signIn(), // Allow login on keyboard done action
                ),
                const SizedBox(height: 24),
                // Display error message if it exists
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Show loading indicator or login button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('Login'),
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: 12),
                           textStyle: const TextStyle(fontSize: 16)
                        ),
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _isLoading ? null : () {
                    // Navigate to Signup Screen
                    Navigator.of(context).push( // Use push, not pushReplacement, so user can go back if needed
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );
                  },
                  child: const Text('Don\'t have an account? Sign Up'),
                ),
                 // Optional: Add Password Reset Button later
                 /*
                 TextButton(
                    onPressed: _isLoading ? null : () { /* Navigate to Password Reset Screen */ },
                    child: const Text('Forgot Password?'),
                 ),
                 */
              ],
            ),
          ),
        ),
      ),
    );
  }
}
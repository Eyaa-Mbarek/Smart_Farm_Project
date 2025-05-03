import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_farm_test/presentation/providers/auth_providers.dart'; // Adjust import path
// No explicit navigation back needed, Wrapper handles state change

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController(); // Optional username
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signUp() async {
     // Validate form inputs
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Don't proceed if validation fails
    }

    // No need to re-check password match here, validator does it

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      // Attempt sign up, passing optional username
      await authRepository.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
         username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
      );
       // IMPORTANT: No navigation needed here.
       // The Wrapper widget listens to authStateProvider and will automatically
       // navigate to MainScreen when the user state changes to logged in after signup.
       if (mounted) {
         print("Signup successful, Wrapper should navigate.");
         // Optionally show a success message before Wrapper navigates
         // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account created successfully!')));
       }

    } on FirebaseAuthException catch (e) {
       if (mounted) {
          setState(() {
             // Provide user-friendly messages
             if (e.code == 'weak-password') {
                _errorMessage = 'The password provided is too weak.';
             } else if (e.code == 'email-already-in-use') {
                 _errorMessage = 'An account already exists for that email.';
             } else {
                 _errorMessage = e.message ?? 'Signup failed. Please try again.';
             }
          });
       }
        print("Signup Error (FirebaseAuth): ${e.code} - ${e.message}");

    } catch (e) {
       if (mounted) {
          setState(() {
            _errorMessage = 'An unexpected error occurred during signup.';
          });
       }
        print("Signup Error (General): $e");

    } finally {
        if (mounted) {
           setState(() { _isLoading = false; });
        }
    }
  }

   @override
   void dispose() {
     _emailController.dispose();
     _passwordController.dispose();
     _confirmPasswordController.dispose();
     _usernameController.dispose();
     super.dispose();
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')), // Keep back button by default
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
               crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create Account', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary), textAlign: TextAlign.center),
                const SizedBox(height: 30),
                 TextFormField( // Optional Username
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                   textInputAction: TextInputAction.next,
                  // No strict validation needed for optional field
                ),
                const SizedBox(height: 16),
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
                  validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                   textInputAction: TextInputAction.next,
                ),
                 const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_reset_outlined)),
                  obscureText: true,
                  validator: (value) {
                     if (value == null || value.isEmpty) return 'Please confirm your password';
                     if (value != _passwordController.text) return 'Passwords do not match';
                     return null;
                  },
                   textInputAction: TextInputAction.done,
                   onFieldSubmitted: (_) => _isLoading ? null : _signUp(),
                ),
                const SizedBox(height: 24),
                 // Display error message
                 if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                    ),
                  ),
                 // Show loading indicator or signup button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                         icon: const Icon(Icons.person_add_alt_1),
                         label: const Text('Sign Up'),
                        onPressed: _signUp,
                         style: ElevatedButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: 12),
                           textStyle: const TextStyle(fontSize: 16)
                        ),
                      ),
                 const SizedBox(height: 20),
                 // Link back to Login Screen
                TextButton(
                  onPressed: _isLoading ? null : () {
                    // Simply pop the current screen to go back to Login
                    if (Navigator.canPop(context)) {
                       Navigator.pop(context);
                    }
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
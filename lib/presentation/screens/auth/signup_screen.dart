import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_farm_test/presentation/providers/auth_providers.dart';
import 'package:smart_farm_test/presentation/screens/auth/login_screen.dart'; // Navigate back to login

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
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() { _errorMessage = 'Passwords do not match.'; });
        return;
      }
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final authRepository = ref.read(authRepositoryProvider);
        await authRepository.signUpWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
           username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(), // Pass username
        );
         // Navigation handled by Wrapper
      } on FirebaseAuthException catch (e) {
         setState(() { _errorMessage = e.message ?? 'Signup failed.'; });
          print("Signup Error: ${e.code} - ${e.message}");
      } catch (e) {
         setState(() { _errorMessage = 'An unexpected error occurred.'; });
          print("Signup Error (General): $e");
      } finally {
          if (mounted) {
             setState(() { _isLoading = false; });
          }
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
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Create Account', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 30),
                 TextFormField( // Optional Username
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username (Optional)', border: OutlineInputBorder()),
                  validator: (value) => null, // No strict validation for optional
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6) ? 'Min. 6 characters' : null,
                ),
                 const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) => (value == null || value != _passwordController.text) ? 'Passwords must match' : null,
                ),
                const SizedBox(height: 20),
                 if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                        child: const Text('Sign Up'),
                      ),
                 const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                     Navigator.of(context).pushReplacement( // Replace Signup with Login
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
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
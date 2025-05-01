import 'package:firebase_auth/firebase_auth.dart';

abstract class IAuthRepository {
  // Stream to listen for authentication state changes
  Stream<User?> get authStateChanges;

  // Get the current user (if logged in)
  User? get currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password);

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailPassword(String email, String password, {String? username});

  // Sign out
  Future<void> signOut();

  // Send password reset email (optional)
  // Future<void> sendPasswordResetEmail(String email);
}
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // Handle specific errors (e.g., 'user-not-found', 'wrong-password')
      print("FirebaseAuthDataSource Error (SignIn): ${e.code} - ${e.message}");
      rethrow; // Rethrow to be handled by the repository/UI
    }
  }

  Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
     try {
       return await _auth.createUserWithEmailAndPassword(email: email, password: password);
     } on FirebaseAuthException catch (e) {
      // Handle specific errors (e.g., 'weak-password', 'email-already-in-use')
      print("FirebaseAuthDataSource Error (SignUp): ${e.code} - ${e.message}");
      rethrow;
     }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
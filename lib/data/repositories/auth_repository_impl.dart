import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_farm_test/data/datasources/firebase_auth_datasource.dart'; // Adjust import path
import 'package:smart_farm_test/data/datasources/firestore_datasource.dart'; // Adjust import path
import 'package:smart_farm_test/domain/repositories/auth_repository.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/user_profile.dart'; // Adjust import path

class FirebaseAuthRepositoryImpl implements IAuthRepository {
  final FirebaseAuthDataSource _authDataSource;
  final FirestoreDataSource _firestoreDataSource; // Inject FirestoreDataSource

   FirebaseAuthRepositoryImpl(this._authDataSource, this._firestoreDataSource);


  @override
  Stream<User?> get authStateChanges => _authDataSource.authStateChanges;

  @override
  User? get currentUser => _authDataSource.currentUser;

  @override
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    return await _authDataSource.signInWithEmailPassword(email, password);
  }

  @override
  Future<UserCredential> signUpWithEmailPassword(String email, String password, {String? username}) async {
     // 1. Create user in Firebase Auth
    UserCredential userCredential = await _authDataSource.signUpWithEmailPassword(email, password);
    User? user = userCredential.user;

     // 2. Create corresponding user profile in Firestore
    if (user != null && user.email != null) { // Ensure email is not null
       // Use the static helper from UserProfile to create initial data map
       final initialProfileData = UserProfile.initialData(user.email!, username: username);
       try {
          // Use setUserProfile which handles merge and timestamp
          await _firestoreDataSource.setUserProfile(user.uid, initialProfileData);
           print("Firestore profile created successfully for ${user.uid}");
       } catch (e) {
          // Handle profile creation error (e.g., log it, maybe delete the auth user?)
          print("Error creating Firestore profile during signup for ${user.uid}: $e");
          // Consider deleting the newly created auth user if profile creation fails critical setup
          // await user.delete().catchError((deleteError) => print("Failed to delete auth user after profile error: $deleteError"));
          // throw Exception("Failed to create user profile.");
          rethrow; // Rethrow the original error for now
       }
    } else {
        // This case should ideally not happen if signup succeeded, but handle defensively
        if (user == null) throw Exception("Firebase Auth user was null after signup.");
        if (user.email == null) throw Exception("Firebase Auth user email was null after signup.");
    }
    return userCredential;
  }

  @override
  Future<void> signOut() async {
    await _authDataSource.signOut();
  }
}
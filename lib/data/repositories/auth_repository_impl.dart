import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_farm_test/data/datasources/firebase_auth_datasource.dart';
import 'package:smart_farm_test/data/datasources/firestore_datasource.dart'; // Needed to create profile
import 'package:smart_farm_test/domain/repositories/auth_repository.dart';

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
    if (user != null) {
       final initialProfileData = {
          'email': user.email,
          'username': username ?? user.email?.split('@')[0], // Default username from email part
          'monitoredBlocks': ['bloc1', 'bloc2'], // Default monitored blocks
          // 'createdAt' will be added by FirestoreDataSource
       };
       try {
          await _firestoreDataSource.setUserProfile(user.uid, initialProfileData);
       } catch (e) {
          // Handle profile creation error (e.g., log it, maybe delete the auth user?)
          print("Error creating Firestore profile during signup: $e");
          // Consider deleting the newly created auth user if profile creation fails
          // await user.delete();
          // throw Exception("Failed to create user profile.");
          rethrow; // Rethrow the original error for now
       }
    } else {
        throw Exception("Firebase Auth user was null after signup.");
    }
    return userCredential;
  }

  @override
  Future<void> signOut() async {
    await _authDataSource.signOut();
  }
}
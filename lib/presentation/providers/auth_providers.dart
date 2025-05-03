import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/data/datasources/firebase_auth_datasource.dart'; // Adjust import path
import 'package:smart_farm_test/data/datasources/firestore_datasource.dart'; // Adjust import path
import 'package:smart_farm_test/data/repositories/auth_repository_impl.dart'; // Adjust import path
import 'package:smart_farm_test/domain/repositories/auth_repository.dart'; // Adjust import path

// --- Data Source Providers ---
final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource();
});

// Provider for FirestoreDataSource (used by AuthRepo for signup profile creation)
// Assuming this is the primary definition for FirestoreDataSource
final firestoreDataSourceProvider = Provider<FirestoreDataSource>((ref) {
  return FirestoreDataSource();
});


// --- Repository Provider ---
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final authDataSource = ref.watch(firebaseAuthDataSourceProvider);
   // Auth repo needs Firestore access to create user profiles on signup
   final firestoreDataSource = ref.watch(firestoreDataSourceProvider);
  return FirebaseAuthRepositoryImpl(authDataSource, firestoreDataSource);
});

// --- Stream Provider for Auth State ---
// This is the primary way the UI knows if the user is logged in or out
final authStateProvider = StreamProvider.autoDispose<User?>((ref) {
   print("authStateProvider executing");
   // Keep the subscription alive even if the UI stops listening temporarily
   // ref.keepAlive(); // Consider if needed based on app lifecycle
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});
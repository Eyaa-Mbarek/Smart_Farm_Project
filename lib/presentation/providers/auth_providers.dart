import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/data/datasources/firebase_auth_datasource.dart';
import 'package:smart_farm_test/data/datasources/firestore_datasource.dart'; // Needed for signup
import 'package:smart_farm_test/data/repositories/auth_repository_impl.dart';
import 'package:smart_farm_test/domain/repositories/auth_repository.dart';

// --- Data Source Providers ---
final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource();
});

// Assume FirestoreDataSource provider exists elsewhere or define it here
final firestoreDataSourceProvider = Provider<FirestoreDataSource>((ref) {
  return FirestoreDataSource();
});


// --- Repository Provider ---
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final authDataSource = ref.watch(firebaseAuthDataSourceProvider);
   final firestoreDataSource = ref.watch(firestoreDataSourceProvider); // Get Firestore DS
  return FirebaseAuthRepositoryImpl(authDataSource, firestoreDataSource); // Pass it here
});

// --- Stream Provider for Auth State ---
// This is the primary way the UI knows if the user is logged in or out
final authStateProvider = StreamProvider.autoDispose<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});
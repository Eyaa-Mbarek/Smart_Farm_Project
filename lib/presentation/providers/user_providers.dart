import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/data/repositories/user_repository_impl.dart';
import 'package:smart_farm_test/domain/entities/user_profile.dart';
import 'package:smart_farm_test/domain/repositories/user_repository.dart';
import 'package:smart_farm_test/presentation/providers/auth_providers.dart'; // Need auth state

// Repository Provider
final userRepositoryProvider = Provider<IUserRepository>((ref) {
  final firestoreDataSource = ref.watch(firestoreDataSourceProvider);
  return UserRepositoryImpl(firestoreDataSource);
});

// Provider to watch the current user's profile
// It depends on the auth state to get the UID
final userProfileProvider = StreamProvider.autoDispose<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value; // Get the Firebase User object

  if (user != null) {
     print("userProfileProvider: Watching profile for UID ${user.uid}");
     final userRepository = ref.watch(userRepositoryProvider);
     try {
         // Return the stream from the repository
         return userRepository.watchUserProfile(user.uid);
     } catch (e) {
        print("userProfileProvider: Error watching profile - $e");
        // Return a stream emitting the error
         return Stream.error(e);
     }
  } else {
     print("userProfileProvider: No user logged in, returning null stream.");
     // No user logged in, return a stream with null
     return Stream.value(null);
  }
});
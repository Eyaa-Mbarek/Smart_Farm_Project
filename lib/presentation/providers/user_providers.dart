import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/data/datasources/firestore_datasource.dart'; // Assuming exists via auth_providers
import 'package:smart_farm_test/data/repositories/user_repository_impl.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/user_profile.dart'; // Adjust import path
import 'package:smart_farm_test/domain/repositories/user_repository.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/auth_providers.dart'; // Need auth state

// --- FirestoreDataSource Provider (defined in auth_providers) ---
// Re-export or ensure it's accessible if needed directly, but usually accessed via repo.
// final firestoreDataSourceProvider = Provider<FirestoreDataSource>(...);

// --- User Repository Provider ---
final userRepositoryProvider = Provider<IUserRepository>((ref) {
  // Depends on FirestoreDataSource provider (defined in auth_providers.dart)
  final firestoreDataSource = ref.watch(firestoreDataSourceProvider);
  return UserRepositoryImpl(firestoreDataSource);
});

// --- Provider to watch the current user's profile ---
// It depends on the auth state to get the UID
final userProfileProvider = StreamProvider.autoDispose<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull; // Use valueOrNull to handle initial loading state

  if (user != null) {
     print("userProfileProvider: Watching profile for UID ${user.uid}");
     final userRepository = ref.watch(userRepositoryProvider);
     try {
         // Return the stream from the repository
         return userRepository.watchUserProfile(user.uid);
     } catch (e, stackTrace) {
        print("userProfileProvider: Error watching profile - $e\n$stackTrace");
        // Return a stream emitting the error
         return Stream.error(e, stackTrace);
     }
  } else {
     print("userProfileProvider: No user logged in, returning null stream.");
     // No user logged in, return a stream with null value
     return Stream.value(null);
  }
});


// --- Action Providers for managing user profile data ---

// Provider to update the username
final updateUsernameProvider = Provider((ref) {
   final repo = ref.watch(userRepositoryProvider);
   final user = ref.watch(authStateProvider).value;
   return (String newUsername) async {
      if (user != null && newUsername.isNotEmpty) {
         await repo.updateUserProfile(user.uid, {'username': newUsername});
      }
   };
});


// Action Providers for managing monitored devices list
final addUserMonitoredDeviceProvider = Provider((ref) {
    final repo = ref.watch(userRepositoryProvider);
    final user = ref.watch(authStateProvider).value;
    return (String deviceId) async {
       if (user != null) {
          print("Adding device $deviceId to monitored list for ${user.uid}");
          await repo.addDeviceToMonitored(user.uid, deviceId);
       }
    };
});

final removeUserMonitoredDeviceProvider = Provider((ref) {
     final repo = ref.watch(userRepositoryProvider);
     final user = ref.watch(authStateProvider).value;
     return (String deviceId) async {
       if (user != null) {
          print("Removing device $deviceId from monitored list for ${user.uid}");
          await repo.removeDeviceFromMonitored(user.uid, deviceId);
        }
    };
});


// --- Action providers for FCM token management (if needed) ---
final addUserFcmTokenProvider = Provider((ref) {
   final repo = ref.watch(userRepositoryProvider);
   final user = ref.watch(authStateProvider).value;
    return (String token) async {
      if (user != null && token.isNotEmpty) {
         await repo.addFcmToken(user.uid, token);
         print("Added FCM token for user ${user.uid}");
      }
   };
});

final removeUserFcmTokenProvider = Provider((ref) {
    final repo = ref.watch(userRepositoryProvider);
    final user = ref.watch(authStateProvider).value;
    return (String token) async {
      if (user != null && token.isNotEmpty) {
         await repo.removeFcmToken(user.uid, token);
          print("Removed FCM token for user ${user.uid}");
      }
   };
});
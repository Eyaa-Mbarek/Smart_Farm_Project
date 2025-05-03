import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/data/datasources/firestore_datasource.dart'; // Assuming exists via auth_providers
import 'package:smart_farm_test/data/repositories/notification_repository_impl.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/notification_item.dart'; // Adjust import path
import 'package:smart_farm_test/domain/repositories/notification_repository.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/auth_providers.dart'; // Need auth state

// --- FirestoreDataSource Provider (defined in auth_providers) ---
// final firestoreDataSourceProvider = Provider<FirestoreDataSource>(...);

// --- Notification Repository Provider ---
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  // Depends on FirestoreDataSource provider
  final firestoreDataSource = ref.watch(firestoreDataSourceProvider);
  return NotificationRepositoryImpl(firestoreDataSource);
});

// --- Provider to watch the current user's notification history ---
final notificationHistoryProvider = StreamProvider.autoDispose<List<NotificationItem>>((ref) {
   final authState = ref.watch(authStateProvider);
   final user = authState.valueOrNull; // Use valueOrNull

    if (user != null) {
      print("notificationHistoryProvider: Watching notifications for UID ${user.uid}");
      final notificationRepository = ref.watch(notificationRepositoryProvider);
      try {
         return notificationRepository.watchNotifications(user.uid);
      } catch (e, stackTrace) {
          print("notificationHistoryProvider: Error watching notifications - $e\n$stackTrace");
          return Stream.error(e, stackTrace);
      }
    } else {
       print("notificationHistoryProvider: No user logged in, returning empty list stream.");
       // No user logged in, return a stream with an empty list
       return Stream.value([]);
    }
});

// --- Action Provider for adding notifications to Firestore history ---
// This is called by the threshold alert logic
final addNotificationProvider = Provider((ref) {
   final repository = ref.watch(notificationRepositoryProvider);
   // Read auth state directly to avoid dependency loop if threshold provider also needs it
   final user = ref.read(authStateProvider).value;

   return ({
       required String title,
       required String body,
       String? blocId,
       String? deviceId, // Add deviceId
   }) {
       if (user != null) {
            print("addNotificationProvider: Adding notification for user ${user.uid}");
           // Call repo method asynchronously, don't wait here
           repository.addNotification(
               user.uid,
               title: title,
               body: body,
               blocId: blocId,
               deviceId: deviceId, // Pass deviceId
           ).catchError((e) {
               print("addNotificationProvider: Error saving notification to Firestore: $e");
               // Handle error logging or reporting if needed
           });
       } else {
          print("AddNotificationProvider: Cannot add notification, user not logged in.");
       }
   };
});


// --- Action Providers for managing notifications in the UI ---

final markNotificationReadProvider = Provider((ref) {
    final repo = ref.watch(notificationRepositoryProvider);
    final user = ref.watch(authStateProvider).value;
    return (String notificationId) async {
       if (user != null) {
           await repo.markNotificationAsRead(user.uid, notificationId);
       }
    };
});

final deleteNotificationProvider = Provider((ref) {
    final repo = ref.watch(notificationRepositoryProvider);
    final user = ref.watch(authStateProvider).value;
    return (String notificationId) async {
      if (user != null) {
         await repo.deleteNotification(user.uid, notificationId);
      }
   };
});
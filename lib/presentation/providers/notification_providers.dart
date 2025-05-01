import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/data/repositories/notification_repository_impl.dart';
import 'package:smart_farm_test/domain/entities/notification_item.dart';
import 'package:smart_farm_test/domain/repositories/notification_repository.dart';
import 'package:smart_farm_test/presentation/providers/auth_providers.dart'; // Need auth state

// Repository Provider
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  final firestoreDataSource = ref.watch(firestoreDataSourceProvider);
  return NotificationRepositoryImpl(firestoreDataSource);
});

// Provider to watch the current user's notification history
final notificationHistoryProvider = StreamProvider.autoDispose<List<NotificationItem>>((ref) {
   final authState = ref.watch(authStateProvider);
   final user = authState.value; // Get the Firebase User object

    if (user != null) {
      print("notificationHistoryProvider: Watching notifications for UID ${user.uid}");
      final notificationRepository = ref.watch(notificationRepositoryProvider);
      try {
         return notificationRepository.watchNotifications(user.uid);
      } catch (e) {
          print("notificationHistoryProvider: Error watching notifications - $e");
          return Stream.error(e);
      }
    } else {
       print("notificationHistoryProvider: No user logged in, returning empty list stream.");
       // No user logged in, return a stream with an empty list
       return Stream.value([]);
    }
});

// Provider for adding notifications (triggered by local threshold check)
final addNotificationProvider = Provider((ref) {
   final repository = ref.watch(notificationRepositoryProvider);
   final user = ref.watch(authStateProvider).value; // Get current user

   return ({required String title, required String body, String? blocId}) {
       if (user != null) {
           repository.addNotification(user.uid, title: title, body: body, blocId: blocId);
       } else {
          print("AddNotificationProvider: Cannot add notification, user not logged in.");
       }
   };
});
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/domain/entities/user_profile.dart';
import 'package:smart_farm_test/presentation/providers/auth_providers.dart'; // Need auth state
import 'package:smart_farm_test/presentation/providers/user_providers.dart'; // Need user repo

// Notifier now interacts with Firestore via UserRepository
class MonitoredBlockIdsNotifier extends StateNotifier<Set<String>> {
  final Ref ref; // Keep ref to read other providers

  // Initialize with empty set, load based on user profile stream
  MonitoredBlockIdsNotifier(this.ref) : super({});

  // No separate load function needed, we react to user profile changes

  // Add a block ID and update Firestore
  Future<void> addMonitoredBlock(String blockId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return; // Not logged in

    if (!state.contains(blockId)) {
      final updatedSet = {...state, blockId};
      state = updatedSet; // Update local state immediately for responsiveness
      try {
         await ref.read(userRepositoryProvider).updateMonitoredBlocks(user.uid, updatedSet.toList());
         print("Updated monitored blocks in Firestore: $state");
      } catch (e) {
         print("Error updating monitored blocks in Firestore: $e");
         // Optionally revert local state on error
         state = state.where((id) => id != blockId).toSet();
         rethrow; // Allow UI to show error
      }
    }
  }

  // Remove a block ID and update Firestore
  Future<void> removeMonitoredBlock(String blockId) async {
     final user = ref.read(authStateProvider).value;
     if (user == null) return;

     if (state.contains(blockId)) {
        final updatedSet = state.where((id) => id != blockId).toSet();
        state = updatedSet; // Update local state immediately
        try {
           await ref.read(userRepositoryProvider).updateMonitoredBlocks(user.uid, updatedSet.toList());
           print("Updated monitored blocks in Firestore: $state");
        } catch (e) {
           print("Error updating monitored blocks in Firestore: $e");
           // Optionally revert local state on error
           state = {...state, blockId};
           rethrow;
        }
     }
  }

  // Function to sync local state with Firestore state (called by provider)
  void syncWithFirestore(List<String> firestoreList) {
     final firestoreSet = firestoreList.toSet();
     if (state != firestoreSet) { // Only update if different
         print("Syncing local monitored blocks with Firestore: $firestoreSet");
         state = firestoreSet;
     }
  }
}


// Provider for the MonitoredBlockIdsNotifier
final monitoredBlockIdsProvider = StateNotifierProvider<MonitoredBlockIdsNotifier, Set<String>>((ref) {
    final notifier = MonitoredBlockIdsNotifier(ref);

    // Listen to the user profile provider
    ref.listen<UserProfile?>(userProfileProvider.select((asyncValue) => asyncValue.valueOrNull), (previousProfile, currentProfile) {
         if (currentProfile != null) {
             // When the user profile loads or changes, sync the monitored blocks
             notifier.syncWithFirestore(currentProfile.monitoredBlocks);
         } else {
             // User logged out or profile is null, reset local state
             notifier.syncWithFirestore([]);
         }
    });

    return notifier;
});
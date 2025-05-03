import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Base key for storing visible blocks in SharedPreferences
const String _prefsBaseKey = 'visibleBlocks_';

// Notifier to manage the Set of VISIBLE block IDs for a SPECIFIC device
class VisibleBlocksNotifier extends StateNotifier<Set<String>> {
  final String deviceId; // ID of the device these blocks belong to
  final Ref ref; // Ref to potentially read initial block list later?

  // Initialize with empty set, load initial values asynchronously
  VisibleBlocksNotifier(this.ref, this.deviceId) : super({}) {
    loadVisibleBlocks(); // Load on initialization
  }

  // Load IDs from SharedPreferences for this specific device
  Future<void> loadVisibleBlocks() async {
     try {
        final prefs = await SharedPreferences.getInstance();
        final List<String>? visibleIds = prefs.getStringList('$_prefsBaseKey$deviceId');
        if (visibleIds != null) {
           state = visibleIds.toSet();
           print("Loaded visible blocks for $deviceId: $state");
        } else {
           // Default: If no setting saved, assume all blocks are visible initially?
           // Or start empty and let user enable via FAB dialog? Let's start empty.
           state = {}; // Start empty
           print("No saved visible blocks for $deviceId, starting empty.");
           // No need to save empty state explicitly
        }
     } catch (e) {
        print("Error loading visible blocks for $deviceId from SharedPreferences: $e");
        state = {}; // Default to empty on error
     }
  }

  // Add a block ID to the visible set and save
  Future<void> showBlock(String blockId) async {
     if (!state.contains(blockId)) {
        state = {...state, blockId}; // Create new set with added ID
        await _saveToPrefs();
         print("Showing block $blockId for $deviceId. New state: $state");
     }
  }

  // Remove a block ID from the visible set and save
  Future<void> hideBlock(String blockId) async {
     if (state.contains(blockId)) {
        state = state.where((id) => id != blockId).toSet(); // Create new set without ID
        await _saveToPrefs();
         print("Hiding block $blockId for $deviceId. New state: $state");
     }
  }

   // Set all blocks as visible (useful for 'show all' action)
   Future<void> showAllBlocks(List<String> allBlockIds) async {
      state = allBlockIds.toSet();
      await _saveToPrefs();
       print("Showing all blocks for $deviceId. New state: $state");
   }

    // Set all blocks as hidden (useful for 'hide all' action)
   Future<void> hideAllBlocks() async {
      state = {};
      await _saveToPrefs();
       print("Hiding all blocks for $deviceId. New state: {}");
   }


  // Helper to save the current state to SharedPreferences
  Future<void> _saveToPrefs() async {
     try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('$_prefsBaseKey$deviceId', state.toList());
     } catch (e) {
        print("Error saving visible blocks for $deviceId to SharedPreferences: $e");
     }
  }
}

// Provider using .family to create a notifier for each deviceId
final visibleBlocksProvider = StateNotifierProvider.autoDispose
    .family<VisibleBlocksNotifier, Set<String>, String>((ref, deviceId) {
   // Creates a new notifier instance for each unique deviceId
   // The notifier loads its state from SharedPreferences upon creation.
   return VisibleBlocksNotifier(ref, deviceId);
});
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefsKey = 'monitoredBlockIds';

// Notifier to manage the Set of monitored block IDs
class MonitoredBlockIdsNotifier extends StateNotifier<Set<String>> {
   // Initialize with an empty set, load initial values asynchronously
  MonitoredBlockIdsNotifier() : super({});

  // Load IDs from SharedPreferences
  Future<void> loadMonitoredBlocks() async {
     final prefs = await SharedPreferences.getInstance();
     final List<String>? monitoredIds = prefs.getStringList(_prefsKey);
     if (monitoredIds != null) {
        state = monitoredIds.toSet();
         print("Loaded monitored blocks: $state");
     } else {
        // Default: Monitor 'bloc1' and 'bloc2' if nothing is saved yet
        state = {'bloc1', 'bloc2'};
         print("No saved blocks, defaulting to: $state");
         await _saveToPrefs(); // Save the default
     }
  }

  // Add a block ID to the monitored set and save
  Future<void> addMonitoredBlock(String blockId) async {
     if (!state.contains(blockId)) {
        state = {...state, blockId}; // Create new set with added ID
        await _saveToPrefs();
         print("Added $blockId to monitored blocks: $state");
     }
  }

  // Remove a block ID from the monitored set and save
  Future<void> removeMonitoredBlock(String blockId) async {
     if (state.contains(blockId)) {
        state = state.where((id) => id != blockId).toSet(); // Create new set without the ID
        await _saveToPrefs();
         print("Removed $blockId from monitored blocks: $state");
     }
  }

  // Helper to save the current state to SharedPreferences
  Future<void> _saveToPrefs() async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.setStringList(_prefsKey, state.toList());
  }
}

// Provider for the MonitoredBlockIdsNotifier
final monitoredBlockIdsProvider = StateNotifierProvider<MonitoredBlockIdsNotifier, Set<String>>((ref) {
   // Instantiated in main.dart override to allow pre-loading
   throw UnimplementedError('monitoredBlockIdsProvider must be overridden in main ProviderScope');
   // return MonitoredBlockIdsNotifier()..loadMonitoredBlocks(); // Standard instantiation if no preload needed
});
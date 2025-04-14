import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/presentation/providers/sensor_providers.dart';         // Provides allSensorBlocksStreamProvider
import 'package:smart_farm_test/presentation/providers/monitored_blocks_provider.dart'; // Provides monitoredBlockIdsProvider
import 'package:smart_farm_test/presentation/providers/filtered_blocks_provider.dart';  // Provides filteredSensorBlocksProvider
import 'package:smart_farm_test/presentation/widgets/sensor_block_card.dart';
import 'package:smart_farm_test/presentation/providers/threshold_alert_provider.dart'; // Import the new provider

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- Initialize the threshold listener ---
    // Watching this provider sets up the listener in its definition.
    // We don't need the return value (`void`) here.
    ref.watch(thresholdAlertProvider);
    // ---

    // Watch the provider that gives the FINAL list of blocks to display
    // This list is derived from all blocks (Firebase) filtered by monitored IDs (local)
    final filteredBlocksAsync = ref.watch(filteredSensorBlocksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Climate Monitor'),
      ),
      body: filteredBlocksAsync.when(
        // Data successfully loaded and filtered
        data: (filteredBlocks) {
          if (filteredBlocks.isEmpty) {
            // Show a message if no blocks are configured in Firebase OR
            // if no blocks are currently being monitored locally.
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No sensor blocks are currently being monitored.\nTap the "+" button to add blocks available on the device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            );
          }
          // Display the list of *filtered* sensor blocks using ListView.builder
          return RefreshIndicator(
             onRefresh: () async {
                // Invalidate providers to force refetch/recompute when user pulls down
                ref.invalidate(allSensorBlocksStreamProvider);
                ref.invalidate(filteredSensorBlocksProvider);
                // No need to invalidate thresholdAlertProvider, it just listens
                // No need to reload monitored blocks unless specifically desired
             },
             child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80), // Padding for FAB and top space
                itemCount: filteredBlocks.length,
                itemBuilder: (context, index) {
                  // Create a SensorBlockCard for each block in the filtered list
                  return SensorBlockCard(block: filteredBlocks[index]);
                },
             ),
           );
        },
        // Loading state (applies while fetching OR filtering)
        loading: () => const Center(child: CircularProgressIndicator()),
        // Error state
        error: (error, stackTrace) {
           print("Error in filteredSensorBlocksProvider (HomeScreen): $error\n$stackTrace");
           return Center(
             child: Padding(
               padding: const EdgeInsets.all(20.0),
               child: Text(
                 'Error loading sensor data:\n$error\nPlease check Firebase connection and setup.',
                 textAlign: TextAlign.center,
                 style: const TextStyle(color: Colors.red),
               ),
             )
           );
        }
      ),
      // Floating action button to add blocks to the monitored list
      floatingActionButton: FloatingActionButton(
         onPressed: () => _showAddBlockDialog(context, ref),
         tooltip: 'Show/Monitor Sensor Block', // Updated tooltip
         child: const Icon(Icons.add_circle_outline),
       ),
    );
  }

  // --- Dialog to Add Block to Monitoring (Show blocks from Firebase not currently monitored) ---
  void _showAddBlockDialog(BuildContext context, WidgetRef ref) {
     showDialog(
        context: context,
        // Use a builder that watches providers to get current state when dialog opens
        builder: (BuildContext dialogContext) {
           // Watch the source of truth for ALL blocks from Firebase
           final allBlocksAsync = ref.watch(allSensorBlocksStreamProvider);
           // Watch the list of blocks currently being monitored locally
           final monitoredIds = ref.watch(monitoredBlockIdsProvider);

           return allBlocksAsync.when(
              // When Firebase data is available
              data: (allBlocks) {
                 // Determine which blocks exist in Firebase but are NOT currently monitored
                 final availableToAdd = allBlocks
                    .where((block) => !monitoredIds.contains(block.id))
                    .toList(); // Keep as SensorBlock list for name access

                 // Case 1: All available blocks are already being monitored
                 if (availableToAdd.isEmpty) {
                    return AlertDialog(
                       title: const Text('Add Block'),
                       content: const Text('All available blocks from Firebase are already being monitored.'),
                       actions: [ TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK')) ],
                    );
                 }

                 // Case 2: Show list of blocks that can be added to monitoring
                 return AlertDialog(
                    title: const Text('Show Sensor Block'),
                    content: SingleChildScrollView(
                      child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: availableToAdd.map((blockToAdd) => ListTile(
                            title: Text(blockToAdd.name), // Show block name from Firebase data
                            subtitle: Text('ID: ${blockToAdd.id}'),
                            leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                            onTap: () async {
                               // Call notifier to add the ID to the monitored set (local state)
                               await ref.read(monitoredBlockIdsProvider.notifier).addMonitoredBlock(blockToAdd.id);
                               Navigator.pop(dialogContext); // Close the dialog
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text('Showing block "${blockToAdd.name}".'), duration: const Duration(seconds: 2)),
                               );
                            },
                         )).toList(),
                       ),
                     ),
                     actions: <Widget>[ TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')) ],
                  );
              },
              // Show loading state while fetching Firebase data
              loading: () => const AlertDialog(
                title: Text('Add Block'),
                content: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(child: CircularProgressIndicator())
                ),
              ),
              // Show error if Firebase data couldn't be loaded
              error: (err, stack) => AlertDialog(
                title: const Text('Error'),
                content: Text('Could not load blocks from Firebase: $err'),
                 actions: [ TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK')) ],
              ),
           );
        },
     );
  }
}
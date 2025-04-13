import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/presentation/providers/sensor_providers.dart';
import 'package:smart_farm_test/presentation/widgets/sensor_block_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the stream provider for sensor blocks
    final blocksAsyncValue = ref.watch(sensorBlocksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Climate Monitor Dashboard'),
        // Optional: Add indicator if Firebase connection has issues?
      ),
      body: blocksAsyncValue.when(
        // Data successfully loaded
        data: (blocks) {
          if (blocks.isEmpty) {
            // Show a message if no blocks are configured or found
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No sensor blocks found for device "$currentDeviceId".\nCheck Firebase Realtime Database structure or device ID.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            );
          }
          // Display the list of sensor blocks using ListView.builder
          return RefreshIndicator( // Add pull-to-refresh (optional, stream handles updates)
            onRefresh: () async {
               // Re-watch the provider (Riverpod often handles this, but can be explicit)
               ref.invalidate(sensorBlocksStreamProvider);
               // Give time for the stream to potentially emit a new value
               await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                // Create a SensorBlockCard for each block
                return SensorBlockCard(block: blocks[index]);
              },
            ),
          );
        },
        // Loading state
        loading: () => const Center(child: CircularProgressIndicator()),
        // Error state
        error: (error, stackTrace) {
           print("Error in HomeScreen stream: $error\n$stackTrace"); // Log the error
           return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error loading sensor data:\n$error\nPlease check Firebase connection and rules.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            )
           );
        }
      ),
      // Optional: Add a floating action button if you want to implement
      // adding new blocks directly from the app in the future.
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () { /* TODO: Implement add new block logic */ },
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
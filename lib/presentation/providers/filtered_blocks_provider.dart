import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/device_providers.dart'; // Provides RTDB stream
import 'package:smart_farm_test/presentation/providers/visible_blocks_provider.dart'; // Provides local visibility set

// Provider family: Filters blocks for a specific device based on local visibility preferences
final filteredDeviceBlocksProvider = Provider.autoDispose
    .family<AsyncValue<List<SensorBlock>>, String>((ref, deviceId) {

   // Watch the stream of ALL blocks for this device from RTDB
   final allBlocksAsync = ref.watch(deviceSensorBlocksStreamProvider(deviceId));
   // Watch the local state of VISIBLE block IDs for this device
   final visibleIds = ref.watch(visibleBlocksProvider(deviceId));

   // Combine the results
   return allBlocksAsync.when(
     data: (allBlocks) {
       // Filter the blocks based on the visible IDs Set
       // If visibleIds is empty after initial load, this will show nothing until user enables blocks.
       // Consider defaulting to show all if visibleIds state is empty initially? (Handled in notifier load)
       final filteredList = allBlocks.where((block) => visibleIds.contains(block.id)).toList();

       // Return the filtered list wrapped in AsyncValue.data
       print("Filtered blocks for $deviceId: ${filteredList.length} of ${allBlocks.length}");
       return AsyncValue.data(filteredList);
     },
     loading: () => const AsyncValue.loading(), // Pass loading state
     error: (err, stack) => AsyncValue.error(err, stack), // Pass error state
   );
});
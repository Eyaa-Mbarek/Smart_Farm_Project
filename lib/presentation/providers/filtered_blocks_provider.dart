import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart';
import 'package:smart_farm_test/presentation/providers/sensor_providers.dart';
import 'package:smart_farm_test/presentation/providers/monitored_blocks_provider.dart';

// Provider that combines all blocks and monitored IDs to produce the filtered list for the UI
final filteredSensorBlocksProvider = Provider.autoDispose<AsyncValue<List<SensorBlock>>>((ref) {

  // Watch the stream of ALL blocks coming from Firebase
  final allBlocksAsync = ref.watch(allSensorBlocksStreamProvider);
  // Watch the state of locally monitored block IDs
  final monitoredIds = ref.watch(monitoredBlockIdsProvider);

  // Combine the results
  return allBlocksAsync.when(
    data: (allBlocks) {
      // Filter the blocks based on the monitored IDs
      final filteredList = allBlocks.where((block) => monitoredIds.contains(block.id)).toList();
      // Return the filtered list wrapped in AsyncValue.data
      return AsyncValue.data(filteredList);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
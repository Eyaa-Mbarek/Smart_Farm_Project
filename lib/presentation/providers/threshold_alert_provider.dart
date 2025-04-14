import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart';
import 'package:smart_farm_test/presentation/providers/filtered_blocks_provider.dart';
import 'package:smart_farm_test/presentation/services/notification_service.dart';

// Provider simply observes the filtered blocks and triggers side effects (notifications)
final thresholdAlertProvider = Provider.autoDispose<void>((ref) {
  // Store previous block values to detect *crossing* the threshold
  final previousValues = StateController<Map<String, double?>>({});

  // Listen to the *successful data* from the filteredSensorBlocksProvider
  ref.listen<AsyncValue<List<SensorBlock>>>(filteredSensorBlocksProvider, (previousAsync, currentAsync) {
    // Only proceed if the current state has data
    if (currentAsync is AsyncData<List<SensorBlock>>) {
      final currentBlocks = currentAsync.value;
      final notificationService = NotificationService(); // Get service instance
      final Map<String, double?> previousValsMap = previousValues.state;
      final Map<String, double?> updatedPreviousVals = Map.from(previousValsMap); // Create mutable copy

      for (final block in currentBlocks) {
        final previousValue = previousValsMap[block.id];
        final currentValue = block.value;

        // Check if threshold check is needed
        if (block.enabled && currentValue != null && block.threshold > 0) { // Check threshold > 0?
          final bool crossedThresholdUpwards =
              (previousValue == null || previousValue <= block.threshold) &&
              currentValue > block.threshold;

          if (crossedThresholdUpwards) {
            print("Local Threshold Check: ${block.id} crossed threshold!");
            notificationService.showThresholdNotification(
              blockId: block.id,
              blockName: block.name,
              value: currentValue,
              threshold: block.threshold,
              unit: block.unit,
            );
          }
        }
         // Update the previous value map for the next check
         updatedPreviousVals[block.id] = currentValue;
      }
       // Update the state controller with the latest values
       previousValues.state = updatedPreviousVals;
    }
  }, fireImmediately: false); // Don't fire immediately, wait for first data load
});
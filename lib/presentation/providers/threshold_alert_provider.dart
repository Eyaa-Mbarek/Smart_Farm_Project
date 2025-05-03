import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/device_providers.dart'; // Use deviceSensorBlocksStreamProvider
import 'package:smart_farm_test/presentation/providers/notification_providers.dart'; // Need add provider
import 'package:smart_farm_test/presentation/services/notification_service.dart'; // Adjust import path

// Provider now uses .family to listen to a specific deviceId's block stream
final deviceThresholdAlertProvider = Provider.autoDispose.family<void, String>((ref, deviceId) {
  // Prevent setup if deviceId is invalid
  if (deviceId.trim().isEmpty) return;

  print("Setting up deviceThresholdAlertProvider for $deviceId");

  // Store previous block values *for this specific device*
  // Use a map associated with the provider instance's lifecycle
  final previousValues = StateController<Map<String, double?>>({});

  // Get the function to add notification to Firestore (will check for user internally)
  final addNotificationToHistory = ref.read(addNotificationProvider);

  // Keep track if listener is active to prevent multiple setups if provider rebuilds quickly
  var isListenerActive = true;
  ref.onDispose(() {
     print("Disposing deviceThresholdAlertProvider for $deviceId");
     isListenerActive = false;
     // Clear previous values map when disposed
     previousValues.state = {};
   });


  // Listen to the specific device's sensor block stream
  ref.listen<AsyncValue<List<SensorBlock>>>(
    deviceSensorBlocksStreamProvider(deviceId),
    (previousAsync, currentAsync) {
      // Ensure listener is still active and we have data
      if (!isListenerActive || currentAsync is! AsyncData<List<SensorBlock>>) {
        return;
      }

      final currentBlocks = currentAsync.value;
      final notificationService = NotificationService(); // Get service instance
      final Map<String, double?> previousValsMap = previousValues.state;
      // Create a mutable copy to update within the loop
      final Map<String, double?> updatedPreviousVals = Map.from(previousValsMap);

      print("Threshold Check Running for $deviceId: ${currentBlocks.length} blocks");

      for (final block in currentBlocks) {
         final previousValue = previousValsMap[block.id];
         final currentValue = block.value;

         // Perform threshold check
         if (block.enabled && currentValue != null) {
             final bool crossedThresholdUpwards =
                 // Trigger if no previous value OR previous was below/equal AND current is above
                 (previousValue == null || previousValue <= block.threshold) &&
                 currentValue > block.threshold;

             if (crossedThresholdUpwards) {
                print("Local Threshold Check: ${block.id} on device $deviceId crossed threshold! (Val: $currentValue > Thr: ${block.threshold})");
                final title = 'Alert: ${block.name} ($deviceId)'; // Add deviceId to title
                final body = 'Value ${currentValue.toStringAsFixed(1)}${block.unit} exceeds threshold ${block.threshold.toStringAsFixed(1)}${block.unit}!';

                // 1. Show Local Notification via Service
                notificationService.showThresholdNotification(
                  blockId: block.id, // Payload could include deviceId too if needed
                  blockName: title, // Use updated title including device ID
                  value: currentValue,
                  threshold: block.threshold,
                  unit: block.unit,
                );

                // 2. Add Notification to Firestore History (via provider)
                 // Use the function obtained earlier
                 addNotificationToHistory(
                    title: title,
                    body: body,
                    blocId: block.id,
                    deviceId: deviceId, // Pass deviceId to history
                 );
             }
         }
          // Update the previous value map for the next check, regardless of threshold crossing
          updatedPreviousVals[block.id] = currentValue;
      }
       // Update the state controller with the latest values after checking all blocks
       // Check if listener is still active before updating state
       if(isListenerActive) {
          previousValues.state = updatedPreviousVals;
       }
    },
    fireImmediately: false // Don't check on initial listen, wait for first data
  );
});
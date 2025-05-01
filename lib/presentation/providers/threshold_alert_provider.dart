import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart';
import 'package:smart_farm_test/presentation/providers/filtered_blocks_provider.dart';
import 'package:smart_farm_test/presentation/providers/notification_providers.dart'; // Need add provider
import 'package:smart_farm_test/presentation/services/notification_service.dart';

final thresholdAlertProvider = Provider.autoDispose<void>((ref) {
  final previousValues = StateController<Map<String, double?>>({});

  // Get the function to add notification to Firestore (will check for user internally)
  final addNotificationToHistory = ref.read(addNotificationProvider);

  ref.listen<AsyncValue<List<SensorBlock>>>(filteredSensorBlocksProvider, (previousAsync, currentAsync) {
    // Only proceed if the current state has data
    if (currentAsync is AsyncData<List<SensorBlock>>) {
      final currentBlocks = currentAsync.value;
      final notificationService = NotificationService();
      final Map<String, double?> previousValsMap = previousValues.state;
      final Map<String, double?> updatedPreviousVals = Map.from(previousValsMap);

      for (final block in currentBlocks) {
        final previousValue = previousValsMap[block.id];
        final currentValue = block.value;

        if (block.enabled && currentValue != null) {
          final bool crossedThresholdUpwards =
              (previousValue == null || previousValue <= block.threshold) &&
              currentValue > block.threshold;

          if (crossedThresholdUpwards) {
            print("Local Threshold Check: ${block.id} crossed threshold!");
            final title = 'Climate Alert: ${block.name}';
            final body = 'Value ${currentValue.toStringAsFixed(1)}${block.unit} exceeds threshold ${block.threshold.toStringAsFixed(1)}${block.unit}!';

            // 1. Show Local Notification
            notificationService.showThresholdNotification(
              blockId: block.id,
              blockName: block.name,
              value: currentValue,
              threshold: block.threshold,
              unit: block.unit,
            );

            // 2. Add Notification to Firestore History (via provider)
            addNotificationToHistory(
               title: title,
               body: body,
               blocId: block.id,
            );
          }
        }
         updatedPreviousVals[block.id] = currentValue;
      }
       previousValues.state = updatedPreviousVals;
    }
  }, fireImmediately: false);
});
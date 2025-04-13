import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart';

class FirebaseDataSource {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  // Store reference to the listener to cancel it later if needed
  StreamSubscription<DatabaseEvent>? _blocksSubscription;

  DatabaseReference _getBlocsRef(String deviceId) {
      return _database.ref('devices/$deviceId/blocs');
  }

  Stream<List<SensorBlock>> watchSensorBlocks(String deviceId) {
    final controller = StreamController<List<SensorBlock>>();
    final ref = _getBlocsRef(deviceId);

    _blocksSubscription = ref.onValue.listen((event) {
      final data = event.snapshot.value;
      final blocks = <SensorBlock>[];

      if (data != null && data is Map) {
        final mapData = Map<String, dynamic>.from(data); // Cast keys to String
         mapData.forEach((key, value) {
          if (value != null && value is Map) {
             final blockData = Map<String, dynamic>.from(value);
              try {
                blocks.add(SensorBlock.fromJson(key, blockData));
              } catch (e) {
                  print("Error parsing block $key: $e");
                  // Optionally add a placeholder or skip the block
              }
          }
        });
         // Sort blocks by ID for consistent order
         blocks.sort((a, b) => a.id.compareTo(b.id));
      }
      controller.add(blocks); // Add the list (even if empty) to the stream
    },
    onError: (error) {
        print("Error listening to Firebase: $error");
        controller.addError(error); // Forward the error to the stream
    });

     // When the stream listener is cancelled, close the subscription
     controller.onCancel = () {
        _blocksSubscription?.cancel();
        print("Cancelled Firebase blocks subscription.");
     };


    return controller.stream;
  }

  Future<void> updateSensorBlockConfig(String deviceId, String blockId, Map<String, dynamic> updates) async {
    // Remove null values to avoid overwriting fields unintentionally
    updates.removeWhere((key, value) => value == null);
    if (updates.isNotEmpty) {
        try {
            await _getBlocsRef(deviceId).child(blockId).update(updates);
            print("Updated config for $blockId: $updates");
        } catch (e) {
            print("Error updating Firebase config for $blockId: $e");
            rethrow; // Re-throw the error to be caught by the caller
        }
    }
  }

   // Call this when the data source is no longer needed (e.g., in dispose method of a provider)
   void dispose() {
     _blocksSubscription?.cancel();
   }
}
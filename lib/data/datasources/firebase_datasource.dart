import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/sensor_type.dart'; // Adjust import path

class FirebaseDataSource {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  // Keep track of active listeners to cancel them
  final Map<String, StreamSubscription<DatabaseEvent>> _blockSubscriptions = {};

  DatabaseReference _getBlocsRef(String deviceId) {
      // Ensure deviceId is valid before creating ref? Basic check:
      if (deviceId.isEmpty) {
          throw ArgumentError("Device ID cannot be empty for RTDB reference.");
      }
      return _database.ref('devices/$deviceId/blocs');
  }

  // Renamed method: Watches blocks for a SPECIFIC device
  Stream<List<SensorBlock>> watchDeviceSensorBlocks(String deviceId) {
    // Cancel existing listener for this deviceId if any
    _cancelSubscription(deviceId);

    final controller = StreamController<List<SensorBlock>>();
    final ref = _getBlocsRef(deviceId);
    print("FirebaseDataSource (RTDB): Subscribing to $ref");

    final subscription = ref.onValue.listen(
      (event) {
        final data = event.snapshot.value;
        final blocks = <SensorBlock>[];
        if (data != null && data is Map) {
          final mapData = Map<String, dynamic>.from(data);
           mapData.forEach((key, value) {
            if (value != null && value is Map) {
               final blockData = Map<String, dynamic>.from(value);
                try {
                  blocks.add(SensorBlock.fromJson(key, blockData));
                } catch (e) {
                    print("FirebaseDataSource (RTDB): Error parsing block $key for device $deviceId: $e");
                }
            }
          });
           blocks.sort((a, b) => a.id.compareTo(b.id));
        }
        controller.add(blocks);
      },
      onError: (error) {
          print("FirebaseDataSource (RTDB): Error listening to $ref: $error");
          controller.addError(error);
           _blockSubscriptions.remove(deviceId); // Remove failed subscription
      },
      onDone: () {
         print("FirebaseDataSource (RTDB): Stream done for $ref");
          _blockSubscriptions.remove(deviceId); // Clean up on done
      }
    );

    // Store the subscription
     _blockSubscriptions[deviceId] = subscription;

     // When the controller listener is cancelled, cancel the Firebase subscription
     controller.onCancel = () {
        print("FirebaseDataSource (RTDB): Controller cancelled for $ref");
        _cancelSubscription(deviceId);
     };

    return controller.stream;
  }

  // Updates config for a specific block on a specific device
  Future<void> updateSensorBlockConfig(String deviceId, String blockId, Map<String, dynamic> updates) async {
    updates.removeWhere((key, value) => value == null);
    if (updates.isNotEmpty) {
        try {
            await _getBlocsRef(deviceId).child(blockId).update(updates);
            print("FirebaseDataSource (RTDB): Updated config for $deviceId/$blockId: $updates");
        } catch (e) {
            print("FirebaseDataSource (RTDB): Error updating RTDB config for $deviceId/$blockId: $e");
            rethrow;
        }
    }
  }

  // Helper to cancel a specific subscription
  void _cancelSubscription(String deviceId) {
     final existingSubscription = _blockSubscriptions.remove(deviceId);
     if (existingSubscription != null) {
        existingSubscription.cancel();
         print("FirebaseDataSource (RTDB): Cancelled existing subscription for device $deviceId");
     }
  }

   // Dispose method to cancel all active listeners when datasource is no longer needed
   void dispose() {
     print("FirebaseDataSource (RTDB): Disposing ${_blockSubscriptions.length} listeners...");
     // Create a copy of keys because removing modifies the map during iteration
     final deviceIds = List<String>.from(_blockSubscriptions.keys);
     for (final deviceId in deviceIds) {
        _cancelSubscription(deviceId);
     }
      _blockSubscriptions.clear();
      print("FirebaseDataSource (RTDB): Disposed.");
   }
}
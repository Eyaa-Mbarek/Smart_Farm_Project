import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart';

class FirebaseDataSource {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  StreamSubscription<DatabaseEvent>? _blocksSubscription;

  DatabaseReference _getBlocsRef(String deviceId) {
      return _database.ref('devices/$deviceId/blocs');
  }

   // --- WATCH ALL --- (Renamed for clarity, logic is the same)
  Stream<List<SensorBlock>> watchAllSensorBlocks(String deviceId) {
    final controller = StreamController<List<SensorBlock>>();
    final ref = _getBlocsRef(deviceId);
    print("FirebaseDataSource: Subscribing to $ref"); // Debug log

    _blocksSubscription = ref.onValue.listen((event) {
      final data = event.snapshot.value;
      final blocks = <SensorBlock>[];

      if (data != null && data is Map) {
        print("FirebaseDataSource: Received data"); // Debug log
        final mapData = Map<String, dynamic>.from(data);
         mapData.forEach((key, value) {
          if (value != null && value is Map) {
             final blockData = Map<String, dynamic>.from(value);
              try {
                blocks.add(SensorBlock.fromJson(key, blockData));
              } catch (e) {
                  print("FirebaseDataSource: Error parsing block $key: $e");
              }
          }
        });
         blocks.sort((a, b) => a.id.compareTo(b.id));
      } else {
         print("FirebaseDataSource: Received null or non-map data"); // Debug log
      }
      controller.add(blocks);
      print("FirebaseDataSource: Emitted ${blocks.length} blocks"); // Debug log
    },
    onError: (error) {
        print("FirebaseDataSource: Error listening to Firebase: $error");
        controller.addError(error);
    });

     controller.onCancel = () {
        _blocksSubscription?.cancel();
        print("FirebaseDataSource: Cancelled Firebase blocks subscription.");
     };

    return controller.stream;
  }

  // --- UPDATE ---
  Future<void> updateSensorBlockConfig(String deviceId, String blockId, Map<String, dynamic> updates) async {
    // (Keep existing update logic)
    updates.removeWhere((key, value) => value == null);
    if (updates.isNotEmpty) {
        try {
            await _getBlocsRef(deviceId).child(blockId).update(updates);
            print("FirebaseDataSource: Updated config for $blockId: $updates");
        } catch (e) {
            print("FirebaseDataSource: Error updating Firebase config for $blockId: $e");
            rethrow;
        }
    }
  }

  // --- ADD and DELETE methods are REMOVED ---

   void dispose() {
     _blocksSubscription?.cancel();
     print("FirebaseDataSource: Disposed");
   }
}
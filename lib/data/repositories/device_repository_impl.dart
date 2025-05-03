import 'package:smart_farm_test/data/datasources/firestore_datasource.dart'; // Adjust import path
import 'package:smart_farm_test/data/datasources/firebase_datasource.dart'; // RTDB Datasource - Adjust import path
import 'package:smart_farm_test/domain/entities/device_config.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/sensor_block.dart'; // Adjust import path
import 'package:smart_farm_test/domain/repositories/device_repository.dart'; // Adjust import path

class DeviceRepositoryImpl implements IDeviceRepository {
  final FirestoreDataSource _firestoreDataSource;
  final FirebaseDataSource _rtdbDataSource;

  DeviceRepositoryImpl(this._firestoreDataSource, this._rtdbDataSource);
  // --- Firestore Device Config ---
  @override
  Future<DeviceConfig?> getDeviceConfig(String deviceId) async {
     final snapshot = await _firestoreDataSource.getDeviceConfig(deviceId);
     if (snapshot.exists && snapshot.data() != null) {
        try {
            return DeviceConfig.fromFirestore(snapshot);
        } catch (e) {
           print("Error parsing DeviceConfig for $deviceId: $e");
           return null; // Return null if parsing fails
        }
     }
     return null;
  }

  @override
  Stream<DeviceConfig?> watchDeviceConfig(String deviceId) { // NEW watch method
     return _firestoreDataSource.watchDeviceConfig(deviceId).map((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
           try { return DeviceConfig.fromFirestore(snapshot); } catch (e) { return null; }
        }
        return null;
     }).handleError((e) {
         print("Error in watchDeviceConfig stream for $deviceId: $e");
         return null; // Emit null on error
     });
  }

  @override
  Future<bool> deviceConfigExists(String deviceId) {
     return _firestoreDataSource.deviceConfigExists(deviceId);
  }

   @override
   Future<void> createDeviceConfig(String deviceId, String ownerUid, String deviceName) {
       // Use the static helper from entity
       final initialData = DeviceConfig.initialData(ownerUid, deviceName);
       return _firestoreDataSource.createDeviceConfig(deviceId, initialData);
   }

   @override
   Future<void> updateDeviceConfig(String deviceId, Map<String, dynamic> data) {
       // Could add validation here (e.g., ensure deviceName is not empty)
       return _firestoreDataSource.updateDeviceConfig(deviceId, data);
   }

   @override
   Future<void> deleteDeviceConfig(String deviceId) {
        // !! IMPORTANT !!
        // Implement transaction here to also remove the deviceId from:
        // - users/{ownerUid}/ownedDevices
        // - users/{anyUserId}/monitoredDevices
        // - users/{anyUserId}/accessibleDevices map
        // This is complex and requires careful handling. For now, just deletes config.
       print("Warning: Deleting device config $deviceId without cleaning up user references.");
       return _firestoreDataSource.deleteDeviceConfig(deviceId);
   }

// --- Authorization Management ---
  @override
  Future<void> addAuthorizedUser(String deviceId, String userUidToAdd) {
     return _firestoreDataSource.addAuthorizedUser(deviceId, userUidToAdd);
  }
  @override
  Future<void> removeAuthorizedUser(String deviceId, String userUidToRemove) {
     // Optional: Add check to prevent removing the owner? Rules should handle this.
     return _firestoreDataSource.removeAuthorizedUser(deviceId, userUidToRemove);
  }

  // --- Realtime Database Sensor Data ---
  @override
  Stream<List<SensorBlock>> watchDeviceSensorBlocks(String deviceId) {
     // Method name matches the updated RTDB DataSource method
     return _rtdbDataSource.watchDeviceSensorBlocks(deviceId);
  }

   @override
   Future<void> updateDeviceBlockConfig(String deviceId, String blockId, Map<String, dynamic> data) {
       // This interacts with RTDB via the RTDB datasource
       return _rtdbDataSource.updateSensorBlockConfig(deviceId, blockId, data);
   }
}
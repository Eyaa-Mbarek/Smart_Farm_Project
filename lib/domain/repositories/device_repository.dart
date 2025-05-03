import 'package:smart_farm_test/domain/entities/device_config.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/sensor_block.dart'; // Adjust import path

abstract class IDeviceRepository {
   // --- Firestore Device Config ---
   Future<DeviceConfig?> getDeviceConfig(String deviceId);
   Stream<DeviceConfig?> watchDeviceConfig(String deviceId); // Add stream to watch config changes
   Future<bool> deviceConfigExists(String deviceId);
   Future<void> createDeviceConfig(String deviceId, String ownerUid, String deviceName);
   Future<void> updateDeviceConfig(String deviceId, Map<String, dynamic> data);
   Future<void> deleteDeviceConfig(String deviceId);

   // --- Authorization Management ---
   Future<void> addAuthorizedUser(String deviceId, String userUidToAdd);
   Future<void> removeAuthorizedUser(String deviceId, String userUidToRemove);

   // --- Realtime Database Sensor Data ---
   Stream<List<SensorBlock>> watchDeviceSensorBlocks(String deviceId);
   Future<void> updateDeviceBlockConfig(String deviceId, String blockId, Map<String, dynamic> data);
}
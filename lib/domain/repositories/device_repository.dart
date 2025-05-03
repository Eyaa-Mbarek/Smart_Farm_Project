import 'package:smart_farm_test/domain/entities/device_config.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/sensor_block.dart'; // Adjust import path

abstract class IDeviceRepository {
   // --- Firestore Device Config ---
   Future<DeviceConfig?> getDeviceConfig(String deviceId);
   Future<bool> deviceConfigExists(String deviceId);
   Future<void> createDeviceConfig(String deviceId, String ownerUid, String deviceName);
   Future<void> updateDeviceConfig(String deviceId, Map<String, dynamic> data); // e.g., update name, authorizedUsers
   Future<void> deleteDeviceConfig(String deviceId); // Use with caution

   // --- Realtime Database Sensor Data ---
   // Listener for ALL blocks of a specific device
   Stream<List<SensorBlock>> watchDeviceSensorBlocks(String deviceId);
   // Update block config in RTDB (as before)
   Future<void> updateDeviceBlockConfig(String deviceId, String blockId, Map<String, dynamic> data);

   // Maybe methods to get device status from RTDB?
   // Stream<Map<String,dynamic>> watchDeviceStatus(String deviceId);
}
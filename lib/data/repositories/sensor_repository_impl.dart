import 'package:smart_farm_test/data/datasources/firebase_datasource.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart';
import 'package:smart_farm_test/domain/entities/sensor_type.dart';
import 'package:smart_farm_test/domain/repositories/sensor_repository.dart';

class FirebaseSensorRepositoryImpl implements ISensorRepository {
  final FirebaseDataSource dataSource;
  FirebaseSensorRepositoryImpl(this.dataSource);

  // Renamed to match interface
  @override
  Stream<List<SensorBlock>> watchAllSensorBlocks(String deviceId) {
    return dataSource.watchAllSensorBlocks(deviceId);
  }

  @override
  Future<void> updateSensorBlockConfig(String deviceId, String blockId, {
      String? name, SensorType? type, double? threshold, String? unit, bool? enabled}) async {
        // (Keep existing update logic)
         final updates = <String, dynamic>{};
         if (name != null) updates['name'] = name;
         if (type != null) {
             updates['type'] = sensorTypeToInt(type);
             updates['unit'] = unit ?? sensorTypeToUnit(type);
         } else if (unit != null) {
             updates['unit'] = unit;
         }
         if (threshold != null) updates['threshold'] = threshold;
         if (enabled != null) updates['enabled'] = enabled;

         await dataSource.updateSensorBlockConfig(deviceId, blockId, updates);
  }

   // --- ADD and DELETE methods are REMOVED ---
}
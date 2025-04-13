import 'package:smart_farm_test/data/datasources/firebase_datasource.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart';
import 'package:smart_farm_test/domain/entities/sensor_type.dart';
import 'package:smart_farm_test/domain/repositories/sensor_repository.dart';

class FirebaseSensorRepositoryImpl implements ISensorRepository {
  final FirebaseDataSource dataSource;
  FirebaseSensorRepositoryImpl(this.dataSource);

  @override
  Stream<List<SensorBlock>> watchSensorBlocks(String deviceId) {
    return dataSource.watchSensorBlocks(deviceId);
  }

  @override
  Future<void> updateSensorBlockConfig(String deviceId, String blockId, {
      String? name, SensorType? type, double? threshold, bool? enabled}) async {

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (type != null) {
          updates['type'] = sensorTypeToInt(type);
          // Always update unit when type changes
          updates['unit'] = sensorTypeToUnit(type);
      }
      if (threshold != null) updates['threshold'] = threshold;
      if (enabled != null) updates['enabled'] = enabled;

      await dataSource.updateSensorBlockConfig(deviceId, blockId, updates);
  }
}
import 'package:smart_farm_test/domain/entities/sensor_block.dart';
import 'package:smart_farm_test/domain/entities/sensor_type.dart';

abstract class ISensorRepository {
  Stream<List<SensorBlock>> watchSensorBlocks(String deviceId);

  Future<void> updateSensorBlockConfig(String deviceId, String blockId, {
    String? name,
    SensorType? type,
    double? threshold,
    bool? enabled,
  });
}
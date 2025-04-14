import 'package:smart_farm_test/domain/entities/sensor_block.dart';
import 'package:smart_farm_test/domain/entities/sensor_type.dart';

// Interface now only deals with fetching and updating configuration
abstract class ISensorRepository {
  // Gets ALL sensor blocks from Firebase for the device
  Stream<List<SensorBlock>> watchAllSensorBlocks(String deviceId);

  // Updates configuration FOR A BLOCK IN FIREBASE
  Future<void> updateSensorBlockConfig(String deviceId, String blockId, {
    String? name,
    SensorType? type,
    double? threshold,
    String? unit,
    bool? enabled,
  });
}
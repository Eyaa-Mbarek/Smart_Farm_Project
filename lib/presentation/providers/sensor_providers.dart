import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/data/datasources/firebase_datasource.dart';
import 'package:smart_farm_test/data/repositories/sensor_repository_impl.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart';
import 'package:smart_farm_test/domain/repositories/sensor_repository.dart';
import 'package:smart_farm_test/domain/entities/sensor_type.dart';

const String currentDeviceId = "esp32_main";

// Data Source Provider (No change)
final firebaseDataSourceProvider = Provider<FirebaseDataSource>((ref) {
   final dataSource = FirebaseDataSource();
   ref.onDispose(() => dataSource.dispose());
   return dataSource;
});

// Repository Provider (No change)
final sensorRepositoryProvider = Provider<ISensorRepository>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return FirebaseSensorRepositoryImpl(dataSource);
});

// Provider to watch ALL blocks from Firebase
final allSensorBlocksStreamProvider = StreamProvider.autoDispose<List<SensorBlock>>((ref) {
  print("allSensorBlocksStreamProvider executing"); // Debug log
  final repository = ref.watch(sensorRepositoryProvider);
  return repository.watchAllSensorBlocks(currentDeviceId);
});

// Update Action Provider (No change)
final updateSensorConfigProvider = Provider((ref) {
  final repository = ref.watch(sensorRepositoryProvider);
  return ({
      required String blockId,
      String? name, SensorType? type, double? threshold,
      String? unit, bool? enabled,
    }) => repository.updateSensorBlockConfig(
        currentDeviceId, blockId,
        name: name, type: type, threshold: threshold,
        unit: unit, enabled: enabled,
      );
});
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/data/datasources/firebase_datasource.dart';
import 'package:smart_farm_test/data/repositories/sensor_repository_impl.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart';
import 'package:smart_farm_test/domain/repositories/sensor_repository.dart';
import 'package:smart_farm_test/domain/entities/sensor_type.dart';

// Define the device ID we are monitoring
const String currentDeviceId = "esp32_main";

// Provider for the data source instance
final firebaseDataSourceProvider = Provider<FirebaseDataSource>((ref) {
   final dataSource = FirebaseDataSource();
   // Ensure the subscription is cancelled when the provider is disposed
   ref.onDispose(() => dataSource.dispose());
   return dataSource;
});

// Provider for the repository implementation
final sensorRepositoryProvider = Provider<ISensorRepository>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return FirebaseSensorRepositoryImpl(dataSource);
});

// StreamProvider to watch the sensor blocks
final sensorBlocksStreamProvider = StreamProvider.autoDispose<List<SensorBlock>>((ref) {
  final repository = ref.watch(sensorRepositoryProvider);
  // Watch blocks for the specific device ID
  return repository.watchSensorBlocks(currentDeviceId);
});

// Provider (or use direct ref.read in widget) for the update action
// This doesn't need to be a provider itself, could be called directly
// using ref.read(sensorRepositoryProvider).updateSensorBlockConfig(...)
// But creating a dedicated function/provider can be cleaner for testing/reuse
final updateSensorConfigProvider = Provider((ref) {
  final repository = ref.watch(sensorRepositoryProvider);
  return ({
      required String blockId,
      String? name,
      SensorType? type,
      double? threshold,
      bool? enabled,
    }) => repository.updateSensorBlockConfig(
        currentDeviceId,
        blockId,
        name: name,
        type: type,
        threshold: threshold,
        enabled: enabled,
      );
});
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/data/datasources/firestore_datasource.dart'; // Adjust import path
import 'package:smart_farm_test/data/datasources/firebase_datasource.dart'; // Adjust import path
import 'package:smart_farm_test/data/repositories/device_repository_impl.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/device_config.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/sensor_block.dart'; // Adjust import path
import 'package:smart_farm_test/domain/repositories/device_repository.dart';
import 'package:smart_farm_test/presentation/providers/auth_providers.dart'; // Adjust import path
// --- FirestoreDataSource Provider (defined in auth_providers) ---
// final firestoreDataSourceProvider = Provider<FirestoreDataSource>(...);

// --- RTDB DataSource Provider ---
// Assuming primary definition is here or imported
final firebaseDataSourceProvider = Provider<FirebaseDataSource>((ref) {
   final ds = FirebaseDataSource();
   // Dispose the RTDB listeners when the provider is disposed
   ref.onDispose(() => ds.dispose());
   return ds;
});


// --- Device Repository Provider ---
final deviceRepositoryProvider = Provider<IDeviceRepository>((ref) {
  final firestoreDS = ref.watch(firestoreDataSourceProvider);
  final rtdbDS = ref.watch(firebaseDataSourceProvider); // Watch the RTDB provider
  return DeviceRepositoryImpl(firestoreDS, rtdbDS);
});

// Watch config changes (autoDispose, family) - NEW
final deviceConfigStreamProvider = StreamProvider.autoDispose.family<DeviceConfig?, String>((ref, deviceId) {
    if (deviceId.trim().isEmpty) return Stream.value(null);
    print("deviceConfigStreamProvider executing for $deviceId");
    final repository = ref.watch(deviceRepositoryProvider);
    return repository.watchDeviceConfig(deviceId);
});

// --- Provider to get config for a specific device ---
// Used when adding/registering a device to check existence and details.
// Not autoDispose, as config might be needed briefly across actions.
final deviceConfigProvider = FutureProvider.autoDispose.family<DeviceConfig?, String>((ref, deviceId) async {
   // Prevent unnecessary fetches for empty IDs
   if (deviceId.trim().isEmpty) {
      print("deviceConfigProvider: deviceId is empty, returning null.");
      return null;
   }
   print("deviceConfigProvider executing for $deviceId");
   final repository = ref.watch(deviceRepositoryProvider);
   try {
       return await repository.getDeviceConfig(deviceId);
   } catch (e) {
      print("deviceConfigProvider: Error fetching config for $deviceId - $e");
      return null; // Return null on error
   }
});

// --- Provider to watch sensor blocks for a *specific* device ID ---
// Family allows passing the deviceId.
// AutoDispose because it's likely only needed while a specific device view is active.
final deviceSensorBlocksStreamProvider = StreamProvider.autoDispose.family<List<SensorBlock>, String>((ref, deviceId) {
   // Prevent unnecessary subscriptions for empty IDs
   if (deviceId.trim().isEmpty) {
      print("deviceSensorBlocksStreamProvider: deviceId is empty, returning empty stream.");
      return Stream.value([]); // Return empty stream if no deviceId
   }
   print("deviceSensorBlocksStreamProvider executing for $deviceId");
   final repository = ref.watch(deviceRepositoryProvider);
   return repository.watchDeviceSensorBlocks(deviceId);
});

// --- Authorization Action Providers ---
final addAuthorizedUserProvider = Provider((ref) {
   final repo = ref.watch(deviceRepositoryProvider);
   // No need for current user check here, rules handle ownership on write
   return ({required String deviceId, required String userUidToAdd}) async {
      await repo.addAuthorizedUser(deviceId, userUidToAdd);
      // Invalidate the stream provider for this device's config to update UI
      ref.invalidate(deviceConfigStreamProvider(deviceId));
   };
});

final removeAuthorizedUserProvider = Provider((ref) {
    final repo = ref.watch(deviceRepositoryProvider);
    return ({required String deviceId, required String userUidToRemove}) async {
      await repo.removeAuthorizedUser(deviceId, userUidToRemove);
       // Invalidate the stream provider for this device's config to update UI
       ref.invalidate(deviceConfigStreamProvider(deviceId));
    };
});
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/data/datasources/firestore_datasource.dart'; // Assuming provider defined elsewhere
import 'package:smart_farm_test/data/repositories/history_repository_impl.dart'; // Adjust import
import 'package:smart_farm_test/domain/entities/block_reading.dart'; // Adjust import
import 'package:smart_farm_test/domain/repositories/history_repository.dart'; // Adjust import
import 'package:smart_farm_test/presentation/providers/auth_providers.dart'; // Need auth state? No for repo, yes maybe for actions

// Repository Provider
final historyRepositoryProvider = Provider<IHistoryRepository>((ref) {
   // Depends on FirestoreDataSource provider (defined in auth_providers.dart or elsewhere)
   final firestoreDataSource = ref.watch(firestoreDataSourceProvider);
   return HistoryRepositoryImpl(firestoreDataSource);
});

// Define arguments for the history stream provider
// Using record type for multiple parameters
typedef BlockHistoryArgs = ({String deviceId, String blockId, DateTime? startTime, int limit});

// Stream Provider Family to watch history for a specific block/device/range
final blockHistoryStreamProvider = StreamProvider.autoDispose
    .family<List<BlockReading>, BlockHistoryArgs>((ref, args) {

    if (args.deviceId.isEmpty || args.blockId.isEmpty) {
        print("blockHistoryStreamProvider: Invalid IDs ($args), returning empty stream.");
        return Stream.value([]);
    }

    print("blockHistoryStreamProvider: PROVIDER EXECUTING for ${args.deviceId}/${args.blockId} (Limit: ${args.limit})"); // Log provider execution

    final repository = ref.watch(historyRepositoryProvider);
    final stream = repository.watchBlockHistory(
        args.deviceId, args.blockId, startTime: args.startTime, limit: args.limit,
    );

    // Optional: Add listener here just for debugging stream events within the provider
    // stream.listen(
    //    (data) => print("blockHistoryStreamProvider [${args.deviceId}/${args.blockId}]: Data received - Count: ${data.length}"),
    //    onError: (err) => print("blockHistoryStreamProvider [${args.deviceId}/${args.blockId}]: Error received - $err"),
    //    onDone: () => print("blockHistoryStreamProvider [${args.deviceId}/${args.blockId}]: Stream done."),
    // );

    return stream; // Return the stream from the repository
});
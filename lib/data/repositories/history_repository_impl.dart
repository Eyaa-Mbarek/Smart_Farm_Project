import 'package:smart_farm_test/data/datasources/firestore_datasource.dart'; // Adjust import
import 'package:smart_farm_test/domain/entities/block_reading.dart'; // Adjust import
import 'package:smart_farm_test/domain/repositories/history_repository.dart'; // Adjust import

class HistoryRepositoryImpl implements IHistoryRepository {
   final FirestoreDataSource _dataSource;
   HistoryRepositoryImpl(this._dataSource);

   @override
   @override
 Stream<List<BlockReading>> watchBlockHistory(
    String deviceId,
    String blockId,
    { DateTime? startTime, DateTime? endTime, int? limit }
 ) {
    print("HistoryRepository: Subscribing via datasource for $deviceId/$blockId"); // Log repo call
    return _dataSource.watchBlockReadingsQuery(
       deviceId, blockId, startTime: startTime, endTime: endTime, limit: limit
    ).map((snapshot) {
       print("HistoryRepository: Mapping snapshot for $deviceId/$blockId - Docs: ${snapshot.docs.length}"); // Log mapping start
       // Map query snapshot to list of entities
       final readings = snapshot.docs.map((doc) {
           try {
              // Log data before parsing
              // print("  - Parsing Doc ID: ${doc.id} Data: ${doc.data()}");
              return BlockReading.fromFirestore(doc);
           } catch (e, stack) {
              // Log specific parsing errors
              print("HistoryRepository: ERROR parsing BlockReading ${doc.id} for $deviceId/$blockId: $e\n$stack");
              return null; // Return null on error
           }
       }).whereType<BlockReading>().toList(); // Filter out nulls
       print("HistoryRepository: Mapped to ${readings.length} BlockReading objects for $deviceId/$blockId"); // Log mapping result
       return readings;
    }).handleError((error){ // Catch errors from datasource stream or mapping
       print("HistoryRepository: ERROR in watchBlockHistory stream for $deviceId/$blockId: $error");
       // Emit an empty list or rethrow? Emitting empty list might hide underlying issue.
       // Let's rethrow so the provider handles the error state.
       // return <BlockReading>[];
       throw error;
    });
 }

   @override
   Future<void> addBlockReading(
      String deviceId,
      String blockId,
      double value,
      int type,
      String unit
   ) {
      // Simple pass-through to datasource
      return _dataSource.addBlockReading(deviceId, blockId, value, type, unit);
   }
}
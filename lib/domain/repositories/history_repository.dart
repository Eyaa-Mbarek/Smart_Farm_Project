import 'package:smart_farm_test/domain/entities/block_reading.dart'; // Adjust import

abstract class IHistoryRepository {
  // Get historical readings for a specific block within a time range
  Stream<List<BlockReading>> watchBlockHistory(
      String deviceId,
      String blockId,
      { DateTime? startTime, DateTime? endTime, int? limit }
  );

  // Method for ESP32/App to add a reading (we won't call this from Flutter UI directly for history)
  Future<void> addBlockReading(
      String deviceId,
      String blockId,
      double value,
      int type,
      String unit
  );
}
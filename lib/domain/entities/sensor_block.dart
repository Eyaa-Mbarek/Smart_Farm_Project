import 'package:smart_farm_test/domain/entities/sensor_type.dart';

class SensorBlock {
  final String id; // e.g., "bloc1"
  final String name;
  final SensorType type;
  final double? value;
  final double threshold;
  final String unit;
  final bool enabled;
  final DateTime? lastUpdated;

  SensorBlock({
    required this.id,
    required this.name,
    required this.type,
    this.value,
    required this.threshold,
    required this.unit,
    required this.enabled,
    this.lastUpdated,
  });

   // Helper factory method for parsing from Firebase JSON
  factory SensorBlock.fromJson(String id, Map<String, dynamic> json) {
    final typeInt = json['type'] as int?;
    final type = intToSensorType(typeInt);
    final timestamp = json['lastUpdated'] as int?; // Firebase timestamp is int (ms)

    return SensorBlock(
      id: id,
      name: json['name'] as String? ?? 'Block $id',
      type: type,
      value: (json['value'] as num?)?.toDouble(), // Handles int or double
      threshold: (json['threshold'] as num? ?? 0).toDouble(), // Default 0
      unit: json['unit'] as String? ?? sensorTypeToUnit(type), // Get unit from json or derive
      enabled: json['enabled'] as bool? ?? true, // Default true
      lastUpdated: timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null,
    );
  }

  // Helper method to convert back to JSON for updates (only config fields)
  Map<String, dynamic> toConfigJson() {
    return {
      'name': name,
      'type': sensorTypeToInt(type),
      'threshold': threshold,
      'unit': unit, // Update unit when saving config
      'enabled': enabled,
    };
  }
}
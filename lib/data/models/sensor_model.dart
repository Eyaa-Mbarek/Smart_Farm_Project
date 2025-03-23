// Define a model for the sensor data
import '../../domain/entities/sensor.dart';

class SensorModel {
  final double temperature;
  final double humidity;
  final double pressure;

  SensorModel({
    required this.temperature,
    required this.humidity,
    required this.pressure,
  });

  // Factory method to create a SensorModel from a JSON map
  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      pressure: (json['pressure'] as num).toDouble(),
    );
  }

  // Method to convert SensorModel to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'pressure': pressure,
    };
  }

  // **ADD THIS METHOD:**
  Sensor toEntity() {
    return Sensor(
      temperature: temperature,
      humidity: humidity,
      pressure: pressure,
    );
  }
}
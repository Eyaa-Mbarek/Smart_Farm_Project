// data/datasources/remote_data_source.dart
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

abstract class RemoteDataSource {
  Stream<Map<String, dynamic>> getSensorDataStream();
  Future<Map<String, dynamic>> getSensorData();
  Future<Map<String, dynamic>> getSensorHistoryData(String sensorType, int startTime, int endTime);
}

class FirebaseRemoteDataSource implements RemoteDataSource {
  final FirebaseDatabase database = FirebaseDatabase.instance;

  @override
  Future<Map<String, dynamic>> getSensorData() async {
    DatabaseReference ref = database.ref("sensor_data");
    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    } else {
      throw Exception('No data available at sensor_data');
    }
  }

  @override
  Stream<Map<String, dynamic>> getSensorDataStream() {
    DatabaseReference ref = database.ref("sensor_data");
    return ref.onValue.map((event) {
      if (event.snapshot.exists) {
        final sensorData = Map<String, dynamic>.from(event.snapshot.value as Map);
        _appendSensorHistory(sensorData); // Append the history
        return sensorData;
      } else {
        return {};
      }
    });
  }

  Future<void> _appendSensorHistory(Map<String, dynamic> sensorData) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    DatabaseReference historyRef = database.ref("sensor_history");

    try {
      await historyRef.child('temperature').child(now.toString()).set(sensorData['temperature']);
      await historyRef.child('humidity').child(now.toString()).set(sensorData['humidity']);
      await historyRef.child('pressure').child(now.toString()).set(sensorData['pressure']);
    } catch (e) {
      print("Error appending sensor history: $e"); // Handle errors appropriately
    }
  }

  @override
  Future<Map<String, dynamic>> getSensorHistoryData(String sensorType, int startTime, int endTime) async {
    DatabaseReference historyRef = database.ref('sensor_history/$sensorType');

    final DataSnapshot snapshot = await historyRef
        .orderByKey()
        .startAt(startTime.toString())
        .endAt(endTime.toString())
        .get();

    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    } else {
      return {};
    }
  }
}
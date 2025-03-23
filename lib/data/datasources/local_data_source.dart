//Implement caching data using shared preferences

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


// Abstract class for local data source, can be used for caching.
abstract class LocalDataSource {
  Future<void> cacheSensorData(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getCachedSensorData();
}


class SharedPreferencesLocalDataSource implements LocalDataSource {
  final SharedPreferences sharedPreferences;

  SharedPreferencesLocalDataSource({required this.sharedPreferences});

  
  @override
  Future<void> cacheSensorData(Map<String, dynamic> data) async {
    print("Caching sensor data: $data"); // ADD THIS LINE
    await sharedPreferences.setString('sensor_data', json.encode(data));
  }

  @override
  Future<Map<String, dynamic>?> getCachedSensorData() async {
    final String? cachedData = sharedPreferences.getString('sensor_data');
    if (cachedData != null) {
      return Map<String, dynamic>.from(json.decode(cachedData));
    } else {
      return null;
    }
  }
}


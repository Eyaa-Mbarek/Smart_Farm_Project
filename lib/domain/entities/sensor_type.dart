enum SensorType { temperature, humidity, pressure, luminosity, unknown }

String sensorTypeToUnit(SensorType type) {
  switch (type) {
    case SensorType.temperature: return '°C';
    case SensorType.humidity: return '%';
    case SensorType.pressure: return 'hPa'; // Adjusted from Pa
    case SensorType.luminosity: return 'lux';
    default: return '';
  }
}

int sensorTypeToInt(SensorType type) {
   switch (type) {
    case SensorType.temperature: return 1;
    case SensorType.humidity: return 2;
    case SensorType.pressure: return 3;
    case SensorType.luminosity: return 4;
    default: return 0;
  }
}

 SensorType intToSensorType(int? typeInt) { // Make input nullable
  switch (typeInt) {
    case 1: return SensorType.temperature;
    case 2: return SensorType.humidity;
    case 3: return SensorType.pressure;
    case 4: return SensorType.luminosity;
    default: return SensorType.unknown;
  }
}
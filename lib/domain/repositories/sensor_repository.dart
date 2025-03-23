// Define an abstract repository for sensor data
import 'package:dartz/dartz.dart';
import '../entities/sensor.dart';
import '../../core/errors/failures.dart';

abstract class SensorRepository {
  Future<Either<Failure, Sensor>> getSensorData();
}
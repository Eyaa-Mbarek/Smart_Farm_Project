// Define a use case to get sensor data
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/sensor.dart';
import '../repositories/sensor_repository.dart';

class GetSensorData implements UseCase<Sensor, NoParams> {
  final SensorRepository repository;

  GetSensorData(this.repository);

  @override
  Future<Either<Failure, Sensor>> call(NoParams params) async {
    return await repository.getSensorData();
  }
}
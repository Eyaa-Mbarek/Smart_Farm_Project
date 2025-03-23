// data/repositories/sensor_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/sensor.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../datasources/remote_data_source.dart';
import '../models/sensor_model.dart';
import '../datasources/local_data_source.dart';

class SensorRepositoryImpl implements SensorRepository {
  final RemoteDataSource remoteDataSource;
  final LocalDataSource localDataSource;

  SensorRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  Future<Either<Failure, Sensor>> getSensorData() async {
    try {
      // First, try to get data from the remote data source
      final remoteData = await remoteDataSource.getSensorData();
      final sensorModel = SensorModel.fromJson(remoteData);

      // Cache the data locally
      await localDataSource.cacheSensorData(sensorModel.toJson());

      // Return the sensor data
      return Right(sensorModel.toEntity());
    } catch (remoteError) { // Capture the remote error for debugging
      print('Error fetching from remote data source: $remoteError'); // Print the remote error
      // If remote data source fails, try to get data from the local data source
      try {
        final localData = await localDataSource.getCachedSensorData();
        if (localData != null) {
          final sensorModel = SensorModel.fromJson(localData);
          return Right(sensorModel.toEntity());
        } else {
          return Left(CacheFailure('No data found in cache.'));
        }
      } catch (cacheError) { // Capture the cache error for debugging
        print('Error fetching from local data source: $cacheError'); // Print the cache error
        return Left(ServerFailure('Failed to fetch data from server and cache.'));
      }
    }
  }
}
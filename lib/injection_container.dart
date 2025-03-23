// injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/network_info.dart'; // Correct import path
import 'data/datasources/remote_data_source.dart';
import 'data/datasources/local_data_source.dart';
import 'data/repositories/sensor_repository_impl.dart';
import 'domain/repositories/sensor_repository.dart';
import 'domain/usecases/get_sensor_data.dart';
import 'presentation/bloc/sensor_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Sensor
  // Bloc
  sl.registerFactory(
    () => SensorBloc(getSensorData: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSensorData(sl()));

  // Repository
  sl.registerLazySingleton<SensorRepository>(
    () => SensorRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<RemoteDataSource>(
    () => FirebaseRemoteDataSource(),
  );

  sl.registerLazySingleton<LocalDataSource>(
    () => SharedPreferencesLocalDataSource(sharedPreferences: sl()),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl())); // Using NetworkInfo as a type argument here

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => InternetConnectionChecker.createInstance()); // Use the named constructor
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}
// presentation/bloc/sensor_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/sensor.dart';
import '../../domain/usecases/get_sensor_data.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Define Events
abstract class SensorEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class GetSensorDataEvent extends SensorEvent {}

class SensorDataReceived extends SensorEvent {
  final Sensor sensor;

  SensorDataReceived(this.sensor);

  @override
  List<Object> get props => [sensor];
}

// Define States
abstract class SensorState extends Equatable {
  @override
  List<Object> get props => [];
}

class SensorInitial extends SensorState {}

class SensorLoading extends SensorState {}

class SensorLoaded extends SensorState {
  final Sensor sensor;

  SensorLoaded(this.sensor);

  @override
  List<Object> get props => [sensor];
}

class SensorError extends SensorState {
  final String message;

  SensorError(this.message);

  @override
  List<Object> get props => [message];
}

// Define the BLoC
class SensorBloc extends Bloc<SensorEvent, SensorState> {
  final GetSensorData getSensorData;
  StreamSubscription? _sensorDataSubscription;
  double temperatureThreshold = 0.0;
  double humidityThreshold = 0.0;
  double pressureThreshold = 0.0;
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  SensorBloc({required this.getSensorData}) : super(SensorInitial()) {
    on<GetSensorDataEvent>((event, emit) async {
      emit(SensorLoading());
      final failureOrSensor = await getSensorData(NoParams());
      failureOrSensor.fold(
        (failure) => emit(SensorError(_mapFailureToMessage(failure))),
        (sensor) => emit(SensorLoaded(sensor)),
      );
    });

    on<SensorDataReceived>((event, emit) {
      emit(SensorLoaded(event.sensor));
    });

    _configureLocalNotifications();
    _loadThresholds();

    final remoteDataSource = sl<RemoteDataSource>();

    _sensorDataSubscription = remoteDataSource.getSensorDataStream().listen((data) {
      if (data.isNotEmpty) {
        final sensor = Sensor(
          temperature: (data['temperature'] as num).toDouble(),
          humidity: (data['humidity'] as num).toDouble(),
          pressure: (data['pressure'] as num).toDouble(),
        );

        _checkThresholds(sensor);  // Check thresholds and send notifications

        add(SensorDataReceived(sensor));
      }
    });
  }

  @override
  Future<void> close() {
    _sensorDataSubscription?.cancel();
    return super.close();
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message; // Or a generic server error message
    } else if (failure is CacheFailure) {
      return 'Cache Failure: ' + failure.message; //Or a generic cache error message
    } else {
      return 'Unexpected error';
    }
  }

  //Local Notifications

  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_stat_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground
    );
  }
   @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse notificationResponse) {
    print('notification(${notificationResponse.id}) action tapped: '
        '${notificationResponse.actionId} with'
        'payload: ${notificationResponse.payload}');
    if (notificationResponse.input?.isNotEmpty ?? false) {
      print(
          'notification action tapped with input: ${notificationResponse.input}');
    }
  }

  Future<void> showNotification(String title, String body) async {
    print("showNotification called! Title: $title, Body: $body");  // Add this line

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('your_channel_id', 'Your Channel Name',
            channelDescription: 'To show notifications when a sensor exceed');
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
        0, title, body, notificationDetails);
  }

  //Shared Preferences

  Future<void> _loadThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    temperatureThreshold = prefs.getDouble('temperatureThreshold') ?? 0.0;
    humidityThreshold = prefs.getDouble('humidityThreshold') ?? 0.0;
    pressureThreshold = prefs.getDouble('pressureThreshold') ?? 0.0;
  }

  //Threshold Check

  void _checkThresholds(Sensor sensor) {
  print("_checkThresholds called! Temperature: ${sensor.temperature}, Threshold: $temperatureThreshold, Humidity: ${sensor.humidity}, Threshold: $humidityThreshold, Pressure: ${sensor.pressure}, Threshold: $pressureThreshold");

  if (sensor.temperature > temperatureThreshold) {
    print("Temperature threshold exceeded! Sending notification.");
    showNotification('Temperature Alert', 'Temperature exceeds threshold: ${sensor.temperature} > $temperatureThreshold');
  } else {
    print("Temperature is within the threshold.");
  }

  if (sensor.humidity > humidityThreshold) {
    print("Humidity threshold exceeded! Sending notification.");
    showNotification('Humidity Alert', 'Humidity exceeds threshold: ${sensor.humidity} > $humidityThreshold');
  } else {
    print("Humidity is within the threshold.");
  }

  if (sensor.pressure > pressureThreshold) {
    print("Pressure threshold exceeded! Sending notification.");
    showNotification('Pressure Alert', 'Pressure exceeds threshold: ${sensor.pressure} > $pressureThreshold');
  } else {
    print("Pressure is within the threshold.");
  }
}
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/percent_indicator.dart'; // Add this import

import '../bloc/sensor_bloc.dart';

class SensorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Data')),
      body: BlocBuilder<SensorBloc, SensorState>(
        builder: (context, state) {
          if (state is SensorInitial) {
            return const Center(child: Text('Press the button to load data.'));
          }
          if (state is SensorLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SensorLoaded) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SensorCard(
                    title: 'Temperature',
                    value: state.sensor.temperature,
                    maxValue: 50, // Assumed maximum temperature
                    icon: Icons.thermostat,
                    color: Colors.redAccent,
                    unit: '°C',
                  ),
                  const SizedBox(height: 16),
                  SensorCard(
                    title: 'Humidity',
                    value: state.sensor.humidity,
                    maxValue: 100, // Maximum humidity is 100%
                    icon: Icons.water_drop,
                    color: Colors.blueAccent,
                    unit: '%',
                  ),
                  const SizedBox(height: 16),
                  SensorCard(
                    title: 'Pressure',
                    value: state.sensor.pressure,
                    maxValue: 1100, // Assumed maximum pressure
                    minValue: 900, // Assumed minimum pressure
                    icon: Icons.air,
                    color: Colors.greenAccent,
                    unit: 'hPa',
                  ),
                ],
              ),
            );
          }
          if (state is SensorError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Unknown state.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          BlocProvider.of<SensorBloc>(context).add(GetSensorDataEvent());
          
        } ,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final double value;
  final double maxValue;
  final double? minValue; // Minimum Value of pressure
  final IconData icon;
  final Color color;
  final String unit;

  const SensorCard({
    Key? key,
    required this.title,
    required this.value,
    required this.maxValue,
    this.minValue,
    required this.icon,
    required this.color,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double percentage;
    //Calculating the percentage
    if (minValue != null) {
      percentage = (value - minValue!) / (maxValue - minValue!);
    } else {
      percentage = value / maxValue;
    }
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Row(
            children: [
              Icon(icon, size: 50.0, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CircularPercentIndicator(
                      radius: 60.0,
                      lineWidth: 15.0,
                      percent: percentage,
                      center: Text(
                        "${value.toStringAsFixed(1)} $unit", // Format to 1 decimal place
                        style: const TextStyle( fontSize: 14,
                                                fontWeight: FontWeight.bold
                                              ),
                      ),
                      progressColor: color,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
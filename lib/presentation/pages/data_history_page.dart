// presentation/pages/data_history_page.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_farm_test/injection_container.dart';
import 'package:smart_farm_test/data/datasources/remote_data_source.dart';
import 'package:intl/intl.dart';

class DataHistoryPage extends StatefulWidget {
  const DataHistoryPage({Key? key}) : super(key: key);

  @override
  State<DataHistoryPage> createState() => _DataHistoryPageState();
}

class _DataHistoryPageState extends State<DataHistoryPage> {
  String _selectedSensorType = 'temperature';
  String _selectedPeriod = 'today';
  bool _isLoading = false;
  Map<String, dynamic>? _chartData;

  @override
  void initState() {
    super.initState();
    _loadSensorData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Data History')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Sensor Type',
                              border: InputBorder.none,
                            ),
                            value: _selectedSensorType,
                            items: ['temperature', 'humidity', 'pressure']
                                .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.toUpperCase()),
                                ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSensorType = value!;
                                _loadSensorData();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Period',
                              border: InputBorder.none,
                            ),
                            value: _selectedPeriod,
                            items: ['today', 'last week', 'last month']
                                .map((period) => DropdownMenuItem(
                                  value: period,
                                  child: Text(period.toUpperCase()),
                                ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriod = value!;
                                _loadSensorData();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SensorHistoryChart(
                              sensorType: _selectedSensorType,
                              period: _selectedPeriod,
                              chartData: _chartData,
                              selectedPeriod: _selectedPeriod,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadSensorData() async {
    setState(() {
      _isLoading = true;
      _chartData = null;
    });
    try {
      final now = DateTime.now();
      int startTime;
      int endTime = now.millisecondsSinceEpoch;

      switch (_selectedPeriod) {
        case 'today':
          startTime = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
          break;
        case 'last week':
          startTime = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
          break;
        case 'last month':
          startTime = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
          break;
        default:
          startTime = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
          break;
      }

      final sensorData = await sl<RemoteDataSource>().getSensorHistoryData(_selectedSensorType, startTime, endTime);
      final aggregatedsensorData = await _aggregateData(sensorData, _selectedPeriod);
      setState(() {
        _chartData = aggregatedsensorData;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _aggregateData(Map<String, dynamic> rawData, String period) async {
    Map<String, dynamic> aggregatedData = {};

    Duration interval;
    switch (period) {
      case 'today':
        interval = const Duration(minutes: 30);
        break;
      case 'last week':
        interval = const Duration(hours: 6);
        break;
      case 'last month':
        interval = const Duration(days: 1);
        break;
      default:
        interval = const Duration(minutes: 30);
        break;
    }

    List<MapEntry<String, dynamic>> entries = rawData.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));

    DateTime currentIntervalStart = entries.isNotEmpty
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(entries.first.key))
        : DateTime.now();
    List<double> valuesInInterval = [];

    for (var entry in entries) {
      DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(entry.key));
      double value = (entry.value as num).toDouble();

      if (timestamp.isBefore(currentIntervalStart.add(interval))) {
        valuesInInterval.add(value);
      } else {
        if (valuesInInterval.isNotEmpty) {
          double averageValue = valuesInInterval.reduce((a, b) => a + b) / valuesInInterval.length;
          int averageTimestamp = currentIntervalStart.millisecondsSinceEpoch;
          aggregatedData[averageTimestamp.toString()] = averageValue;
        }

        currentIntervalStart = timestamp;
        valuesInInterval = [value];
      }
    }
    if (valuesInInterval.isNotEmpty) {
          // Average the values in the previous interval
          double averageValue = valuesInInterval.reduce((a, b) => a + b) / valuesInInterval.length;
          int averageTimestamp = currentIntervalStart.millisecondsSinceEpoch;
          aggregatedData[averageTimestamp.toString()] = averageValue;
        }
    return aggregatedData;
  }
}

class SensorHistoryChart extends StatelessWidget {
  final String sensorType;
  final String period;
  final Map<String, dynamic>? chartData;
   final String selectedPeriod;

  const SensorHistoryChart({
    Key? key,
    required this.sensorType,
    required this.period,
    required this.chartData,
     required this.selectedPeriod,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (chartData == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (chartData!.isEmpty) {
      return const Center(child: Text('No data available for the selected period.'));
    } else {
      final List<BarChartGroupData> barGroups = [];

      final List<MapEntry<String, dynamic>> sortedEntries = chartData!.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      for (int i = 0; i < sortedEntries.length; i++) {
        final entry = sortedEntries[i];
        final value = (entry.value as num).toDouble();
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value,
                color: Colors.green,
                width: 8,
              ),
            ],
          ),
        );
      }

      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(chartData!),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value < 0 || value >= sortedEntries.length) {
                    return const Text(''); // Hide titles outside the range
                  }
                  final timestamp = int.parse(sortedEntries[value.toInt()].key);
                  DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
                  final now = DateTime.now();

                  if ( selectedPeriod != 'last month'||selectedPeriod == 'last month' && (date.day % 5 == 0 ||
                      (date.year == now.year && date.month == now.month && date.day == now.day))) {
                     return Text(DateFormat('d').format(date),
                      style: const TextStyle(fontSize: 10));
                  } else {
                    return const Text(''); // Hide other dates
                  }
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true,reservedSize: 28,maxIncluded: false),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          barGroups: barGroups,
        ),
      );
    }
  }

  double _getMaxY(Map<String, dynamic> chartData) {
    double maxY = 0;
    for (var entry in chartData.entries) {
      final value = (entry.value as num).toDouble();
      if (value > maxY) {
        maxY = value;
      }
    }
    return maxY * 1.2; // Add some padding
  }
  // Helper function to build the bottom titles (dates)
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return Text(DateFormat('MMM d').format(date)); // Format date
  }
}
// presentation/pages/data_history_page.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_farm_test/injection_container.dart';
import 'package:smart_farm_test/data/datasources/remote_data_source.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting


class DataHistoryPage extends StatefulWidget {
  const DataHistoryPage({super.key});

  @override
  State<DataHistoryPage> createState() => _DataHistoryPageState();
}

class _DataHistoryPageState extends State<DataHistoryPage> {
  String _selectedSensorType = 'temperature';
  String _selectedPeriod = 'today';
  bool _isLoading = false; // Track loading state
  Map<String, dynamic>? _chartData; // Add the _chartData variable

  @override
  void initState() {
    super.initState();
    // Load initial data
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
                // Dropdowns for Sensor Type and Period
                Card(  // Card around the Dropdown
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
                              border: InputBorder.none,  //Remove the border
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
                                _loadSensorData(); // Reload data when sensor type changes
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Period',
                              border: InputBorder.none,  //Remove the border
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
                                _loadSensorData(); // Reload data when period changes
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // The Graph
                Expanded(
                  child: Card(  //Card Around the Chart
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
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Loading Indicator Overlay
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
      _chartData = null; // Reset chart data while loading
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

    // Determine the interval based on the selected period
    Duration interval;
    switch (period) {
      case 'today':
        interval = const Duration(minutes: 30);  // 30-minute intervals
        break;
      case 'last week':
        interval = const Duration(hours: 6);   // 6-hour intervals
        break;
      case 'last month':
        interval = const Duration(days: 1);     // 1-day intervals
        break;
      default:
        interval = const Duration(minutes: 30);  // Default to 30-minute intervals
        break;
    }

    List<MapEntry<String, dynamic>> entries = rawData.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key)); // Sort by timestamp

    DateTime currentIntervalStart = entries.isNotEmpty
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(entries.first.key))
        : DateTime.now();
    List<double> valuesInInterval = [];

    for (var entry in entries) {
      DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(entry.key));
      double value = (entry.value as num).toDouble();

      if (timestamp.isBefore(currentIntervalStart.add(interval))) {
        // Still within the current interval
        valuesInInterval.add(value);
      } else {
        // Move to the next interval
        if (valuesInInterval.isNotEmpty) {
          // Average the values in the previous interval
          double averageValue = valuesInInterval.reduce((a, b) => a + b) / valuesInInterval.length;
          int averageTimestamp = currentIntervalStart.millisecondsSinceEpoch;
          aggregatedData[averageTimestamp.toString()] = averageValue;
        }

        // Start a new interval
        currentIntervalStart = timestamp;
        valuesInInterval = [value];  // Add the current value to the new interval
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

  const SensorHistoryChart({
    super.key,
    required this.sensorType,
    required this.period,
    required this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    if (chartData == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (chartData!.isEmpty) {
      return const Center(child: Text('No data available for the selected period.'));
    } else {
      // Process the data to build the chart
      final List<FlSpot> data = chartData!.entries.map((entry) {
        final timestamp = int.parse(entry.key);
        final value = (entry.value as num).toDouble();
        return FlSpot(timestamp.toDouble(), value);
      }).toList();

      // Find min and max Y values for chart scaling
      double minY = data.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      double maxY = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

      // Adjust min/max Y to provide some padding in the chart
      double range = maxY - minY;
      minY -= range * 0.1;
      maxY += range * 0.1;

      return LineChart(
        LineChartData(
          minX: data.first.x,
          maxX: data.last.x,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              color: Colors.blue,  // Set line color
              barWidth: 3,   // Set line width
              isStrokeCapRound: true,
              dotData: FlDotData(show: true), // Show data point dots
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: bottomTitleWidgets,
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: true,  //Show Grid
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey, //Horizontal Line Color
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey, //Vertical Line Color
                strokeWidth: 1,
              );
            },),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
        ),
      );
    }
  }

  // Helper function to build the bottom titles (dates)
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return Text(DateFormat('MMM d').format(date)); // Format date
  }
}
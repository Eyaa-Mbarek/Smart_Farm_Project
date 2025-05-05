import 'dart:math'; // Import for Random generation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart'; // Chart library
import 'package:intl/intl.dart'; // Date formatting
import 'package:smart_farm_test/domain/entities/block_reading.dart'; // Data entity for readings
import 'package:smart_farm_test/domain/entities/sensor_block.dart'; // Data entity for current block info
import 'package:smart_farm_test/domain/entities/sensor_type.dart'; // For sensorTypeToInt
import 'package:smart_farm_test/presentation/providers/history_providers.dart'; // Provides history stream
import 'package:smart_farm_test/presentation/providers/device_providers.dart'; // Provides current block stream & device config

// Change to StatefulWidget to manage loading state for generation button & stable start time
class BlockHistoryScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final String blockId;

  // Use super parameters for constructor
  const BlockHistoryScreen({
    super.key,
    required this.deviceId,
    required this.blockId,
  });

  @override
  ConsumerState<BlockHistoryScreen> createState() => _BlockHistoryScreenState();
}

class _BlockHistoryScreenState extends ConsumerState<BlockHistoryScreen> {
  bool _isGenerating = false; // State variable for "Generate History" button loading
  // Store startTime in state to make it stable across builds
  late final DateTime _historyStartTime;

  @override
  void initState() {
    super.initState();
    // Calculate startTime ONCE when the widget is first created
    _historyStartTime = DateTime.now().subtract(const Duration(hours: 24));
    print("BlockHistoryScreen Init: History StartTime = $_historyStartTime");
  }

  // --- Function to Generate and Save Fake Historical Data ---
  Future<void> _generateAndSaveFakeHistory(SensorBlock? currentBlock) async {
    if (_isGenerating) return; // Prevent concurrent execution

    // Need current block info to generate relevant fake data
    if (currentBlock == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Cannot generate history: current block data missing."),
            backgroundColor: Colors.orange));
      }
      return;
    }

    setState(() => _isGenerating = true); // Show loading indicator
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
           content: Text("Generating test history data..."),
           duration: Duration(seconds: 2)));
    }

    // Get repository provider to save data
    final historyRepo = ref.read(historyRepositoryProvider);
    final random = Random();
    final now = DateTime.now();
    final List<Future<void>> saveFutures = []; // To wait for all writes

    const int numberOfPoints = 20; // Number of fake data points
    const int timeStepMinutes = 15; // Interval between points
    // Base value for generation (use current or default)
    final double baseValue = currentBlock.value ?? 20.0;
    // Random variation range
    final double variation = (currentBlock.threshold > 0 ? currentBlock.threshold : baseValue.abs()) * 0.15;

    print("Generating $numberOfPoints fake points for ${widget.deviceId}/${widget.blockId} around value $baseValue +/- $variation");

    // Create fake data points going back in time
    for (int i = 0; i < numberOfPoints; i++) {
      final timestamp = now.subtract(Duration(minutes: i * timeStepMinutes));
      final value = baseValue + (random.nextDouble() * 2 * variation) - variation;

      // Add the save operation Future to the list
      saveFutures.add(historyRepo.addBlockReading(
        widget.deviceId,
        widget.blockId,
        value,
        sensorTypeToInt(currentBlock.type), // Save type associated with this reading
        currentBlock.unit, // Save unit associated with this reading
      ));
    }

    try {
       // Wait for all Firestore writes to complete
       await Future.wait(saveFutures);
       print("Successfully added $numberOfPoints fake history points.");
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Test history data generated! Chart will update."),
              backgroundColor: Colors.green));
       }
    } catch (e) {
       print("Error generating fake history: $e");
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
               content: Text("Error generating history: $e"),
               backgroundColor: Colors.red));
        }
    } finally {
        // Ensure loading state is reset, even on error
        if (mounted) {
          setState(() => _isGenerating = false);
        }
    }
  } // End of _generateAndSaveFakeHistory


  @override
  Widget build(BuildContext context) {
    // --- Watch Providers ---
    // Watch stream for current block list for this device
    final currentBlockStream = ref.watch(deviceSensorBlocksStreamProvider(widget.deviceId));
    // Watch device config (for name)
    final deviceConfigAsync = ref.watch(deviceConfigProvider(widget.deviceId));

    // --- Safely extract current block data ---
    SensorBlock? currentBlock;
    final blockList = currentBlockStream.valueOrNull;
    if (blockList != null) {
       try { currentBlock = blockList.firstWhere((b) => b.id == widget.blockId); } catch (e) { currentBlock = null; }
    }
    // ---

    // --- Get names ---
    final deviceName = deviceConfigAsync.valueOrNull?.deviceName ?? widget.deviceId;
    final blockName = currentBlock?.name ?? widget.blockId;
    // ---

    // --- Define history args using stable start time from state ---
    final historyArgs = (
        deviceId: widget.deviceId,
        blockId: widget.blockId,
        startTime: _historyStartTime, // Use state variable here
        limit: 100
    );
    // --- Watch history stream using stable args ---
    final historyAsync = ref.watch(blockHistoryStreamProvider(historyArgs));
    // --- End Provider Watching ---


    return Scaffold(
      appBar: AppBar(
        title: Text('History: $blockName'),
        // Subtitle-like display using AppBar.bottom
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20.0),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                 'Device: $deviceName',
                 style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
               ),
            ),
        ),
        // Action button to generate test data
        actions: [
          _isGenerating
              ? const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                )
              : IconButton(
                  icon: const Icon(Icons.science_outlined),
                  tooltip: 'Generate Test History Data',
                  onPressed: _isGenerating ? null : () => _generateAndSaveFakeHistory(currentBlock),
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Current Value Card
            _buildCurrentValue(context, currentBlock),
            const SizedBox(height: 24),

            // History Section Title
            Text("Last 24 Hours (Max ${historyArgs.limit} points)", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // Chart Area - Handles loading/error/data for history
            Expanded(
              child: historyAsync.when(
                data: (readings) {
                  print("BlockHistoryScreen: Received data state - Count: ${readings.length}"); // Log data state
                  if (readings.isEmpty) {
                     return const Center(
                        child: Text(
                            "No historical data available.\n(Use AppBar button to generate test data)",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey)
                         )
                      );
                  }
                  // Prepare data for chart (oldest first)
                  final chartData = readings.reversed.toList();
                  // Build and return the chart widget
                  return _buildLineChart(context, chartData, currentBlock?.unit);
                },
                // Show loading indicator while fetching history
                loading: () {
                  print("BlockHistoryScreen: Showing loading state..."); // Log loading state
                  return const Center(child: CircularProgressIndicator());
                },
                // Show error message if fetching fails
                error: (err, stack) {
                   print("BlockHistoryScreen: Received error state - Error: $err"); // Log error state
                   return Center(
                     child: Text("Error loading history: $err", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                   );
                }
              ),
            ),
          ],
        ),
      ),
    );
  } // End of build method

   // --- Widget to display the current value ---
   Widget _buildCurrentValue(BuildContext context, SensorBlock? block) {
       final valueString = block?.value?.toStringAsFixed(1) ?? '--';
       final unitString = block?.unit ?? '';
       final timeString = (block?.lastUpdated != null)
          ? DateFormat('HH:mm:ss').format(block!.lastUpdated!.toLocal())
          : 'N/A';

       return Card(
           elevation: 2,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
           child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Text("Current:", style: Theme.of(context).textTheme.titleMedium),
                    Text(
                       '$valueString $unitString',
                       style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                           color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold
                       )
                    ),
                    Text("(at $timeString)", style: Theme.of(context).textTheme.bodySmall),
                 ],
              ),
           ),
        );
   } // End of _buildCurrentValue


   // --- Widget to build the line chart using fl_chart ---
   Widget _buildLineChart(BuildContext context, List<BlockReading> data, String? unit) {
      if (data.isEmpty) return const SizedBox.shrink();

      // Convert readings to FlSpot list
      final List<FlSpot> spots = data.map((reading) {
          return FlSpot(
              reading.timestamp.millisecondsSinceEpoch.toDouble(),
              reading.value,
          );
       }).toList();

      if (spots.isEmpty) return const Center(child: Text("Not enough data."));

      // --- Calculate Axis Bounds ---
      final double minX = spots.map((s) => s.x).reduce((a, b) => a < b ? a : b);
      final double maxX = spots.map((s) => s.x).reduce((a, b) => a > b ? a : b);
      double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
      double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      final double yRange = maxY - minY;
      final double yPadding = yRange < 1.0 ? 1.0 : yRange * 0.15;
      minY -= yPadding; maxY += yPadding;
      if (maxY <= minY) maxY = minY + 1.0;
      double adjustedMinX = minX; double adjustedMaxX = maxX;
      if (minX == maxX) { adjustedMinX = minX - 300000; adjustedMaxX = maxX + 300000; } // 5 min range if 1 point
      // --- End Axis Calculation ---

      // --- Title Widget Builder Functions ---
      Widget bottomTitleWidgets(double value, TitleMeta meta) {
           if (value != meta.min && value != meta.max && value % meta.appliedInterval > meta.appliedInterval * 0.1) { return Container(); }
           final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(value.toInt());
           return SideTitleWidget( meta: meta, space: 8.0, child: Text(DateFormat('HH:mm').format(dateTime), style: const TextStyle(fontSize: 10)),);
      }
      Widget leftTitleWidgets(double value, TitleMeta meta) {
             return SideTitleWidget( meta: meta, space: 8.0, child: Text(meta.formattedValue, style: const TextStyle(fontSize: 10)),);
      }
      // --- End Title Functions ---

      // --- Build the LineChart ---
      return LineChart(
         LineChartData(
           gridData: FlGridData( show: true, drawVerticalLine: true, drawHorizontalLine: true, getDrawingHorizontalLine: (v) => FlLine(color: Theme.of(context).dividerColor.withAlpha(100), strokeWidth: 0.5), getDrawingVerticalLine: (v) => FlLine(color: Theme.of(context).dividerColor.withAlpha(100), strokeWidth: 0.5),),
           titlesData: FlTitlesData(show: true, rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: bottomTitleWidgets, interval: (adjustedMaxX - adjustedMinX) / 4)), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: leftTitleWidgets)),),
           borderData: FlBorderData(show: true, border: Border.all(color: Theme.of(context).dividerColor, width: 1)),
           minX: adjustedMinX, maxX: adjustedMaxX, minY: minY, maxY: maxY,
           lineBarsData: [ LineChartBarData( spots: spots, isCurved: true, color: Theme.of(context).colorScheme.primary, barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false), belowBarData: BarAreaData( show: true, gradient: LinearGradient( colors: [Theme.of(context).colorScheme.primary.withAlpha(70), Theme.of(context).colorScheme.primary.withAlpha(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter,), ), ), ],
           lineTouchData: LineTouchData( touchTooltipData: LineTouchTooltipData( tooltipRoundedRadius: 8.0, getTooltipItems: (List<LineBarSpot> touchedBarSpots) { return touchedBarSpots.map((barSpot) { final flSpot = barSpot; final dt = DateTime.fromMillisecondsSinceEpoch(flSpot.x.toInt()); final timeStr = DateFormat('MMM d, HH:mm:ss').format(dt); return LineTooltipItem( '${flSpot.y.toStringAsFixed(1)} ${unit ?? ""}\n', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), children: [ TextSpan(text: timeStr, style: TextStyle(color: Colors.grey[200], fontWeight: FontWeight.normal, fontSize: 10,),),], textAlign: TextAlign.left, ); }).toList(); }, ), handleBuiltInTouches: true, getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) { return spotIndexes.map((index) { return TouchedSpotIndicatorData( FlLine(color: Theme.of(context).colorScheme.primary.withOpacity(0.6), strokeWidth: 2), FlDotData( show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter( radius: 5, color: Colors.white, strokeWidth: 2, strokeColor: Theme.of(context).colorScheme.primary, ),), ); }).toList(); }, ),
         ),
         duration: const Duration(milliseconds: 250),
         curve: Curves.easeInOutCubic,
       );
   } // End of _buildLineChart

} // End of _BlockHistoryScreenState
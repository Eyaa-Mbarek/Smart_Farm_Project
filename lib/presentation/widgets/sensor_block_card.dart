import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:smart_farm_test/domain/entities/sensor_block.dart';
import 'package:smart_farm_test/domain/entities/sensor_type.dart';
import 'package:smart_farm_test/presentation/providers/sensor_providers.dart';

class SensorBlockCard extends ConsumerWidget {
  final SensorBlock block;

  const SensorBlockCard({Key? key, required this.block}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valueString = block.value?.toStringAsFixed(1) ?? '--';
    final thresholdString = block.threshold.toStringAsFixed(1);
    // Check if value exists and is greater than threshold
    final isOverThreshold = block.value != null && block.value! > block.threshold;
    final lastUpdatedString = block.lastUpdated != null
        ? DateFormat('MMM d, HH:mm:ss').format(block.lastUpdated!.toLocal())
        : 'Never';

    // Determine card color based on state
    Color cardColor = Colors.white;
    if (!block.enabled) {
        cardColor = Colors.grey.shade300;
    } else if (isOverThreshold) {
        cardColor = Colors.red.shade100;
    }

     // Determine text color for value based on threshold
     Color valueColor = Colors.black;
     if (block.enabled && isOverThreshold) {
         valueColor = Colors.red.shade800;
     }


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: cardColor,
      elevation: block.enabled ? 2 : 0,
      child: InkWell( // Make card tappable
        onTap: () => _showConfigDialog(context, ref, block),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(_getIconForType(block.type), size: 30, color: block.enabled ? Theme.of(context).primaryColor : Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(block.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Threshold: $thresholdString ${block.unit} | Type: ${block.type.name}'),
                    Text('Status: ${block.enabled ? "Enabled" : "Disabled"}'),
                     Text('Last Update: $lastUpdatedString', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 16),
               Text(
                  '$valueString ${block.unit}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(SensorType type) {
    switch (type) {
      case SensorType.temperature: return Icons.thermostat;
      case SensorType.humidity: return Icons.water_drop_outlined;
      case SensorType.pressure: return Icons.speed_outlined; // Changed icon
      case SensorType.luminosity: return Icons.lightbulb_outline;
      default: return Icons.sensors_off_outlined; // Changed icon
    }
  }

  // --- Configuration Dialog ---
  void _showConfigDialog(BuildContext context, WidgetRef ref, SensorBlock currentBlock) {
     final nameController = TextEditingController(text: currentBlock.name);
     final thresholdController = TextEditingController(text: currentBlock.threshold.toStringAsFixed(1)); // Format threshold
     // Use StatefulBuilder to manage the dialog's local state
     SensorType selectedType = currentBlock.type;
     bool isEnabled = currentBlock.enabled;

     showDialog(
        context: context,
        builder: (dialogContext) { // Use a different context name
           return StatefulBuilder( // Manages state within the dialog
              builder: (context, setState) { // setState here updates only the dialog
                 return AlertDialog(
                    title: Text('Configure Block: ${currentBlock.id}'),
                    content: SingleChildScrollView(
                       child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                               controller: nameController,
                               decoration: const InputDecoration(labelText: 'Block Name'),
                            ),
                            const SizedBox(height: 16),
                            const Text("Sensor Type:", style: TextStyle(fontWeight: FontWeight.bold)),
                            DropdownButton<SensorType>(
                               value: selectedType,
                               isExpanded: true, // Make dropdown take full width
                               items: SensorType.values
                                   .where((t) => t != SensorType.unknown) // Exclude unknown
                                   .map((SensorType type) {
                                  return DropdownMenuItem<SensorType>(
                                     value: type,
                                     child: Row( // Add icon to dropdown item
                                        children: [
                                           Icon(_getIconForType(type), size: 20),
                                           const SizedBox(width: 8),
                                           Text(type.name),
                                        ],
                                      )
                                  );
                               }).toList(),
                               onChanged: (SensorType? newValue) {
                                  if (newValue != null) {
                                     setState(() { // Use the setState from StatefulBuilder
                                        selectedType = newValue;
                                        // Update threshold hint text if needed, though unit is set on save
                                     });
                                  }
                               },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                               controller: thresholdController,
                               decoration: InputDecoration(
                                   labelText: 'Threshold Value (${sensorTypeToUnit(selectedType)})' // Dynamic unit hint
                                ),
                               keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                             const SizedBox(height: 16),
                            SwitchListTile(
                                title: const Text("Enable Block"),
                                value: isEnabled,
                                onChanged: (bool value) {
                                    setState(() { // Use the setState from StatefulBuilder
                                        isEnabled = value;
                                    });
                                },
                                 contentPadding: EdgeInsets.zero, // Remove default padding
                            )
                          ],
                       ),
                    ),
                    actions: [
                       TextButton(
                          onPressed: () => Navigator.pop(dialogContext), // Use dialog context
                          child: const Text('Cancel'),
                       ),
                       ElevatedButton( // Make save more prominent
                          onPressed: () async {
                            // Read values from controllers and dialog state
                            final newName = nameController.text;
                            final newThreshold = double.tryParse(thresholdController.text);

                            // Basic Validation
                            if (newName.isEmpty) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Block name cannot be empty.'), backgroundColor: Colors.orange),
                               );
                               return;
                            }
                             if (newThreshold == null) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invalid threshold value entered.'), backgroundColor: Colors.orange),
                               );
                               return;
                            }

                            // Show loading indicator maybe?
                            try {
                                // Access the update function via ref.read
                                await ref.read(updateSensorConfigProvider)(
                                    blockId: currentBlock.id,
                                    name: newName,
                                    type: selectedType,
                                    threshold: newThreshold,
                                    enabled: isEnabled,
                                );
                                Navigator.pop(dialogContext); // Close dialog on success
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${currentBlock.id} configuration saved!'), backgroundColor: Colors.green),
                                );
                            } catch (e) {
                               print("Error saving config: $e");
                               Navigator.pop(dialogContext); // Close dialog even on error
                               ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error saving configuration: $e'), backgroundColor: Colors.red),
                               );
                            }
                          },
                          child: const Text('Save'),
                       ),
                    ],
                 );
              }
           );
        },
     );
  }
}
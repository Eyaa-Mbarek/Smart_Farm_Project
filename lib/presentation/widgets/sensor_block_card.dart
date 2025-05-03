import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/sensor_type.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/device_providers.dart'; // Use device providers
import 'package:smart_farm_test/presentation/screens/home/home_screen.dart'; // Import for selectedDeviceIdProvider

class SensorBlockCard extends ConsumerWidget {
  final SensorBlock block;
  // No longer needs deviceId passed directly, reads from selectedDeviceIdProvider

  const SensorBlockCard({
      Key? key,
      required this.block,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calculate display values and states
    final valueString = block.value?.toStringAsFixed(1) ?? '--';
    final thresholdString = block.threshold.toStringAsFixed(1);
    final isOverThreshold = block.value != null && block.threshold != 0 && block.value! > block.threshold; // Check threshold != 0?
    final lastUpdatedString = block.lastUpdated != null
        ? DateFormat('MMM d, HH:mm:ss').format(block.lastUpdated!.toLocal())
        : 'Never';

    // Determine card appearance based on state
    Color cardColor = Theme.of(context).colorScheme.surface;
    Color? shadowColor = Colors.grey.withOpacity(0.3);
    if (!block.enabled) {
        cardColor = Colors.grey.shade300;
        shadowColor = Colors.transparent;
    } else if (isOverThreshold) {
        cardColor = Colors.red.shade50; // Softer alert color
    }

     // Determine value text color
     Color valueColor = Theme.of(context).colorScheme.onSurface;
     if (block.enabled && isOverThreshold) {
         valueColor = Colors.red.shade800;
     }

    // Build the Card widget
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      clipBehavior: Clip.antiAlias, // Ensures InkWell splash stays within bounds
      color: cardColor,
      elevation: block.enabled ? 2 : 0.5,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
         // Show config dialog on tap
        onTap: () => _showConfigDialog(context, ref, block),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
             children: [
               // Sensor Icon
               Icon(
                   _getIconForType(block.type),
                   size: 28,
                   color: block.enabled ? Theme.of(context).colorScheme.primary : Colors.grey.shade600
               ),
               const SizedBox(width: 12),
               // Block Name and Details
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(block.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                     const SizedBox(height: 4),
                     Text(
                         'Thr: $thresholdString ${block.unit} | Type: ${block.type.name}${block.enabled ? '' : ' (Disabled)'}',
                         style: Theme.of(context).textTheme.bodySmall,
                         overflow: TextOverflow.ellipsis,
                     ),
                     Text(
                         'Updated: $lastUpdatedString',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)
                      ),
                   ],
                 ),
               ),
               const SizedBox(width: 10),
                // Value Display
                Padding(
                  padding: const EdgeInsets.only(right: 4.0), // Add slight right padding
                  child: Text(
                     '$valueString ${block.unit}',
                     style: TextStyle(
                       fontSize: 22,
                       fontWeight: FontWeight.bold,
                       color: valueColor,
                     ),
                   ),
                ),
             ],
           ),
         ),
       ),
     );
   }

  // Helper function to get icon based on sensor type
  IconData _getIconForType(SensorType type) {
     return switch (type) {
        SensorType.temperature => Icons.thermostat,
        SensorType.humidity => Icons.water_drop_outlined,
        SensorType.pressure => Icons.speed_outlined,
        SensorType.luminosity => Icons.lightbulb_outline,
        _ => Icons.sensors_off_outlined, // Default for unknown
     };
  }

  // --- Configuration Dialog Method ---
  void _showConfigDialog(BuildContext context, WidgetRef ref, SensorBlock currentBlock) {
      // Controllers for text fields
      final nameController = TextEditingController(text: currentBlock.name);
      final thresholdController = TextEditingController(text: currentBlock.threshold.toStringAsFixed(1));
      final unitController = TextEditingController(text: currentBlock.unit);

      // State variables for dropdown and switch (managed by StatefulBuilder)
      SensorType selectedType = currentBlock.type;
      bool isEnabled = currentBlock.enabled;

      // Get the currently selected deviceId from the state provider
       final String? deviceId = ref.read(selectedDeviceIdProvider);
       if (deviceId == null || deviceId.isEmpty) {
          // Show error if no device is selected (shouldn't happen if card is visible)
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Error: No device selected.'), backgroundColor: Colors.red)
          );
          return;
       }

      // Show the actual dialog
      showDialog(
          context: context,
          builder: (dialogContext) {
            // Use StatefulBuilder to manage state changes within the dialog UI
            return StatefulBuilder(
               builder: (context, setStateDialog) { // Use setStateDialog to update dialog
                 return AlertDialog(
                     // Include block and device IDs in the title for clarity
                     title: Text('Configure: ${currentBlock.id} ($deviceId)'),
                     content: SingleChildScrollView(
                        child: Column(
                           mainAxisSize: MainAxisSize.min,
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             // Block Name Field
                             TextField(
                                controller: nameController,
                                decoration: const InputDecoration(labelText: 'Block Name', border: OutlineInputBorder()),
                             ),
                             const SizedBox(height: 16),
                             // Sensor Type Dropdown
                             DropdownButtonFormField<SensorType>(
                                value: selectedType,
                                decoration: const InputDecoration(labelText: 'Sensor Type', border: OutlineInputBorder()),
                                items: SensorType.values
                                    .where((t) => t != SensorType.unknown) // Exclude 'unknown' type
                                    .map((SensorType type) {
                                   return DropdownMenuItem<SensorType>(
                                      value: type,
                                      child: Row(children: [ Icon(_getIconForType(type), size: 20), const SizedBox(width: 8), Text(type.name)])
                                   );
                                }).toList(),
                                onChanged: (SensorType? newValue) {
                                   if (newValue != null) {
                                      // Update state within the dialog
                                      setStateDialog(() {
                                         selectedType = newValue;
                                         // Auto-update unit field when type changes
                                         unitController.text = sensorTypeToUnit(selectedType);
                                      });
                                   }
                                },
                             ),
                             const SizedBox(height: 16),
                             // Threshold and Unit Fields (side-by-side)
                             Row(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                   // Threshold Field
                                   Expanded(
                                     flex: 2, // Give threshold more space
                                     child: TextField(
                                        controller: thresholdController,
                                        decoration: InputDecoration(
                                            labelText: 'Threshold',
                                            border: const OutlineInputBorder(),
                                            // Show current unit as suffix
                                            suffixText: unitController.text.isNotEmpty ? unitController.text : null,
                                         ),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      ),
                                   ),
                                   const SizedBox(width: 8),
                                    // Unit Field
                                    Expanded(
                                      flex: 1,
                                      child: TextField(
                                         controller: unitController,
                                         decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                                         // Update the threshold suffix when unit changes
                                         onChanged: (_) => setStateDialog((){}),
                                       ),
                                    ),
                               ],
                             ),
                              const SizedBox(height: 10),
                              // Enabled Switch
                             SwitchListTile(
                                 title: const Text("Enable Block"),
                                 value: isEnabled,
                                 onChanged: (bool value) {
                                     // Update state within the dialog
                                     setStateDialog(() { isEnabled = value; });
                                 },
                                  contentPadding: EdgeInsets.zero, // Adjust padding
                                  dense: true,
                             )
                           ],
                         ),
                     ),
                     // Dialog Actions (Cancel, Save)
                     actions: <Widget>[
                        TextButton(
                           onPressed: () => Navigator.pop(dialogContext), // Close dialog
                           child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                           onPressed: () async {
                              // --- Save Logic ---
                              final newName = nameController.text.trim();
                              final newThreshold = double.tryParse(thresholdController.text.trim());
                              final newUnit = unitController.text.trim();

                              // Basic Validation
                              if (newName.isEmpty || newThreshold == null || newUnit.isEmpty) {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please fill all fields correctly.'), backgroundColor: Colors.orange),
                                 );
                                 return; // Don't proceed if invalid
                              }

                              try {
                                 // Read the device repository provider
                                 final deviceRepo = ref.read(deviceRepositoryProvider);
                                 // Construct the map of updates for RTDB
                                 final updates = {
                                    'name': newName,
                                    'type': sensorTypeToInt(selectedType),
                                    'threshold': newThreshold,
                                    'unit': newUnit,
                                    'enabled': isEnabled,
                                    // Optionally update 'lastUpdated' here? Or let ESP handle it.
                                 };
                                 // Call the repository method to update the specific block config in RTDB
                                 await deviceRepo.updateDeviceBlockConfig(deviceId, currentBlock.id, updates);

                                 // Close the dialog on success
                                 if (Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
                                 // Show success message
                                  if (context.mounted){ // Check context before showing SnackBar
                                      ScaffoldMessenger.of(context).showSnackBar(
                                         SnackBar(content: Text('${currentBlock.id} on $deviceId config saved!'), backgroundColor: Colors.green),
                                      );
                                  }
                              } catch (e) {
                                  print("Error saving block config: $e");
                                  // Close the dialog even on error
                                  if (Navigator.canPop(dialogContext)) Navigator.pop(dialogContext);
                                  // Show error message
                                   if (context.mounted) { // Check context
                                      ScaffoldMessenger.of(context).showSnackBar(
                                         SnackBar(content: Text('Error saving configuration: $e'), backgroundColor: Colors.red),
                                      );
                                   }
                              }
                           },
                           child: const Text('Save Config'),
                        ),
                     ],
                  );
               }
            );
         },
      );
   } // End of _showConfigDialog

} // End of SensorBlockCard
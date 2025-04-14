import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart';
import 'package:smart_farm_test/domain/entities/sensor_type.dart';
import 'package:smart_farm_test/presentation/providers/sensor_providers.dart';
import 'package:smart_farm_test/presentation/providers/monitored_blocks_provider.dart'; // Import provider

class SensorBlockCard extends ConsumerWidget {
  final SensorBlock block;

  const SensorBlockCard({Key? key, required this.block}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // (Keep existing build logic for card appearance)
    final valueString = block.value?.toStringAsFixed(1) ?? '--';
    final thresholdString = block.threshold.toStringAsFixed(1);
    final isOverThreshold = block.value != null && block.value! > block.threshold;
    final lastUpdatedString = block.lastUpdated != null
        ? DateFormat('MMM d, HH:mm:ss').format(block.lastUpdated!.toLocal())
        : 'Never';

    Color cardColor = Theme.of(context).colorScheme.surface; // Use theme color
    Color? shadowColor = Colors.grey.withOpacity(0.3);
    if (!block.enabled) {
        cardColor = Colors.grey.shade300;
        shadowColor = Colors.transparent;
    } else if (isOverThreshold) {
        cardColor = Colors.red.shade50; // Softer red
    }

     Color valueColor = Theme.of(context).colorScheme.onSurface; // Use theme color
     if (block.enabled && isOverThreshold) {
         valueColor = Colors.red.shade800;
     }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12), // Slightly reduced margin
      clipBehavior: Clip.antiAlias,
      color: cardColor,
      elevation: block.enabled ? 2 : 0.5, // Reduced elevation for disabled
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      child: InkWell(
        onTap: () => _showConfigDialog(context, ref, block),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 10, bottom: 10, right: 4), // Adjust padding
          child: Row(
             children: [
               // --- Hide Button ---
               IconButton(
                   icon: Icon(Icons.visibility_off_outlined, color: Colors.grey.shade600, size: 20),
                   tooltip: 'Hide this block',
                   onPressed: () => _confirmAndHide(context, ref, block.id),
                   padding: EdgeInsets.zero,
                   constraints: const BoxConstraints(), // Remove default padding
                ),
               const SizedBox(width: 8),
               Icon(_getIconForType(block.type), size: 28, color: block.enabled ? Theme.of(context).colorScheme.primary : Colors.grey),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(block.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                Padding( // Add padding to value
                  padding: const EdgeInsets.only(right: 8.0),
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

  IconData _getIconForType(SensorType type) {
     // (Keep existing icon logic)
     return switch (type) {
        SensorType.temperature => Icons.thermostat,
        SensorType.humidity => Icons.water_drop_outlined,
        SensorType.pressure => Icons.speed_outlined,
        SensorType.luminosity => Icons.lightbulb_outline,
        _ => Icons.sensors_off_outlined,
     };
  }

  // --- Configuration Dialog ---
  void _showConfigDialog(BuildContext context, WidgetRef ref, SensorBlock currentBlock) {
     // (Keep existing dialog logic for Name, Type, Threshold, Unit, Enabled)
     // --- REMOVE THE FIREBASE DELETE BUTTON ---
       final nameController = TextEditingController(text: currentBlock.name);
       final thresholdController = TextEditingController(text: currentBlock.threshold.toStringAsFixed(1));
       final unitController = TextEditingController(text: currentBlock.unit);
       SensorType selectedType = currentBlock.type;
       bool isEnabled = currentBlock.enabled;

       showDialog( /* ... rest of the dialog setup ... */
          context: context,
          builder: (dialogContext) {
             return StatefulBuilder(
                builder: (context, setState) {
                   return AlertDialog(
                      title: Text('Configure: ${currentBlock.id}'),
                      content: SingleChildScrollView( /* ... Fields as before ... */
                         child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Block Name', border: OutlineInputBorder())),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<SensorType>( /* ... Type Dropdown ... */
                              value: selectedType,
                              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Sensor Type'),
                              items: SensorType.values.where((t) => t != SensorType.unknown).map((SensorType type) {
                                return DropdownMenuItem<SensorType>(value: type, child: Row(children: [ Icon(_getIconForType(type), size: 20), const SizedBox(width: 8), Text(type.name)]));
                              }).toList(),
                              onChanged: (SensorType? newValue) { if (newValue != null) setState(() { selectedType = newValue; unitController.text = sensorTypeToUnit(selectedType); });},
                            ),
                            const SizedBox(height: 16),
                            Row( /* ... Threshold and Unit Fields ... */
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Expanded(flex: 2, child: TextField(controller: thresholdController, decoration: InputDecoration(labelText: 'Threshold', border: const OutlineInputBorder(), suffixText: unitController.text), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                                  const SizedBox(width: 8),
                                  Expanded(flex: 1, child: TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()), onChanged: (_) => setState((){}))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile(title: const Text("Enable Block"), value: isEnabled, onChanged: (bool value) { setState(() { isEnabled = value; }); }, contentPadding: EdgeInsets.zero, dense: true)
                          ],
                        ),
                      ),
                      actions: <Widget>[
                          // --- REMOVED DELETE BUTTON ---
                         TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                         ElevatedButton(
                            onPressed: () async {
                              // (Keep existing save logic - using updateSensorConfigProvider)
                                final newName = nameController.text;
                                final newThreshold = double.tryParse(thresholdController.text);
                                final newUnit = unitController.text;
                                if (newName.isEmpty || newThreshold == null || newUnit.isEmpty) { /*... validation ...*/ return; }
                                try {
                                    await ref.read(updateSensorConfigProvider)( blockId: currentBlock.id, name: newName, type: selectedType, threshold: newThreshold, unit: newUnit, enabled: isEnabled);
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${currentBlock.id} saved!'), backgroundColor: Colors.green));
                                } catch (e) { /* ... error handling ... */ }
                            },
                            child: const Text('Save Config'),
                         ),
                      ],
                   );
                }
             );
          },
       );
   }

  // --- Confirmation Dialog for HIDING ---
  void _confirmAndHide(BuildContext context, WidgetRef ref, String blockId) {
     showDialog(
        context: context,
        builder: (BuildContext dialogContext) { // Use different context name
           return AlertDialog(
              title: const Text('Hide Block'),
              content: Text('Stop showing block "$blockId" on the dashboard? You can add it back later using the "+" button.'),
              actions: <Widget>[
                 TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(), // Close confirmation dialog
                    child: const Text('Cancel'),
                 ),
                 TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800), // Use orange for hide
                    onPressed: () async {
                        // Use the provider to remove the block from the monitored list
                        await ref.read(monitoredBlockIdsProvider.notifier).removeMonitoredBlock(blockId);
                        Navigator.of(dialogContext).pop(); // Close confirmation dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Block $blockId hidden.'), duration: const Duration(seconds: 2)),
                        );
                    },
                    child: const Text('Hide'),
                 ),
              ],
           );
        },
     );
  }
}
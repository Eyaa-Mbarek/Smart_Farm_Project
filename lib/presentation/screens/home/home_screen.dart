
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/user_profile.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/auth_providers.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/user_providers.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/device_providers.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/threshold_alert_provider.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/visible_blocks_provider.dart'; // Import NEW provider
import 'package:smart_farm_test/presentation/providers/filtered_blocks_provider.dart'; // Import NEW provider
import 'package:smart_farm_test/presentation/widgets/sensor_block_card.dart'; // Adjust import path
// Import DeviceConfig if needed for type hints
// import 'package:smart_farm_test/domain/entities/device_config.dart';

// State for the currently selected device ID shown on the HomeScreen
final selectedDeviceIdProvider = StateProvider<String?>((ref) => null);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final selectedDeviceId = ref.watch(selectedDeviceIdProvider);

    // --- Set initial device selection based on profile load ---
    ref.listen<UserProfile?>(userProfileProvider.select((asyncValue) => asyncValue.valueOrNull), (prevProfile, nextProfile) {
       // If selection is still null and profile loaded with devices, set the first one
       if (ref.read(selectedDeviceIdProvider) == null && nextProfile != null && nextProfile.monitoredDevices.isNotEmpty) {
           print("HomeScreen Listener: Setting initial device to ${nextProfile.monitoredDevices.first}");
           // Use notifier to update state provider
           ref.read(selectedDeviceIdProvider.notifier).state = nextProfile.monitoredDevices.first;
       } else if (nextProfile != null && selectedDeviceId != null && !nextProfile.monitoredDevices.contains(selectedDeviceId)) {
           // If the currently selected device was removed from monitored list, reset selection
           print("HomeScreen Listener: Selected device $selectedDeviceId removed from monitored list. Resetting.");
           ref.read(selectedDeviceIdProvider.notifier).state = nextProfile.monitoredDevices.isNotEmpty ? nextProfile.monitoredDevices.first : null;
       }
    });

    // --- Activate threshold listener for the *currently selected* device ---
    if (selectedDeviceId != null && selectedDeviceId.isNotEmpty) {
      ref.watch(deviceThresholdAlertProvider(selectedDeviceId));
    }
    // ---

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        // Add Device Button moved to actions
        actions: [
            IconButton(
               icon: const Icon(Icons.add_box_outlined),
               tooltip: 'Add/Register Device',
               onPressed: () => _showAddDeviceDialog(context, ref),
            ),
        ],
         bottom: userProfileAsync.maybeWhen(
            data: (profile) => _buildDeviceSelector(context, ref, profile),
            orElse: () => null,
         ),
      ),
      body: userProfileAsync.when(
        data: (userProfile) {
          if (userProfile == null) return const Center(child: Text('Please log in.'));

          // Handle states: No monitored devices, or no device selected
          if (userProfile.monitoredDevices.isEmpty) return _buildNoMonitoredDeviceUI(context, ref);
          if (selectedDeviceId == null || selectedDeviceId.isEmpty) return const Center(child: CircularProgressIndicator()); // Or 'Select Device' prompt

          // --- Display Filtered Blocks for Selected Device ---
          // Watch the *filtered* blocks provider for the selected device
          final filteredBlocksAsync = ref.watch(filteredDeviceBlocksProvider(selectedDeviceId));

          return filteredBlocksAsync.when(
             data: (blocks) {
                 if (blocks.isEmpty) {
                     // Could be no blocks configured OR no blocks are set to visible locally
                      return Center(
                         child: Padding(
                           padding: const EdgeInsets.all(20.0),
                           child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                 Text(
                                     'No sensor blocks visible for device "$selectedDeviceId".\nUse the "eye" button to manage block visibility.',
                                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                                 const SizedBox(height: 10),
                                 // Optionally show raw block count if needed for debug
                                  Consumer(builder: (context, ref, _) {
                                     final rawCount = ref.watch(deviceSensorBlocksStreamProvider(selectedDeviceId)).valueOrNull?.length ?? 0;
                                     return Text("(Total blocks from device: $rawCount)", style: Theme.of(context).textTheme.bodySmall);
                                  }),
                              ],
                            ),
                         )
                     );
                 }
                 // Display the list of filtered blocks
                  return RefreshIndicator(
                     onRefresh: () async {
                         ref.invalidate(deviceSensorBlocksStreamProvider(selectedDeviceId));
                         ref.invalidate(filteredDeviceBlocksProvider(selectedDeviceId));
                         ref.invalidate(visibleBlocksProvider(selectedDeviceId)); // Reload local state too
                         ref.invalidate(deviceConfigProvider(selectedDeviceId));
                     },
                     child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: blocks.length,
                        itemBuilder: (context, index) => SensorBlockCard(block: blocks[index]),
                     ),
                   );
             },
             loading: () => const Center(child: CircularProgressIndicator()), // Loading filtered blocks
             error: (err, stack) => Center(child: Text('Error loading sensor blocks: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()), // Loading user profile
        error: (err, stack) => Center(child: Text('Error loading user profile: $err')),
      ),
       // --- FAB for Managing Block Visibility ---
       floatingActionButton: selectedDeviceId != null && selectedDeviceId.isNotEmpty // Only show if a device is selected
           ? FloatingActionButton.extended(
              onPressed: () => _showManageBlocksDialog(context, ref, selectedDeviceId),
              tooltip: 'Manage Visible Blocks',
              icon: const Icon(Icons.visibility_outlined),
              label: const Text("Blocks"),
            )
           : null, // No FAB if no device selected
    );
  } // End of build method


  // --- UI Helper for No Monitored Devices ---
  Widget _buildNoMonitoredDeviceUI(BuildContext context, WidgetRef ref) {
     return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                const Text( 'No devices are being monitored.\nAdd a device using the "+" button in the AppBar.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                   onPressed: () => _showAddDeviceDialog(context, ref),
                   icon: const Icon(Icons.add_circle_outline),
                   label: const Text('Add Device'),
                )
             ],
           ),
        )
     );
  }


  // --- Device Selector Dropdown Builder ---
  PreferredSizeWidget? _buildDeviceSelector(BuildContext context, WidgetRef ref, UserProfile? profile) {
     // ... (Keep the exact same logic as provided in the previous response) ...
       if (profile == null || profile.monitoredDevices.isEmpty) return null;
       final selectedDeviceId = ref.watch(selectedDeviceIdProvider);
       final List<String> monitoredDevices = profile.monitoredDevices;
       final String currentSelection;
       // ... (Logic to determine currentSelection and call setState if needed) ...
        if (selectedDeviceId != null && monitoredDevices.contains(selectedDeviceId)) { currentSelection = selectedDeviceId; }
        else if (monitoredDevices.isNotEmpty) { currentSelection = monitoredDevices.first; WidgetsBinding.instance.addPostFrameCallback((_){ if (ref.read(selectedDeviceIdProvider) != currentSelection && monitoredDevices.contains(currentSelection)) { ref.read(selectedDeviceIdProvider.notifier).state = currentSelection; } }); }
        else { return null; }

       return PreferredSize(
         preferredSize: const Size.fromHeight(50.0),
         child: Container( /* ... DropdownButton logic using deviceConfigProvider ... */
             color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
             alignment: Alignment.centerLeft,
             child: DropdownButtonHideUnderline(
               child: DropdownButton<String>(
                  value: currentSelection, isExpanded: true, icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onChanged: (String? newValue) { if (newValue != null) ref.read(selectedDeviceIdProvider.notifier).state = newValue; },
                  items: monitoredDevices.map<DropdownMenuItem<String>>((String deviceId) {
                     final deviceConfigAsync = ref.watch(deviceConfigProvider(deviceId));
                     return DropdownMenuItem<String>(value: deviceId, child: Text( deviceConfigAsync.when(data: (c) => c?.deviceName ?? deviceId, loading: () => '$deviceId (L...)', error: (e,s)=>'$deviceId (E)'), overflow: TextOverflow.ellipsis));
                  }).toList(),
               ),
             ),
          ),
       );
   }


  // --- Add/Register Device Dialog Logic ---
// --- Dialog to Add/Register a New Device ID ---
   void _showAddDeviceDialog(BuildContext context, WidgetRef ref) {
      final deviceIdController = TextEditingController();
      final deviceNameController = TextEditingController(); // For owner setting name when registering
      final formKey = GlobalKey<FormState>();

      showDialog(
         context: context,
         // Use StatefulBuilder to manage the loading state within the dialog
         builder: (BuildContext dialogContext) {
            // Use a local state variable for loading within the dialog
            bool isLoading = false;
            return StatefulBuilder(
              builder: (context, setStateDialog) { // Use setStateDialog to update dialog state
                return AlertDialog(
                   title: const Text('Add Device by ID'),
                   content: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Prevent dialog stretching
                        children: [
                          TextFormField(
                            controller: deviceIdController,
                             decoration: const InputDecoration(labelText: 'Device ID', hintText: 'e.g., esp32_main', border: OutlineInputBorder()),
                             validator: (value) => (value == null || value.trim().isEmpty) ? 'Device ID cannot be empty' : null,
                          ),
                          const SizedBox(height: 16),
                          // Only show name field if potentially registering
                           TextFormField(
                              controller: deviceNameController,
                              decoration: const InputDecoration(labelText: 'Device Name', hintText: 'e.g., Main Farm (if new)', border: OutlineInputBorder()),
                              // No validator needed for optional field
                            ),
                            const SizedBox(height: 16),
                            // Show loading indicator if processing
                            if (isLoading) const Padding(padding: EdgeInsets.only(top: 10), child: CircularProgressIndicator()),
                        ],
                      ),
                   ),
                   actions: <Widget>[
                      // Cancel button
                      TextButton(
                         onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                         child: const Text('Cancel'),
                      ),
                      // Add button
                      ElevatedButton(
                         // Disable button while loading
                         onPressed: isLoading ? null : () async {
                            if (formKey.currentState!.validate()) {
                                // Set loading state within dialog
                                setStateDialog(() => isLoading = true);
                                final deviceId = deviceIdController.text.trim();
                                final deviceName = deviceNameController.text.trim();
                                // Call the handler function (defined below)
                                await _handleDeviceAddition(
                                    context, // Pass original context for ScaffoldMessenger
                                    ref,
                                    deviceId,
                                    deviceName.isEmpty ? null : deviceName
                                );
                                // Close dialog if successful or on error (handled in _handleDeviceAddition)
                                // Check if dialog's context is still valid before popping
                                if (Navigator.of(dialogContext).canPop()) {
                                   Navigator.pop(dialogContext);
                                }
                                // No need to reset isLoading here as dialog closes
                            }
                         },
                         child: const Text('Check & Add'),
                      ),
                   ],
                );
              }
            );
         },
      );
   }

Future<void> _handleDeviceAddition(BuildContext context, WidgetRef ref, String deviceId, String? deviceName) async {
        final user = ref.read(authStateProvider).value;
        if (user == null) {
           print("Error: User not logged in for device addition.");
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not logged in.'), backgroundColor: Colors.red));
           return;
        }

        final deviceRepo = ref.read(deviceRepositoryProvider);
        final userRepo = ref.read(userRepositoryProvider);

        try {
            print("Checking existence of device config: $deviceId");
            final configExists = await deviceRepo.deviceConfigExists(deviceId);

            if (!configExists) {
                // --- Device does NOT exist in Firestore config -> Register it ---
                print("Registering new device: $deviceId for user ${user.uid}");
                final nameToSet = deviceName ?? 'Device $deviceId'; // Use provided name or default

                // 1. Create device config in Firestore
                await deviceRepo.createDeviceConfig(deviceId, user.uid, nameToSet);
                // 2. Add device to user's 'ownedDevices' list
                await userRepo.addDeviceToOwned(user.uid, deviceId);
                // 3. Add device to user's 'monitoredDevices' list
                await userRepo.addDeviceToMonitored(user.uid, deviceId);
                // 4. Select the newly added device
                ref.read(selectedDeviceIdProvider.notifier).state = deviceId;

                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Device "$nameToSet" registered and added!'), backgroundColor: Colors.green),
                   );
                }

            } else {
                // --- Device EXISTS in Firestore config -> Check authorization ---
                print("Device $deviceId already exists. Checking authorization...");
                final deviceConfig = await deviceRepo.getDeviceConfig(deviceId);

                if (deviceConfig == null) {
                    throw Exception("Device config not found despite existing check.");
                }

                // Check if current user is owner or in authorized list
                if (deviceConfig.ownerUid == user.uid || deviceConfig.authorizedUsers.contains(user.uid)) {
                    print("User ${user.uid} authorized for device $deviceId.");
                    // User has access, add to their monitored list if not already there
                    final profile = await userRepo.getUserProfile(user.uid); // Get current profile
                    if (!profile.monitoredDevices.contains(deviceId)) {
                        await userRepo.addDeviceToMonitored(user.uid, deviceId);
                    }
                    // Add to accessibleDevices map if not the owner
                    if (deviceConfig.ownerUid != user.uid && !profile.accessibleDevices.containsKey(deviceId)) {
                        await userRepo.addDeviceToAccessible(user.uid, deviceId, deviceConfig.ownerUid);
                    }
                    // Select the device
                    ref.read(selectedDeviceIdProvider.notifier).state = deviceId;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added existing device "${deviceConfig.deviceName}" to your dashboard.'), backgroundColor: Colors.blue),
                      );
                    }
                } else {
                    // --- User NOT authorized ---
                    print("User ${user.uid} NOT authorized for device $deviceId. Owner: ${deviceConfig.ownerUid}");
                     if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Permission denied for device $deviceId. Ask the owner for access.'), duration: Duration(seconds: 4), backgroundColor: Colors.orange),
                       );
                    }
                }
            }

        } catch (e, stackTrace) {
            print("Error handling device addition: $e\n$stackTrace");
             if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Error adding device: $e'), backgroundColor: Colors.red),
               );
             }
        }
    }

   // --- NEW Dialog to Manage Visible Blocks ---
   void _showManageBlocksDialog(BuildContext context, WidgetRef ref, String deviceId) {
      // Watch ALL blocks for this device from RTDB (source of truth for what *can* be shown)
      final allBlocksAsync = ref.watch(deviceSensorBlocksStreamProvider(deviceId));
      // Note: We don't watch visibleBlocksProvider here directly, StatefulBuilder will read it

      showDialog(
         context: context,
         builder: (BuildContext dialogContext) {
            return AlertDialog(
               title: Text('Manage Visible Blocks ($deviceId)'),
               content: SizedBox( // Constrain height for scrollable list
                  width: double.maxFinite,
                  child: allBlocksAsync.when(
                      data: (allBlocks) {
                         if (allBlocks.isEmpty) return const Center(child: Text("No blocks found for this device."));

                         // Use StatefulBuilder to manage checkbox state within the dialog
                         return StatefulBuilder(
                           builder: (context, setStateDialog) {
                               // Read the current visibility state INSIDE the builder
                               final visibleBlockIds = ref.watch(visibleBlocksProvider(deviceId));
                               final notifier = ref.read(visibleBlocksProvider(deviceId).notifier);

                               return ListView(
                                 shrinkWrap: true,
                                 children: [
                                     // Optional: Show All / Hide All buttons
                                     Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                            TextButton(onPressed: () => notifier.showAllBlocks(allBlocks.map((b) => b.id).toList()).then((_) => setStateDialog((){})), child: const Text("Show All")),
                                            TextButton(onPressed: () => notifier.hideAllBlocks().then((_) => setStateDialog((){})), child: const Text("Hide All")),
                                        ],
                                     ),
                                     const Divider(),
                                     // List of blocks with checkboxes
                                     ...allBlocks.map((block) {
                                        final bool isVisible = visibleBlockIds.contains(block.id);
                                        return CheckboxListTile(
                                           title: Text(block.name),
                                           subtitle: Text("ID: ${block.id}"),
                                           value: isVisible,
                                           onChanged: (bool? newValue) {
                                              if (newValue == true) {
                                                 notifier.showBlock(block.id);
                                              } else {
                                                 notifier.hideBlock(block.id);
                                              }
                                              // Update the dialog UI
                                              setStateDialog(() {});
                                           },
                                           dense: true,
                                        );
                                     }).toList(),
                                 ],
                               );
                           }
                         );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(child: Text("Error loading blocks: $e")),
                  ),
               ),
               actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Done")),
               ],
            );
         }
      );
   }
}
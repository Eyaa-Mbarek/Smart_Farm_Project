import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/domain/entities/sensor_block.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/user_profile.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/auth_providers.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/user_providers.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/device_providers.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/threshold_alert_provider.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/widgets/sensor_block_card.dart'; // Adjust import path
import 'package:smart_farm_test/domain/repositories/device_repository.dart'; // For type hint if needed

// State for the currently selected device ID shown on the HomeScreen
final selectedDeviceIdProvider = StateProvider<String?>((ref) {
   // Initialize to null, default will be set later if possible
   return null;
});

class HomeScreen extends ConsumerStatefulWidget { // Changed to StatefulWidget
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> { // Changed to ConsumerState

   // Method to set the initial selected device only once
   void _setInitialDevice(UserProfile? profile) {
      // Check if a device isn't already selected and the profile is valid
      if (ref.read(selectedDeviceIdProvider) == null && profile != null && profile.monitoredDevices.isNotEmpty) {
         print("HomeScreen: Setting initial device to ${profile.monitoredDevices.first}");
         // Use context.read outside build or ref.read inside build with postFrameCallback
         // Using ref.read directly here is safe as it's called based on profile data update
          ref.read(selectedDeviceIdProvider.notifier).state = profile.monitoredDevices.first;
      }
   }


   @override
   Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final selectedDeviceId = ref.watch(selectedDeviceIdProvider);

    // --- Set initial device selection based on profile load ---
    // Use listen to react to profile changes without causing build loops
    ref.listen<UserProfile?>(userProfileProvider.select((asyncValue) => asyncValue.valueOrNull), (prevProfile, nextProfile) {
       // If selection is still null and profile loaded with devices, set the first one
       if (ref.read(selectedDeviceIdProvider) == null && nextProfile != null && nextProfile.monitoredDevices.isNotEmpty) {
           print("HomeScreen Listener: Setting initial device to ${nextProfile.monitoredDevices.first}");
           // Important: Use notifier to update state provider
           ref.read(selectedDeviceIdProvider.notifier).state = nextProfile.monitoredDevices.first;
       } else if (nextProfile != null && selectedDeviceId != null && !nextProfile.monitoredDevices.contains(selectedDeviceId)) {
           // If the currently selected device was removed from monitored list, reset selection
           print("HomeScreen Listener: Selected device $selectedDeviceId removed from monitored list. Resetting.");
           ref.read(selectedDeviceIdProvider.notifier).state = nextProfile.monitoredDevices.isNotEmpty ? nextProfile.monitoredDevices.first : null;
       }
    });


    // --- Activate threshold listener for the *currently selected* device ---
    // If a device ID is selected, watch its corresponding alert provider
    if (selectedDeviceId != null && selectedDeviceId.isNotEmpty) {
      print("HomeScreen: Watching threshold alerts for $selectedDeviceId");
      // Watching the provider sets up the listener defined in its body
      ref.watch(deviceThresholdAlertProvider(selectedDeviceId));
    }
    // ---

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
         // Build the device selector dropdown in the AppBar's bottom
         bottom: userProfileAsync.maybeWhen(
            // Only build selector if profile data exists
            data: (profile) => _buildDeviceSelector(context, ref, profile),
            orElse: () => null, // Return null (no bottom) if loading or error
         ),
         // Add a refresh button? Might be redundant with pull-to-refresh
         // actions: [
         //    IconButton(onPressed: () {
         //        if(selectedDeviceId != null) {
         //           ref.invalidate(deviceSensorBlocksStreamProvider(selectedDeviceId));
         //        }
         //        ref.invalidate(userProfileProvider); // Refresh profile too?
         //    }, icon: const Icon(Icons.refresh))
         // ],
      ),
      body: userProfileAsync.when(
        data: (userProfile) {
          if (userProfile == null) {
            // Should be handled by Wrapper, but good fallback
             return const Center(child: Text('User profile not loaded. Please restart or log in again.'));
          }

          // Handle state where user has NO monitored devices
          if (userProfile.monitoredDevices.isEmpty) {
              return Center(
                 child: Padding(
                   padding: const EdgeInsets.all(20.0),
                   child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         const Text('No devices are being monitored.\nAdd a device using the "+" button.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
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

          // Handle state where monitored devices exist, but none is selected *yet*
          // (This case might be brief due to the listener setting the default)
          if (selectedDeviceId == null || selectedDeviceId.isEmpty) {
              print("HomeScreen: No device selected yet, showing loading/prompt.");
              // It's possible the default selection is happening in the post frame callback
              return const Center(child: CircularProgressIndicator()); // Or show a 'Select a device' prompt
          }


          // --- Display Blocks for Selected Device ---
          // Watch the sensor blocks stream for the *selected* device ID
          final blocksAsync = ref.watch(deviceSensorBlocksStreamProvider(selectedDeviceId));

          return blocksAsync.when(
             data: (blocks) {
                 if (blocks.isEmpty) {
                     // Could be no blocks configured OR device is offline and RTDB path is empty
                     return Center(
                       child: Padding(
                         padding: const EdgeInsets.all(20.0),
                         child: Text(
                            'No sensor blocks found for device "$selectedDeviceId".\nEnsure blocks are configured in Firebase RTDB or the device is online.',
                             textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                       )
                     );
                 }
                 // Display the list using RefreshIndicator and ListView
                  return RefreshIndicator(
                     onRefresh: () async {
                          print("Refreshing data for device $selectedDeviceId");
                         // Invalidate the stream for the specific device to refetch RTDB data
                         ref.invalidate(deviceSensorBlocksStreamProvider(selectedDeviceId));
                         // Optionally invalidate device config too if it might change
                         ref.invalidate(deviceConfigProvider(selectedDeviceId));
                     },
                     child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80), // Padding for FAB
                        itemCount: blocks.length,
                        // Pass the deviceId to the card if needed for config dialog context
                        itemBuilder: (context, index) => SensorBlockCard(block: blocks[index] /*, deviceId: selectedDeviceId */),
                     ),
                   );
             },
             loading: () => const Center(child: CircularProgressIndicator()), // Loading blocks for selected device
             error: (err, stack) {
                print("Error loading blocks for $selectedDeviceId: $err");
                return Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading sensor blocks for $selectedDeviceId: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                ));
             },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()), // Loading user profile
        error: (err, stack) {
           print("Error loading user profile in HomeScreen: $err");
           return Center(child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: Text('Error loading user profile: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
           ));
        },
      ),
       // FAB to add/register a new device
       floatingActionButton: FloatingActionButton(
         onPressed: () => _showAddDeviceDialog(context, ref),
         tooltip: 'Add/Register Device',
         child: const Icon(Icons.add_box_outlined), // Use a device-related icon
       ),
    );
  }

   // --- Helper to build the device selector AppBar bottom ---
   PreferredSizeWidget? _buildDeviceSelector(BuildContext context, WidgetRef ref, UserProfile? profile) {
      // Don't show selector if profile isn't loaded or no devices are monitored
      if (profile == null || profile.monitoredDevices.isEmpty) {
         return null;
      }

      final selectedDeviceId = ref.watch(selectedDeviceIdProvider);
      final List<String> monitoredDevices = profile.monitoredDevices;

       // Ensure selectedDeviceId is valid within the monitored list, default to first if not
       final String currentSelection;
       if (selectedDeviceId != null && monitoredDevices.contains(selectedDeviceId)) {
           currentSelection = selectedDeviceId;
       } else if (monitoredDevices.isNotEmpty) {
           // If current selection is invalid or null, default to the first monitored device
           // This might trigger a state update shortly after build, handled by Riverpod
           currentSelection = monitoredDevices.first;
            // Avoid calling setState directly in build
            WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ref.read(selectedDeviceIdProvider) != currentSelection && monitoredDevices.contains(currentSelection)) {
                   ref.read(selectedDeviceIdProvider.notifier).state = currentSelection;
                }
            });
       } else {
           // No devices to select
           return null;
       }


      return PreferredSize(
          preferredSize: const Size.fromHeight(50.0), // Height of the dropdown area
          child: Container(
             // Style to match AppBar
             color: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
             alignment: Alignment.centerLeft,
             child: DropdownButtonHideUnderline( // Remove the default underline
               child: DropdownButton<String>(
                  value: currentSelection,
                  isExpanded: true, // Take available width
                  icon: const Icon(Icons.arrow_drop_down_circle_outlined), // Custom icon
                  // Style dropdown text
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant
                  ),
                  // Callback when a new item is selected
                  onChanged: (String? newValue) {
                     if (newValue != null) {
                        print("Device selected: $newValue");
                        // Update the state provider for the selected device ID
                        ref.read(selectedDeviceIdProvider.notifier).state = newValue;
                     }
                  },
                  // Generate dropdown items from the monitored devices list
                  items: monitoredDevices.map<DropdownMenuItem<String>>((String deviceId) {
                     // Watch the specific device config provider to get the name
                     // This uses .family provider with the deviceId
                     final deviceConfigAsync = ref.watch(deviceConfigProvider(deviceId));
                     return DropdownMenuItem<String>(
                        value: deviceId,
                        // Display device name or ID based on config loading state
                        child: Text(
                           deviceConfigAsync.when(
                              data: (config) => config?.deviceName ?? deviceId, // Show name or ID
                              loading: () => '$deviceId (Loading...)',
                              error: (e, s) => '$deviceId (Error)',
                           ),
                           overflow: TextOverflow.ellipsis, // Prevent long names from overflowing
                        ),
                     );
                  }).toList(),
               ),
             ),
          ),
       );
   }


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

    // --- Logic to handle checking and adding the device ---
    // (Keep the _handleDeviceAddition function exactly as provided in the previous response)
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
} // End of _HomeScreenState
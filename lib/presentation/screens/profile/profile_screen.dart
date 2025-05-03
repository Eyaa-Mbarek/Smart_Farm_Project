import 'package:flutter/material.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'package:intl/intl.dart';
    import 'package:smart_farm_test/presentation/providers/auth_providers.dart';
    import 'package:smart_farm_test/presentation/providers/user_providers.dart';
    import 'package:smart_farm_test/presentation/providers/notification_providers.dart';
    import 'package:smart_farm_test/domain/entities/user_profile.dart';
    import 'package:smart_farm_test/domain/entities/notification_item.dart';
    import 'package:smart_farm_test/domain/repositories/auth_repository.dart';
    import 'package:smart_farm_test/presentation/providers/device_providers.dart'; // Import device providers
    import 'manage_device_access_screen.dart'; // Import the new screen
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _usernameController = TextEditingController();
  bool _isEditingUsername = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  // Function to trigger saving the username
  void _saveUsername(String uid) async {
     final newUsername = _usernameController.text.trim();
     if (newUsername.isNotEmpty) {
        // Show loading or disable button briefly? For now, just call update.
        print("Attempting to update username for $uid to $newUsername");
        try {
           // Use the dedicated provider/repo method
           await ref.read(userRepositoryProvider).updateUserProfile(uid, {'username': newUsername});
           if (mounted) { // Check if widget is still in the tree
              setState(() { _isEditingUsername = false; }); // Exit editing mode on success
              ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Username updated successfully!'), backgroundColor: Colors.green),
              );
           }
        } catch (e) {
            print("Error updating username: $e");
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Error updating username: $e'), backgroundColor: Colors.red),
               );
             }
        }
     } else {
         // Handle case where user tries to save an empty username if required
         // For now, just exit editing mode without saving
         if (mounted) {
           setState(() { _isEditingUsername = false; });
            // Optionally reset controller to original value
            _usernameController.text = ref.read(userProfileProvider).value?.username ?? '';
         }
     }
  }

   // Method to show the logout confirmation dialog
  void _showLogoutConfirmationDialog(BuildContext context, IAuthRepository authRepository) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog FIRST
                try {
                  await authRepository.signOut();
                  // Wrapper will handle navigation
                  print("User logged out successfully via ProfileScreen.");
                } catch (e) {
                   print("Error during logout from ProfileScreen: $e");
                   // Show error SnackBar if needed (using the original screen context)
                   if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text('Logout failed: $e'), backgroundColor: Colors.red),
                      );
                   }
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
      Widget build(BuildContext context) {
        final userProfileAsync = ref.watch(userProfileProvider);
        final notificationsAsync = ref.watch(notificationHistoryProvider);
        final authRepository = ref.read(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutConfirmationDialog(context, authRepository); // Show confirmation
            },
          )
        ],
      ),
      // Use userProfileAsync.when to handle loading/error for the main content
      body: userProfileAsync.when(
        data: (userProfile) {
          // If profile data is null (e.g., user just logged out but widget hasn't switched yet)
          if (userProfile == null) {
             // This state should ideally be brief as Wrapper handles navigation
             return const Center(child: Text('Not logged in or profile loading...'));
          }

          // Set initial value for username controller ONLY when data loads
          // and we are NOT currently in editing mode. This prevents overriding user input.
          if (!_isEditingUsername && _usernameController.text.isEmpty && userProfile.username != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted && !_isEditingUsername) { // Check again in callback
                    _usernameController.text = userProfile.username!;
                 }
              });
          }

          // Main content structure using ListView
          return RefreshIndicator( // Add pull-to-refresh for notifications/profile
             onRefresh: () async {
                ref.invalidate(userProfileProvider);
                ref.invalidate(notificationHistoryProvider);
             },
             child: ListView(
               padding: const EdgeInsets.all(16.0),
               children: [
                 // --- Profile Info Section ---
                 Padding(
                   padding: const EdgeInsets.only(bottom: 8.0),
                   child: Text('User Profile', style: Theme.of(context).textTheme.titleLarge),
                 ),
                 Card( // Wrap profile info in a Card
                   elevation: 2,
                   child: Column(
                     children: [
                       ListTile(
                          leading: const Icon(Icons.email_outlined),
                          title: const Text('Email'),
                          subtitle: Text(userProfile.email),
                       ),
                       ListTile(
                         leading: const Icon(Icons.person_outline),
                         title: const Text('Username'),
                         // Conditional UI for displaying or editing username
                         subtitle: _isEditingUsername
                             ? Padding( // Add padding for TextField density
                                 padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                                 child: TextFormField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(hintText: 'Enter username', isDense: true),
                                    autofocus: true,
                                     textInputAction: TextInputAction.done,
                                     onFieldSubmitted: (_) => _saveUsername(userProfile.uid),
                                  ),
                               )
                             : Text(userProfile.username ?? 'Not set'), // Show username or placeholder
                         // Trailing icons for edit/save/cancel
                         trailing: _isEditingUsername
                             ? Row( // Save and Cancel buttons
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                   IconButton(
                                      icon: const Icon(Icons.save_outlined, color: Colors.green),
                                      onPressed: () => _saveUsername(userProfile.uid),
                                      tooltip: 'Save Username',
                                   ),
                                   IconButton(
                                      icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
                                      onPressed: () {
                                         // Cancel editing
                                         setState(() { _isEditingUsername = false; });
                                         // Reset controller text to original value
                                         _usernameController.text = userProfile.username ?? '';
                                      },
                                      tooltip: 'Cancel',
                                   ),
                                ],
                             )
                             : IconButton( // Edit button
                                 icon: const Icon(Icons.edit_outlined, size: 20),
                                 onPressed: () {
                                    // Start editing - populate controller first
                                     _usernameController.text = userProfile.username ?? '';
                                    setState(() { _isEditingUsername = true; });
                                 },
                                 tooltip: 'Edit Username',
                               ),
                       ),
                        // Add more profile fields/settings here later
                        // Example:
                        // ListTile(
                        //    leading: Icon(Icons.devices_other),
                        //    title: Text('Owned Devices'),
                        //    subtitle: Text(userProfile.ownedDevices.join(', ') ),
                        // ),
                     ],
                   ),
                 ),

                 const Divider(height: 30, thickness: 1),

                   // --- Owned Devices Section (NEW) ---
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text('My Owned Devices', style: Theme.of(context).textTheme.titleLarge),
                      ),
                      if (userProfile.ownedDevices.isEmpty)
                          const Card(child: ListTile(title: Text("You haven't registered any devices yet.")))
                      else
                          ...userProfile.ownedDevices.map((deviceId) {
                              // Watch device config to get its name
                              final deviceConfigAsync = ref.watch(deviceConfigProvider(deviceId));
                              return Card(
                                 margin: const EdgeInsets.symmetric(vertical: 4),
                                 child: ListTile(
                                    leading: const Icon(Icons.developer_board),
                                    title: Text(deviceConfigAsync.when(
                                        data: (c) => c?.deviceName ?? deviceId,
                                        loading: () => deviceId,
                                        error: (e,s) => deviceId
                                    )),
                                    subtitle: Text("ID: $deviceId"),
                                    trailing: ElevatedButton( // Button to manage access
                                        child: const Text("Manage Access"),
                                        onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(
                                               builder: (context) => ManageDeviceAccessScreen(deviceId: deviceId),
                                            ));
                                        },
                                    ),
                                    // Optional: Add button to remove from monitored list? Or delete device?
                                 ),
                              );
                           }).toList(),

                       const Divider(height: 30, thickness: 1),

                 // --- Notification History Section ---
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('Notification History', style: Theme.of(context).textTheme.titleLarge),
                  ),
                 // Use notificationsAsync.when for this section
                 notificationsAsync.when(
                     data: (notifications) {
                       if (notifications.isEmpty) {
                          // Show a message if history is empty
                          return const Center(child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 30.0),
                            child: Text('No notifications yet.', style: TextStyle(color: Colors.grey)),
                          ));
                       }
                       // Build the list of notifications
                       return ListView.builder(
                          shrinkWrap: true, // Required inside another scroll view
                          physics: const NeverScrollableScrollPhysics(), // Disable inner list scrolling
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                             final notification = notifications[index];
                             // Format timestamp for display
                             final formattedTime = DateFormat('MMM d, yyyy HH:mm').format(notification.timestamp.toDate().toLocal());
                             return Card( // Wrap each notification in a Card
                               margin: const EdgeInsets.symmetric(vertical: 4.0),
                               elevation: 1,
                               child: ListTile(
                                 leading: Icon(
                                     notification.read ? Icons.notifications_none_outlined : Icons.notifications_active,
                                     color: notification.read ? Colors.grey : Theme.of(context).colorScheme.primary,
                                 ),
                                 title: Text(
                                     notification.title,
                                     style: TextStyle(fontWeight: notification.read ? FontWeight.normal : FontWeight.bold),
                                 ),
                                 subtitle: Text("${notification.body}\n$formattedTime"),
                                 isThreeLine: true,
                                 // Delete button
                                 trailing: IconButton(
                                    icon: Icon(Icons.delete_sweep_outlined, color: Colors.red.shade300),
                                    tooltip: 'Delete Notification',
                                    onPressed: () async {
                                       try {
                                          // Use the delete provider
                                          await ref.read(deleteNotificationProvider)(notification.id);
                                          if (mounted) {
                                             ScaffoldMessenger.of(context).showSnackBar(
                                                 const SnackBar(content: Text('Notification deleted.'), duration: Duration(seconds: 2)),
                                             );
                                          }
                                       } catch (e) {
                                           if (mounted) {
                                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting notification: $e')));
                                          }
                                       }
                                    },
                                 ),
                                 // Mark as read on tap
                                 onTap: () async {
                                    if (!notification.read) {
                                       try {
                                           // Use the mark read provider
                                          await ref.read(markNotificationReadProvider)(notification.id);
                                       } catch (e) {
                                           print("Error marking notification read: $e");
                                          /* Handle error silently? */
                                       }
                                    }
                                     // Maybe navigate to details or related device?
                                     print("Tapped notification: ${notification.id} (Device: ${notification.deviceId}, Block: ${notification.blocId})");
                                 },
                               ),
                             );
                          },
                       );
                     },
                     // Loading state for notifications
                     loading: () => const Center(child: Padding(
                       padding: EdgeInsets.symmetric(vertical: 30.0),
                       child: CircularProgressIndicator(),
                     )),
                     // Error state for notifications
                     error: (err, stack) => Center(child: Padding(
                       padding: const EdgeInsets.symmetric(vertical: 30.0),
                       child: Text('Error loading notifications: $err', style: const TextStyle(color: Colors.red)),
                     )),
                  ),
               ],
             ),
           );
        },
        // Loading state for the user profile itself
        loading: () => const Center(child: CircularProgressIndicator()),
        // Error state for the user profile
        error: (err, stack) {
           print("Error loading profile screen: $err");
           return Center(child: Text('Error loading profile: $err', style: const TextStyle(color: Colors.red)));
        },
      ),
    );
  }
}

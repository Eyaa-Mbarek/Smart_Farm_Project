import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:smart_farm_test/domain/repositories/auth_repository.dart';
import 'package:smart_farm_test/presentation/providers/auth_providers.dart';
import 'package:smart_farm_test/presentation/providers/user_providers.dart';
import 'package:smart_farm_test/presentation/providers/notification_providers.dart';

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

  void _saveUsername(String uid) async {
     final newUsername = _usernameController.text.trim();
     if (newUsername.isNotEmpty) {
        try {
           await ref.read(userRepositoryProvider).updateUserProfile(uid, {'username': newUsername});
           setState(() { _isEditingUsername = false; });
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Username updated!'), backgroundColor: Colors.green),
            );
        } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error updating username: $e'), backgroundColor: Colors.red),
            );
        }
     }
  }

   void _showLogoutConfirmationDialog(BuildContext context, IAuthRepository authRepository) { // Accept repo
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Use a different context name
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
              style: TextButton.styleFrom(foregroundColor: Colors.red), // Style the logout button
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog FIRST
                try {
                  await authRepository.signOut();
                  // No navigation needed here, the Wrapper will handle the auth state change
                  print("User logged out successfully.");
                } catch (e) {
                   print("Error during logout: $e");
                   // Show error SnackBar if needed (using the original screen context)
                   ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Logout failed: $e'), backgroundColor: Colors.red),
                   );
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
    final authRepository = ref.watch(authRepositoryProvider); // For logout

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
            // Show confirmation dialog BEFORE logging out
              _showLogoutConfirmationDialog(context, authRepository); // Pass context and repo
               // Wrapper will handle navigation
            },
          )
        ],
      ),
      body: userProfileAsync.when(
        data: (userProfile) {
          if (userProfile == null) {
             // This shouldn't happen if Wrapper works correctly, but handle defensively
             return const Center(child: Text('Not logged in.'));
          }

          // Set initial value for username controller when data loads and not editing
          if (!_isEditingUsername && userProfile.username != null) {
              _usernameController.text = userProfile.username!;
          }

          return ListView( // Use ListView for scrolling content
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Profile Info Section ---
              Text('User Profile', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              ListTile(
                 leading: const Icon(Icons.email_outlined),
                 title: const Text('Email'),
                 subtitle: Text(userProfile.email),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Username'),
                subtitle: _isEditingUsername
                    ? TextFormField(
                         controller: _usernameController,
                         decoration: const InputDecoration(hintText: 'Enter username'),
                         autofocus: true,
                      )
                    : Text(userProfile.username ?? 'Not set'),
                trailing: _isEditingUsername
                    ? Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                          IconButton(
                             icon: const Icon(Icons.save, color: Colors.green),
                             onPressed: () => _saveUsername(userProfile.uid),
                             tooltip: 'Save Username',
                          ),
                          IconButton(
                             icon: const Icon(Icons.cancel, color: Colors.grey),
                             onPressed: () {
                                setState(() { _isEditingUsername = false; });
                                // Reset controller text if needed
                                _usernameController.text = userProfile.username ?? '';
                             },
                             tooltip: 'Cancel',
                          ),
                       ],
                    )
                    : IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () {
                           setState(() { _isEditingUsername = true; });
                        },
                        tooltip: 'Edit Username',
                      ),
              ),
              // Add more profile settings later (e.g., Password Reset button)

              const Divider(height: 40),

              // --- Notification History Section ---
              Text('Notification History', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              notificationsAsync.when(
                  data: (notifications) {
                    if (notifications.isEmpty) {
                       return const Center(child: Padding(
                         padding: EdgeInsets.symmetric(vertical: 20.0),
                         child: Text('No notifications yet.', style: TextStyle(color: Colors.grey)),
                       ));
                    }
                    return ListView.builder(
                       shrinkWrap: true, // Important inside another ListView
                       physics: const NeverScrollableScrollPhysics(), // Disable scrolling of inner list
                       itemCount: notifications.length,
                       itemBuilder: (context, index) {
                          final notification = notifications[index];
                          final formattedTime = DateFormat('MMM d, yyyy HH:mm').format(notification.timestamp.toDate());
                          return ListTile(
                            leading: Icon(notification.read ? Icons.notifications_none : Icons.notifications_active, color: notification.read ? Colors.grey : Theme.of(context).colorScheme.primary),
                            title: Text(notification.title, style: TextStyle(fontWeight: notification.read ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Text("${notification.body}\n$formattedTime"),
                            isThreeLine: true,
                            trailing: IconButton(
                               icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                               tooltip: 'Delete Notification',
                               onPressed: () async {
                                  try {
                                     await ref.read(notificationRepositoryProvider).deleteNotification(userProfile.uid, notification.id);
                                  } catch (e) {
                                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting notification: $e')));
                                  }
                               },
                            ),
                            onTap: () async {
                               // Mark as read on tap
                               if (!notification.read) {
                                  try {
                                     await ref.read(notificationRepositoryProvider).markNotificationAsRead(userProfile.uid, notification.id);
                                  } catch (e) {/* Handle error silently? */}
                               }
                            },
                          );
                       },
                    );
                  },
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: CircularProgressIndicator(),
                  )),
                  error: (err, stack) => Center(child: Text('Error loading notifications: $err')),
               ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }
}
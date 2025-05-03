import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_farm_test/domain/entities/device_config.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/device_providers.dart'; // Adjust import path
import 'package:smart_farm_test/presentation/providers/user_providers.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/user_profile.dart'; // Adjust import path

class ManageDeviceAccessScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const ManageDeviceAccessScreen({Key? key, required this.deviceId})
    : super(key: key);

  @override
  ConsumerState<ManageDeviceAccessScreen> createState() =>
      _ManageDeviceAccessScreenState();
}

class _ManageDeviceAccessScreenState
    extends ConsumerState<ManageDeviceAccessScreen> {
  final _emailController = TextEditingController();
  bool _isAddingUser = false;
  String? _addUserError;
  String? _foundUserId; // Store UID of found user

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Function to find user by email and add authorization
  Future<void> _findAndAddUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _addUserError = "Please enter a valid email address.";
      });
      return;
    }

    setState(() {
      _isAddingUser = true;
      _addUserError = null;
      _foundUserId = null;
    });

    try {
      final findUser = ref.read(findUserByEmailProvider);
      final UserProfile? userToAdd = await findUser(email);

      if (userToAdd == null) {
        setState(() {
          _addUserError = "User with email $email not found.";
          _isAddingUser = false;
        });
        return;
      }

      // User found, now try adding them
      _foundUserId = userToAdd.uid;
      final addAuth = ref.read(addAuthorizedUserProvider);

      // Get current config to prevent adding owner or already authorized user
      final currentConfig = await ref
          .read(deviceRepositoryProvider)
          .getDeviceConfig(widget.deviceId);
      if (currentConfig == null) {
        setState(() {
          _addUserError = "Device config error.";
          _isAddingUser = false;
        });
        return;
      }
      if (currentConfig.ownerUid == _foundUserId) {
        setState(() {
          _addUserError = "Cannot add the device owner.";
          _isAddingUser = false;
        });
        return;
      }
      if (currentConfig.authorizedUsers.contains(_foundUserId)) {
        setState(() {
          _addUserError = "$email is already authorized.";
          _isAddingUser = false;
        });
        return;
      }

      await addAuth(deviceId: widget.deviceId, userUidToAdd: _foundUserId!);

      // Success! Clear fields and show message
      _emailController.clear();
      setState(() {
        _isAddingUser = false;
        _addUserError = null;
        _foundUserId = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User $email (${userToAdd.username ?? ''}) granted access!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _addUserError = "Error granting access: $e";
        _isAddingUser = false;
      });
    }
  }

  // Function to remove user authorization
  Future<void> _removeUser(String userUidToRemove) async {
    print(
      "Attempting to remove user $userUidToRemove from device ${widget.deviceId}",
    );
    // Optional: Add confirmation dialog here
    try {
      final removeAuth = ref.read(removeAuthorizedUserProvider);
      await removeAuth(
        deviceId: widget.deviceId,
        userUidToRemove: userUidToRemove,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User access revoked.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error revoking access: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the stream of the specific device's config
    final deviceConfigAsync = ref.watch(
      deviceConfigStreamProvider(widget.deviceId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Access: ${widget.deviceId}'), // Show device ID
        // Potentially show device name when loaded: deviceConfigAsync.value?.deviceName ?? widget.deviceId
      ),
      body: deviceConfigAsync.when(
        data: (config) {
          if (config == null) {
            return const Center(child: Text('Device configuration not found.'));
          }

          // Filter out the owner from the list shown for removal
          final removableUsers =
              config.authorizedUsers
                  .where((uid) => uid != config.ownerUid)
                  .toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text(
                  "Device Name: ${config.deviceName}",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  "Owner UID: ${config.ownerUid}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),

                // --- Section to Add New User ---
                Text(
                  "Grant Access to User",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'User Email to Add',
                    border: const OutlineInputBorder(),
                    errorText: _addUserError, // Show error message below field
                    suffixIcon:
                        _isAddingUser
                            ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                            : IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              tooltip: 'Grant Access',
                              onPressed: _findAndAddUser,
                            ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isAddingUser, // Disable while adding
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _findAndAddUser(),
                ),

                const Divider(height: 30),

                // --- Section to Show/Remove Authorized Users ---
                Text(
                  "Authorized Users",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (removableUsers.isEmpty)
                  const Text(
                    "Only the owner has access currently.",
                    style: TextStyle(color: Colors.grey),
                  ),
                // List authorized users (excluding owner) with remove button
                ...removableUsers.map((userUid) {
                  // Fetch user details to show email/name - Could be optimized
                  final userProfileFuture = ref.watch(
                    userProfileProvider.select((value) => value.valueOrNull),
                  ); // Read current value of logged in user profile - THIS IS WRONG - need to fetch specific UID

                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    // TODO: Fetch and display user email/name for the given userUid
                    title: Text(
                      'User UID: $userUid',
                    ), // Placeholder - Fetch profile needed
                    subtitle: Text('Can access this device'), // Placeholder
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                      ),
                      tooltip: 'Revoke Access',
                      onPressed: () => _removeUser(userUid),
                    ),
                  );
                }).toList(),

                // Display owner separately (cannot be removed)
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(
                    "Owner: ${config.ownerUid}",
                  ), // Placeholder - Fetch profile needed
                  subtitle: const Text("Full access"),
                  dense: true,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, stack) =>
                Center(child: Text("Error loading device config: $err")),
      ),
    );
  }
}

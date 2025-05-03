import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? username;
  final Timestamp? createdAt;
  final List<String> monitoredDevices; // List of device IDs user actively watches
  final List<String> ownedDevices;     // List of device IDs user owns
  final Map<String, String> accessibleDevices; // Map<deviceId, ownerUid> for shared devices
  final List<String> fcmTokens; // List of FCM tokens for this user

  UserProfile({
    required this.uid,
    required this.email,
    this.username,
    this.createdAt,
    required this.monitoredDevices,
    required this.ownedDevices,
    required this.accessibleDevices,
    required this.fcmTokens,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) throw Exception("User profile data is null!");

    // Helper to safely convert map from Firestore
    Map<String, String> safeMapCast(Map<dynamic, dynamic>? inputMap) {
        if (inputMap == null) return {};
        return Map<String, String>.from(inputMap.map(
             (key, value) => MapEntry(key.toString(), value.toString()),
        ));
    }

    return UserProfile(
      uid: snapshot.id,
      email: data['email'] as String? ?? '',
      username: data['username'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      monitoredDevices: List<String>.from(data['monitoredDevices'] as List<dynamic>? ?? []),
      ownedDevices: List<String>.from(data['ownedDevices'] as List<dynamic>? ?? []),
      accessibleDevices: safeMapCast(data['accessibleDevices'] as Map<dynamic, dynamic>?),
      fcmTokens: List<String>.from(data['fcmTokens'] as List<dynamic>? ?? []), // Load FCM tokens
    );
  }

  // Map for general profile updates (e.g., username, monitored devices)
  Map<String, dynamic> toUpdateFirestore() {
    return {
      if (username != null) 'username': username,
      'monitoredDevices': monitoredDevices,
      // Note: email, ownedDevices, accessibleDevices, fcmTokens are usually updated via specific actions
    };
  }

   // Helper to create initial data for a new user profile
   static Map<String, dynamic> initialData(String email, {String? username}) {
      return {
         'email': email,
         'username': username, // Can be null initially
         'createdAt': FieldValue.serverTimestamp(),
         'monitoredDevices': [], // Start with no monitored devices
         'ownedDevices': [],     // Start with no owned devices
         'accessibleDevices': {}, // Start with no accessible devices
         'fcmTokens': [], // Initialize fcmTokens array
      };
   }
}
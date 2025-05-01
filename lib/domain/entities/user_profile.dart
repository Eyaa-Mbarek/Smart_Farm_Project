import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? username; // Optional username
  final Timestamp? createdAt;
  final List<String> monitoredBlocks; // List of monitored block IDs

  UserProfile({
    required this.uid,
    required this.email,
    this.username,
    this.createdAt,
    required this.monitoredBlocks,
  });

  // Factory constructor to create a UserProfile from a Firestore snapshot
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) throw Exception("User profile data is null!");

    return UserProfile(
      uid: snapshot.id,
      email: data['email'] as String? ?? '', // Handle potential null email?
      username: data['username'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
       // Ensure monitoredBlocks is always a list, even if null/missing in Firestore
      monitoredBlocks: List<String>.from(data['monitoredBlocks'] as List<dynamic>? ?? []),
    );
  }

  // Method to convert UserProfile to a map for Firestore updates
  Map<String, dynamic> toFirestore() {
    return {
      // Don't write UID to the document itself
      'email': email,
      if (username != null) 'username': username,
      // createdAt is usually set server-side on create, don't overwrite
      'monitoredBlocks': monitoredBlocks,
       // You might add 'lastUpdated' timestamp here if needed
    };
  }
}
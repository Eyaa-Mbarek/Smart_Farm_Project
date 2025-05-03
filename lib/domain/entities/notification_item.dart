import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final Timestamp timestamp;
  final bool read;
  final String? blocId; // Optional: Link back to the block
  final String? deviceId; // Optional: Link back to the device

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.read,
    this.blocId,
    this.deviceId,
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
     if (data == null) throw Exception("Notification data is null for ${snapshot.id}!");

    return NotificationItem(
      id: snapshot.id,
      title: data['title'] as String? ?? 'No Title',
      body: data['body'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      read: data['read'] as bool? ?? false,
      blocId: data['blocId'] as String?,
      deviceId: data['deviceId'] as String?, // Load deviceId
    );
  }
}
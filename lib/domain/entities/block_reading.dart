import 'package:cloud_firestore/cloud_firestore.dart';

class BlockReading {
  final String id; // Firestore document ID
  final DateTime timestamp;
  final double value;
  final int type; // Store raw type/unit as they were at the time
  final String unit;

  BlockReading({
    required this.id,
    required this.timestamp,
    required this.value,
    required this.type,
    required this.unit,
  });

  factory BlockReading.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) throw Exception("Reading data is null for ${snapshot.id}");

    return BlockReading(
      id: snapshot.id,
      // Convert Firestore Timestamp to DateTime
      timestamp: (data['timestamp'] as Timestamp? ?? Timestamp.now()).toDate(),
      // Handle potential integer values from Firestore
      value: (data['value'] as num? ?? 0.0).toDouble(),
      type: data['type'] as int? ?? 0, // Default to 0 (unknown)
      unit: data['unit'] as String? ?? '',
    );
  }
}
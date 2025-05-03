import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceConfig {
   final String deviceId;
   final String ownerUid;
   final String deviceName;
   final Timestamp? createdAt;
   final List<String> authorizedUsers;

   DeviceConfig({
       required this.deviceId,
       required this.ownerUid,
       required this.deviceName,
       this.createdAt,
       required this.authorizedUsers,
   });

    factory DeviceConfig.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
       final data = snapshot.data();
       if (data == null) throw Exception("Device config data is null for ${snapshot.id}!");

       return DeviceConfig(
         deviceId: snapshot.id,
         ownerUid: data['ownerUid'] as String? ?? '',
         deviceName: data['deviceName'] as String? ?? 'Unnamed Device',
         createdAt: data['createdAt'] as Timestamp?,
         authorizedUsers: List<String>.from(data['authorizedUsers'] as List<dynamic>? ?? []),
       );
   }

   // Helper for initial data when registering a device
   static Map<String, dynamic> initialData(String ownerUid, String deviceName) {
       return {
          'ownerUid': ownerUid,
          'deviceName': deviceName,
          'createdAt': FieldValue.serverTimestamp(),
          'authorizedUsers': [ownerUid], // Owner is authorized by default
       };
   }
}
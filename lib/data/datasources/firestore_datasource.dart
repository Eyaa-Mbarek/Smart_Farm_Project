import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_farm_test/domain/entities/notification_item.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/user_profile.dart'; // Adjust import path
// DeviceConfig entity is not directly used here, but methods operate on its collection

class FirestoreDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- User Profile Methods ---

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
     return _firestore.collection('users').doc(uid);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
     return _userRef(uid).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserProfileSnapshot(String uid) {
     return _userRef(uid).snapshots();
  }

   // Creates or overwrites user profile document
  Future<void> setUserProfile(String uid, Map<String, dynamic> data) async {
     // This ensures initialData with serverTimestamp is handled correctly
     await _userRef(uid).set(data, SetOptions(merge: true));
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    // Ensure internal arrays/maps are not accidentally overwritten by general update
    data.remove('createdAt');
    data.remove('ownedDevices');
    data.remove('accessibleDevices');
    data.remove('fcmTokens');
    data.remove('monitoredDevices'); // Specific method updates this
    if (data.isEmpty) return Future.value(); // Avoid empty update
     return _userRef(uid).update(data);
  }

   // --- User Device List Methods ---
   Future<void> addDeviceToUserList(String uid, String field, String deviceId) {
      // Adds deviceId to an array field (monitoredDevices or ownedDevices)
      return _userRef(uid).update({
          field: FieldValue.arrayUnion([deviceId])
      });
   }
    Future<void> removeDeviceFromUserList(String uid, String field, String deviceId) {
      // Removes deviceId from an array field
      return _userRef(uid).update({
          field: FieldValue.arrayRemove([deviceId])
      });
   }
   Future<void> addDeviceToAccessibleMap(String uid, String deviceId, String ownerUid) {
      // Adds an entry to the accessibleDevices map
      return _userRef(uid).update({
          'accessibleDevices.$deviceId': ownerUid // Use dot notation
      });
   }
   Future<void> removeDeviceFromAccessibleMap(String uid, String deviceId) {
      // Removes an entry from the accessibleDevices map
       return _userRef(uid).update({
          'accessibleDevices.$deviceId': FieldValue.delete()
      });
   }

    // --- User FCM Token Methods ---
   Future<void> addFcmToken(String uid, String token) {
       return _userRef(uid).update({
           'fcmTokens': FieldValue.arrayUnion([token])
       });
   }
    Future<void> removeFcmToken(String uid, String token) {
       return _userRef(uid).update({
           'fcmTokens': FieldValue.arrayRemove([token])
       });
   }

 // --- User Lookup Method (NEW) ---
  Future<QuerySnapshot<Map<String, dynamic>>> findUserByEmail(String email) {
     // Query users collection where email matches. Limit to 1 for efficiency.
     return _firestore.collection('users')
         .where('email', isEqualTo: email.trim().toLowerCase()) // Search lowercase email
         .limit(1)
         .get();
  }


  // --- Device Config Methods ---
  DocumentReference<Map<String, dynamic>> _deviceConfigRef(String deviceId) {
     return _firestore.collection('devices_config').doc(deviceId);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDeviceConfig(String deviceId) {
     return _deviceConfigRef(deviceId).get();
  }

   Future<bool> deviceConfigExists(String deviceId) async {
     final doc = await getDeviceConfig(deviceId);
     return doc.exists;
  }

  Future<void> createDeviceConfig(String deviceId, Map<String, dynamic> data) {
     // Assumes data includes ownerUid, deviceName, createdAt, authorizedUsers
     return _deviceConfigRef(deviceId).set(data);
  }

  Future<void> updateDeviceConfig(String deviceId, Map<String, dynamic> data) {
     data.remove('ownerUid'); // Protect ownerUid
     data.remove('createdAt');
     if (data.isEmpty) return Future.value();
     return _deviceConfigRef(deviceId).update(data);
  }

  Future<void> deleteDeviceConfig(String deviceId) {
     return _deviceConfigRef(deviceId).delete();
  }

// Stream to watch a single device config document (NEW)
   Stream<DocumentSnapshot<Map<String, dynamic>>> watchDeviceConfig(String deviceId) {
      return _deviceConfigRef(deviceId).snapshots();
   }

  // --- Authorization Management Methods (NEW) ---
   Future<void> addAuthorizedUser(String deviceId, String userUidToAdd) {
      return _deviceConfigRef(deviceId).update({
         'authorizedUsers': FieldValue.arrayUnion([userUidToAdd])
      });
   }

   Future<void> removeAuthorizedUser(String deviceId, String userUidToRemove) {
      return _deviceConfigRef(deviceId).update({
         'authorizedUsers': FieldValue.arrayRemove([userUidToRemove])
      });
   }

  // --- Notification History Methods ---
  CollectionReference<Map<String, dynamic>> _notificationsRef(String uid) {
      return _userRef(uid).collection('notifications');
  }

  Future<void> addNotification(String uid, Map<String, dynamic> notificationData) async {
    // Create a new map locally to ensure we control all fields being added
    final Map<String, dynamic> dataToSave = Map.from(notificationData);

    // Add the special fields DIRECTLY to the map being saved
    dataToSave['timestamp'] = FieldValue.serverTimestamp();
    dataToSave['read'] = false; // Default to unread

    print("FirestoreDataSource: Adding notification data: $dataToSave for UID: $uid");
    try {
        // Add the locally constructed map
        await _notificationsRef(uid).add(dataToSave);
        print("FirestoreDataSource: Notification added successfully.");
    } catch (e) {
       print("FirestoreDataSource: Error adding notification document: $e");
       rethrow;
    }
 }

  Stream<List<NotificationItem>> watchNotifications(String uid) {
    print("FirestoreDataSource: watchNotifications called for UID: $uid");
    final query = _notificationsRef(uid)
        .orderBy('timestamp', descending: true)
        .limit(50); // Limit for performance

    return query.snapshots().map((snapshot) {
      print("FirestoreDataSource: Received ${snapshot.docs.length} notification snapshots for UID: $uid");
      return snapshot.docs
          .map((doc) {
              try {
                 return NotificationItem.fromFirestore(doc);
              } catch (e) {
                  print("FirestoreDataSource: Error parsing notification ${doc.id}: $e");
                  return null; // Handle potential parsing errors
              }
           })
          .whereType<NotificationItem>() // Filter out nulls
          .toList();
    }).handleError((error) {
       print("FirestoreDataSource: Error in notification stream for UID $uid: $error");
       // Propagate error or return empty list
       // throw error;
        return <NotificationItem>[]; // Return empty list on stream error
    });
  }

  Future<void> markNotificationAsRead(String uid, String notificationId) {
     return _notificationsRef(uid).doc(notificationId).update({'read': true});
  }

   Future<void> deleteNotification(String uid, String notificationId) {
     return _notificationsRef(uid).doc(notificationId).delete();
  }

  CollectionReference<Map<String, dynamic>> _readingsRef(String deviceId, String blockId) {
     return _firestore
         .collection('devices_history')
         .doc(deviceId)
         .collection('blocs')
         .doc(blockId)
         .collection('readings');
  }

  // Query for history readings
Stream<QuerySnapshot<Map<String, dynamic>>> watchBlockReadingsQuery(
   String deviceId,
   String blockId,
   { DateTime? startTime, DateTime? endTime, int? limit }
) {
    Query<Map<String, dynamic>> query = _readingsRef(deviceId, blockId)
                                          .orderBy('timestamp', descending: true);
    // ... (add filters for startTime, endTime, limit as before) ...

    print("FirestoreDataSource: WATCHING history for $deviceId/$blockId (Limit: $limit)"); // Log subscription start

    return query.snapshots().map((snapshot) { // Add map here to log *before* repo processes
       print("FirestoreDataSource: Snapshot received for $deviceId/$blockId - Docs: ${snapshot.docs.length}"); // Log snapshot arrival
       snapshot.docs.forEach((doc) { // Log individual docs received (optional, can be verbose)
         // print("  - Doc ID: ${doc.id}, Data: ${doc.data()}");
       });
       return snapshot; // Pass the snapshot along
    }).handleError((error, stackTrace) { // Add detailed error logging for the stream itself
       print("FirestoreDataSource: ERROR in Firestore stream for $deviceId/$blockId: $error\n$stackTrace");
       // Rethrow the error so the repository's handleError can catch it too
       throw error;
    });
}

  // Method to add a single reading (used by ESP32 or potentially app background task)
  Future<void> addBlockReading(
     String deviceId,
     String blockId,
     double value,
     int type,
     String unit
  ) {
     final data = {
        'timestamp': FieldValue.serverTimestamp(), // Use server time
        'value': value,
        'type': type,
        'unit': unit,
     };
      print("FirestoreDataSource: Adding history reading for $deviceId/$blockId");
     return _readingsRef(deviceId, blockId).add(data);
  }

  
}

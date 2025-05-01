import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_farm_test/domain/entities/notification_item.dart'; // Import entity
import 'package:smart_farm_test/domain/entities/user_profile.dart'; // Import entity

class FirestoreDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- User Profile Methods ---

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) {
     return _firestore.collection('users').doc(uid).get();
  }

   // Creates or overwrites user profile document
  Future<void> setUserProfile(String uid, Map<String, dynamic> data) async {
     // Add createdAt timestamp only when creating
     final docRef = _firestore.collection('users').doc(uid);
     final doc = await docRef.get();
     if (!doc.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
     }
     await docRef.set(data, SetOptions(merge: true)); // Use merge: true to avoid overwriting fields not included in 'data'
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    // Ensure createdAt is not overwritten if present in data
    data.remove('createdAt');
     return _firestore.collection('users').doc(uid).update(data);
  }

  // --- Monitored Blocks (within User Profile) ---

  Future<void> updateMonitoredBlocks(String uid, List<String> blockIds) {
     return _firestore.collection('users').doc(uid).update({'monitoredBlocks': blockIds});
  }

  Stream<UserProfile> watchUserProfile(String uid) {
     return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
           throw Exception("User profile not found for UID: $uid");
        }
        return UserProfile.fromFirestore(snapshot);
     });
  }


  // --- Notification History Methods ---

   Future<void> addNotification(String uid, Map<String, dynamic> notificationData) async {
         // Create a new map locally to ensure we control all fields being added
         final Map<String, dynamic> dataToSave = Map.from(notificationData); // Copy incoming data

         // Add the special fields DIRECTLY to the map being saved
         dataToSave['timestamp'] = FieldValue.serverTimestamp();
         dataToSave['read'] = false; // Default to unread

         print("FirestoreDataSource: Adding notification data: $dataToSave for UID: $uid");
         try {
             // Add the locally constructed map
             await _firestore.collection('users').doc(uid).collection('notifications').add(dataToSave);
             print("FirestoreDataSource: Notification added successfully.");
         } catch (e) {
            print("FirestoreDataSource: Error adding notification document: $e");
            rethrow;
         }
      }

  // Stream of notifications ordered by timestamp descending
  Stream<List<NotificationItem>> watchNotifications(String uid) {
    final query = _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50); // Limit the number of notifications fetched

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationItem.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> markNotificationAsRead(String uid, String notificationId) {
     return _firestore.collection('users').doc(uid).collection('notifications').doc(notificationId).update({'read': true});
  }

   Future<void> deleteNotification(String uid, String notificationId) {
     return _firestore.collection('users').doc(uid).collection('notifications').doc(notificationId).delete();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_farm_test/data/datasources/firestore_datasource.dart'; // Adjust import path
import 'package:smart_farm_test/domain/entities/user_profile.dart'; // Adjust import path
import 'package:smart_farm_test/domain/repositories/user_repository.dart'; // Adjust import path

class UserRepositoryImpl implements IUserRepository {
  final FirestoreDataSource _dataSource;
  UserRepositoryImpl(this._dataSource);

  @override
  Stream<UserProfile> watchUserProfile(String uid) {
     // Map the snapshot stream from datasource to UserProfile stream
    return _dataSource.watchUserProfileSnapshot(uid).map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
         // Handle case where profile might be temporarily missing or deleted
         print("Warning: User profile snapshot not found for UID: $uid during watch. Returning default/empty profile.");
          // Return a default or empty profile to avoid stream error, UI should handle this state
          return UserProfile(uid: uid, email: '', monitoredDevices: [], ownedDevices: [], accessibleDevices: {}, fcmTokens: []);
      }
      return UserProfile.fromFirestore(snapshot);
    }).handleError((error) {
       print("Error in watchUserProfile stream for $uid: $error");
       // Propagate error or return a default state
       throw error; // Rethrowing might break the stream in UI, consider returning default
    });
  }

  @override
  Future<UserProfile> getUserProfile(String uid) async {
     final snapshot = await _dataSource.getUserProfile(uid);
      if (!snapshot.exists || snapshot.data() == null) {
         throw Exception("User profile not found for UID: $uid");
      }
     return UserProfile.fromFirestore(snapshot);
  }

  @override
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) {
    // Basic validation or field filtering could happen here if needed
    return _dataSource.updateUserProfile(uid, data);
  }

   // --- Device List Management ---
   @override
   Future<void> addDeviceToMonitored(String uid, String deviceId) {
      return _dataSource.addDeviceToUserList(uid, 'monitoredDevices', deviceId);
   }
   @override
   Future<void> removeDeviceFromMonitored(String uid, String deviceId) {
       return _dataSource.removeDeviceFromUserList(uid, 'monitoredDevices', deviceId);
   }
   @override
   Future<void> addDeviceToOwned(String uid, String deviceId) {
       return _dataSource.addDeviceToUserList(uid, 'ownedDevices', deviceId);
   }
   @override
   Future<void> addDeviceToAccessible(String uid, String deviceId, String ownerUid) {
       return _dataSource.addDeviceToAccessibleMap(uid, deviceId, ownerUid);
   }

   // --- FCM Token Management ---
   @override
   Future<void> addFcmToken(String uid, String token) {
       return _dataSource.addFcmToken(uid, token);
   }
   @override
   Future<void> removeFcmToken(String uid, String token) {
       return _dataSource.removeFcmToken(uid, token);
   }
}
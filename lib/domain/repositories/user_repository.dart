import 'package:smart_farm_test/domain/entities/user_profile.dart'; // Adjust import path

abstract class IUserRepository {
   Stream<UserProfile> watchUserProfile(String uid);
   Future<UserProfile> getUserProfile(String uid);
   Future<void> updateUserProfile(String uid, Map<String, dynamic> data);

   // --- Device List Management ---
   Future<void> addDeviceToMonitored(String uid, String deviceId);
   Future<void> removeDeviceFromMonitored(String uid, String deviceId);
   Future<void> addDeviceToOwned(String uid, String deviceId);
   Future<void> addDeviceToAccessible(String uid, String deviceId, String ownerUid);
   // Maybe remove methods...

   // --- FCM Token Management ---
   Future<void> addFcmToken(String uid, String token);
   Future<void> removeFcmToken(String uid, String token);

   // --- User Lookup ---
   Future<UserProfile?> findUserByEmail(String email); // Add this
}
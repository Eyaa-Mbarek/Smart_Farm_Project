import 'package:smart_farm_test/domain/entities/user_profile.dart'; // Adjust import path

abstract class IUserRepository {
   // Watch user profile changes
   Stream<UserProfile> watchUserProfile(String uid);
   // Get user profile once
   Future<UserProfile> getUserProfile(String uid);
   // Update user profile data (e.g., username)
   Future<void> updateUserProfile(String uid, Map<String, dynamic> data);

   // --- Device List Management ---
   Future<void> addDeviceToMonitored(String uid, String deviceId);
   Future<void> removeDeviceFromMonitored(String uid, String deviceId);

   // These are typically managed internally during device registration/sharing
   Future<void> addDeviceToOwned(String uid, String deviceId);
   Future<void> addDeviceToAccessible(String uid, String deviceId, String ownerUid);
   // Maybe methods to remove from owned/accessible if needed (e.g., device deletion)

   // --- FCM Token Management --- (If re-enabling FCM)
   Future<void> addFcmToken(String uid, String token);
   Future<void> removeFcmToken(String uid, String token);
}
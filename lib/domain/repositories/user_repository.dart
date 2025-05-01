import 'package:smart_farm_test/domain/entities/user_profile.dart';

abstract class IUserRepository {
   // Watch user profile changes
   Stream<UserProfile> watchUserProfile(String uid);
   // Get user profile once
   Future<UserProfile> getUserProfile(String uid);
   // Update user profile data
   Future<void> updateUserProfile(String uid, Map<String, dynamic> data);
   // Specifically update monitored blocks
   Future<void> updateMonitoredBlocks(String uid, List<String> blockIds);
}
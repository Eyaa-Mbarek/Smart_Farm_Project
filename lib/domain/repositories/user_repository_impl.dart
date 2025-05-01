import 'package:smart_farm_test/data/datasources/firestore_datasource.dart';
import 'package:smart_farm_test/domain/entities/user_profile.dart';
import 'package:smart_farm_test/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements IUserRepository {
  final FirestoreDataSource _dataSource;
  UserRepositoryImpl(this._dataSource);

  @override
  Stream<UserProfile> watchUserProfile(String uid) {
    return _dataSource.watchUserProfile(uid);
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
    return _dataSource.updateUserProfile(uid, data);
  }

   @override
  Future<void> updateMonitoredBlocks(String uid, List<String> blockIds) {
     return _dataSource.updateMonitoredBlocks(uid, blockIds);
  }
}
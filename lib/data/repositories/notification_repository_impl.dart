import 'package:smart_farm_test/data/datasources/firestore_datasource.dart';
import 'package:smart_farm_test/domain/entities/notification_item.dart';
import 'package:smart_farm_test/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements INotificationRepository {
  final FirestoreDataSource _dataSource;
  NotificationRepositoryImpl(this._dataSource);

  @override
  Stream<List<NotificationItem>> watchNotifications(String uid) {
    return _dataSource.watchNotifications(uid);
  }

  @override
  Future<void> addNotification(
    String uid, {
    required String title,
    required String body,
    String? blocId,
  }) {
    // THIS is the map being passed to the datasource
    final data = {
      'title': title, // String - OK
      'body': body, // String - OK
      if (blocId != null) 'blocId': blocId, // String? - OK
      // We are NOT adding timestamp or read here, datasource does it.
      // IS THERE ANY OTHER FIELD ACCIDENTALLY ADDED HERE?
    };
    // Check what's actually in 'data' right before passing
    print("NotificationRepositoryImpl: Passing data to datasource: $data");
    return _dataSource.addNotification(uid, data); // Passing the 'data' map
  }

  @override
  Future<void> markNotificationAsRead(String uid, String notificationId) {
    return _dataSource.markNotificationAsRead(uid, notificationId);
  }

  @override
  Future<void> deleteNotification(String uid, String notificationId) {
    return _dataSource.deleteNotification(uid, notificationId);
  }
}

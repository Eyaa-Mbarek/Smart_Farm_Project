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
  Future<void> addNotification(String uid, {required String title, required String body, String? blocId}) {
     final data = {
        'title': title,
        'body': body,
        if (blocId != null) 'blocId': blocId,
        // timestamp and read status are handled by datasource
     };
     return _dataSource.addNotification(uid, data);
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
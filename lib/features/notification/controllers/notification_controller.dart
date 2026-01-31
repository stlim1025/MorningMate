import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../data/models/notification_model.dart';

class NotificationController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  // 특정 친구에게 보낸 응원 메시지 목록 가져오기
  Stream<List<NotificationModel>> getSentMessagesStream(
      String senderId, String receiverId) {
    return _db
        .collection('notifications')
        .where('senderId', isEqualTo: senderId)
        .where('userId', isEqualTo: receiverId)
        .where('type', isEqualTo: 'cheerMessage')
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return messages;
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAsReplied(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'isReplied': true, 'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  Future<void> markAllAsRead(String userId) async {
    final unreadSnapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadSnapshot.docs.isEmpty) {
      return;
    }

    final batch = _db.batch();
    for (final doc in unreadSnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // 응원 메시지(방명록) 보내기 -> 알림 생성
  Future<void> sendCheerMessage(
      String senderId, String senderNickname, String receiverId, String message,
      {bool fcmSent = false}) async {
    final notificationRef = _db.collection('notifications').doc();

    final notification = NotificationModel(
      id: notificationRef.id,
      userId: receiverId,
      senderId: senderId,
      senderNickname: senderNickname,
      type: NotificationType.cheerMessage,
      message: '친구가 응원 메시지를 보냈어요.\n$message',
      createdAt: DateTime.now(),
      isRead: false,
      fcmSent: fcmSent,
    );

    await notificationRef.set(notification.toFirestore());
  }

  // 친구 깨우기 알림 보내기 (중복 방지 로직 포함 가능)
  Future<void> sendWakeUpNotification(
      String senderId, String senderNickname, String receiverId,
      {bool fcmSent = false}) async {
    // 오늘 이미 보낸 깨우기 알림이 있는지 확인? (선택사항)

    final notificationRef = _db.collection('notifications').doc();
    final notification = NotificationModel(
      id: notificationRef.id,
      userId: receiverId,
      senderId: senderId,
      senderNickname: senderNickname,
      type: NotificationType.wakeUp,
      message: '$senderNickname님이 당신을 깨우려고 합니다! ⏰',
      createdAt: DateTime.now(),
      isRead: false,
      fcmSent: fcmSent,
    );

    await notificationRef.set(notification.toFirestore());
  }
}

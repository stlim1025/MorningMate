import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../data/models/notification_model.dart';

class NotificationController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  // 응원 메시지(방명록) 보내기 -> 알림 생성
  Future<void> sendCheerMessage(String senderId, String senderNickname,
      String receiverId, String message) async {
    final notificationRef = _db.collection('notifications').doc();

    final notification = NotificationModel(
      id: notificationRef.id,
      userId: receiverId,
      senderId: senderId,
      senderNickname: senderNickname,
      type: NotificationType.cheerMessage,
      message: message,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await notificationRef.set(notification.toFirestore());
  }

  // 친구 깨우기 알림 보내기 (중복 방지 로직 포함 가능)
  Future<void> sendWakeUpNotification(
      String senderId, String senderNickname, String receiverId) async {
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
    );

    await notificationRef.set(notification.toFirestore());
  }
}

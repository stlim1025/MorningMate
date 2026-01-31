import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  wakeUp,
  friendRequest,
  cheerMessage,
  system,
}

class NotificationModel {
  final String id;
  final String userId; // 알림 받는 사람
  final String senderId; // 알림 보낸 사람
  final String senderNickname;
  final NotificationType type;
  final String message;
  final bool isRead;
  final bool fcmSent;
  final bool isReplied; // 답장 완료 여부
  final DateTime createdAt;
  final Map<String, dynamic>? data; // 추가 데이터 (친구 요청 ID 등)

  NotificationModel({
    required this.id,
    required this.userId,
    required this.senderId,
    required this.senderNickname,
    required this.type,
    required this.message,
    this.isRead = false,
    this.fcmSent = false,
    this.isReplied = false,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderNickname: data['senderNickname'] ?? '알 수 없음',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${data['type']}',
        orElse: () => NotificationType.system,
      ),
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      fcmSent: data['fcmSent'] ?? false,
      isReplied: data['isReplied'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: data['data'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'senderId': senderId,
      'senderNickname': senderNickname,
      'type': type.toString().split('.').last,
      'message': message,
      'isRead': isRead,
      'fcmSent': fcmSent,
      'isReplied': isReplied,
      'createdAt': Timestamp.fromDate(createdAt),
      'data': data,
    };
  }
}

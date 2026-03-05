import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';

enum NotificationType {
  wakeUp,
  friendRequest,
  friendAccept,
  friendReject,
  cheerMessage,
  system,
  challenge,
  nestInvite,
  nestDonation,
  nestPoke,
  nestUpgrade,
  referralReward,
  memoLike,
  reportResult,
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

  String getLocalizedMessage(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return message;

    final name = senderNickname;
    final String nestName = data?['nestName']?.toString() ?? '둥지';
    final String amount = data?['amount']?.toString() ?? '0';
    final String level = data?['level']?.toString() ?? '1';
    final String duration = data?['duration']?.toString() ?? '';
    final String reason = data?['reason']?.toString() ?? '';

    switch (type) {
      case NotificationType.wakeUp:
        return loc.getFormat('notiMsgWakeUp', {'name': name});
      case NotificationType.nestPoke:
        return loc.getFormat(
            'notiMsgWakeUpPoke', {'name': name, 'nestName': nestName});
      case NotificationType.friendRequest:
        return loc.getFormat('notiMsgFriendRequest', {'name': name});
      case NotificationType.friendAccept:
        return loc.getFormat('notiMsgFriendAccept', {'name': name});
      case NotificationType.friendReject:
        if (data?['isSender'] == true) {
          return loc.getFormat('notiMsgFriendRejectSent', {'name': name});
        }
        return loc.getFormat('notiMsgFriendReject', {'name': name});
      case NotificationType.cheerMessage:
        final dynamic isReplyVal = data?['isReply'];
        final bool isReply = isReplyVal == true || isReplyVal == 'true';
        if (isReply) {
          return loc.getFormat(
              'notiMsgReplyWithContent', {'name': name, 'message': message});
        }
        return loc.getFormat(
            'notiMsgCheerWithContent', {'name': name, 'message': message});
      case NotificationType.nestInvite:
        return loc.getFormat(
            'notiMsgNestInvite', {'name': name, 'nestName': nestName});
      case NotificationType.nestDonation:
        return loc.getFormat('notiMsgNestDonation',
            {'name': name, 'nestName': nestName, 'amount': amount});
      case NotificationType.nestUpgrade:
        return loc.getFormat(
            'notiMsgNestUpgrade', {'nestName': nestName, 'level': level});
      case NotificationType.memoLike:
        return loc.getFormat('notiMsgMemoLike', {'name': name});
      case NotificationType.reportResult:
        if (data?['status'] == 'resolved') {
          return loc.getFormat('notiMsgReportResultDone', {});
        } else if (data?['status'] == 'suspended') {
          return loc
              .getFormat('notiMsgReportResultSuspend', {'duration': duration});
        } else if (data?['status'] == 'rejected') {
          return loc.getFormat('notiMsgReportResultReject', {'reason': reason});
        }
        return message;
      case NotificationType.system:
        if (data?['systemType'] == 'inviteAccept') {
          return loc
              .getFormat('notiMsgNestInviteAccept', {'nestName': nestName});
        } else if (data?['systemType'] == 'inviteReject') {
          return loc
              .getFormat('notiMsgNestInviteReject', {'nestName': nestName});
        } else if (data?['systemType'] == 'violator') {
          return loc.getFormat('notiMsgReportViolator', {});
        }
        // Fallback: detect legacy notifications by Korean message patterns
        if (message.contains('둥지 초대를 수락')) {
          return loc
              .getFormat('notiMsgNestInviteAccept', {'nestName': nestName});
        } else if (message.contains('둥지 초대를 거절')) {
          return loc
              .getFormat('notiMsgNestInviteReject', {'nestName': nestName});
        } else if (message.contains('친구가 되었습니다')) {
          return loc.getFormat('notiMsgFriendAccept', {'name': senderNickname});
        } else if (message.contains('친구 요청을 거절')) {
          return loc.getFormat('notiMsgFriendReject', {'name': senderNickname});
        } else if (message.contains('커뮤니티 가이드라인 위반')) {
          return loc.getFormat('notiMsgReportViolator', {});
        }
        return message;
      case NotificationType.challenge:
        final String? titleKey = data?['challengeTitleKey']?.toString();
        final String reward = data?['reward']?.toString() ?? '';
        final challengeCompleted = loc.get('challengeCompleted');
        final branch = loc.get('branch');
        if (titleKey != null && titleKey.isNotEmpty) {
          final title = loc.get(titleKey);
          return reward.isNotEmpty
              ? '$challengeCompleted: $title (+$reward $branch)'
              : '$challengeCompleted: $title';
        }
        // Legacy fallback: message already contains localized text or Korean
        // Try to extract challenge title from "도전과제 달성!: <title>" pattern
        if (message.contains(': ')) {
          final parts = message.split(': ');
          if (parts.length >= 2) {
            String extractedTitle = parts.sublist(1).join(': ');
            // If we are in English, try to translate common Korean titles
            if (loc.locale.languageCode == 'en') {
              final Map<String, String> titles = {
                '새벽의 시작': 'Start of Dawn',
                '꾸준한 습관': 'Steady Habit',
                '진정한 아침형 인간': 'True Morning Person',
                '2주 연속 기록': '14-Day Streak',
                '3주 연속 기록': '21-Day Streak',
                '한 달의 기적': 'One Month Miracle',
                '첫 친구': 'First Friend',
                '마당 넓은 주인': 'Social King',
                '인기쟁이': 'Popular Person',
                '마당발': 'Wide Network',
                '첫 소품': 'First Prop Purchase',
                '풍성한 방': 'Decorated Room',
                '꾸미기 꿈나무': '5 Props Collection',
                '맥시멀리스트': '10 Props Collection',
                '패셔니스타': 'Fashionista',
                '트렌드세터': 'Trendsetter',
                '기분 전환': 'Atmosphere Change',
                '분위기 메이커': 'Mood Maker',
                '첫 성장': 'Growing Character Lv.2',
                '쑥쑥 성장': 'Growing Character Lv.3',
                '거의 다 왔어': 'Growing Character Lv.4',
                '폭풍 성장': 'Growing Character Lv.5',
                '첫 메모': 'First Memo',
                '메모 수집가': 'Memo Collector',
                '메모 매니아': 'Memo Mania',
                '메모 마스터': 'Memo Master',
                '일기의 달인': 'Record Master',
              };
              // Check for exact match or if it contains the reward suffix
              for (var entry in titles.entries) {
                if (extractedTitle.contains(entry.key)) {
                  extractedTitle =
                      extractedTitle.replaceFirst(entry.key, entry.value);
                  // Also handle reward translation if present
                  extractedTitle =
                      extractedTitle.replaceFirst('가지', 'branches');
                  break;
                }
              }
            }
            return '$challengeCompleted: $extractedTitle';
          }
        }
        return message;
      case NotificationType.referralReward:
        return loc.getFormat('notiMsgReferralReward', {});
    }
  }
}

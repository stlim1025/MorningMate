import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nest_model.dart';
import '../data/models/user_model.dart';

class NestService {
  FirebaseFirestore get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('NestService: FirebaseFirestore 인스턴스 획득 실패 (Firebase 미초기화)');
      rethrow;
    }
  }

  CollectionReference get _nestsCollection {
    try {
      return _db.collection('nests');
    } catch (e) {
      rethrow;
    }
  }

  CollectionReference get _invitesCollection {
    try {
      return _db.collection('nest_invites');
    } catch (e) {
      rethrow;
    }
  }

  // 둥지 생성 (사용자당 최대 2개 제한 등은 Controller에서 처리)
  Future<String> createNest(String name, String creatorId) async {
    final newNest = NestModel(
      id: '',
      name: name,
      creatorId: creatorId,
      memberIds: [creatorId], // 생성자는 기본 멤버
      createdAt: DateTime.now(),
      lastActivityAt: DateTime.now(),
    );

    final docRef = await _nestsCollection.add(newNest.toMap());

    // 사용자 문서에 둥지 ID 추가
    await _db.collection('users').doc(creatorId).update({
      'nestIds': FieldValue.arrayUnion([docRef.id])
    });

    return docRef.id;
  }

  // 둥지 정보 업데이트 (이름, 설명)
  Future<void> updateNest(
      String nestId, String name, String description) async {
    await _nestsCollection.doc(nestId).update({
      'name': name,
      'description': description,
      'lastActivityAt': FieldValue.serverTimestamp(),
    });
  }

  // 둥지 목록 가져오기 (사용자가 속한 둥지)
  Stream<List<NestModel>> getUserNestsStream(String userId) {
    return _nestsCollection
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NestModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // 단일 둥지 정보 가져오기 스트림
  Stream<NestModel?> getNestStream(String nestId) {
    return _nestsCollection.doc(nestId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return NestModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // 가지 기부하기
  Future<void> donateGaji(String nestId, String userId, String senderNickname,
      String nestName, int amount) async {
    final batch = _db.batch();

    // 유저 가지 차감
    final userRef = _db.collection('users').doc(userId);
    batch.update(userRef, {
      'points': FieldValue.increment(-amount),
    });

    // 둥지 가지 증가 및 마지막 활동 시간 업데이트
    final nestRef = _nestsCollection.doc(nestId);
    batch.update(nestRef, {
      'totalGaji': FieldValue.increment(amount),
      'lastActivityAt': FieldValue.serverTimestamp(),
    });

    // 둥지 멤버들에게 알림 보내기
    final nestDoc = await nestRef.get();
    if (nestDoc.exists) {
      final data = nestDoc.data() as Map<String, dynamic>?;
      final memberIds = List<String>.from(data?['memberIds'] ?? []);
      for (final memberId in memberIds) {
        if (memberId == userId) continue; // 본인에게는 알림을 보내지 않음

        // 이미 10개 이상이면 batch commit 후 새 batch?
        // 둥지 정원이 20명이므로 20개 알림 + 2개 업데이트 = 22개. 500개 제한이므로 한 배치에 가능.

        final notificationRef = _db.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': memberId,
          'senderId': userId,
          'senderNickname': senderNickname,
          'type': 'nestDonation',
          'message':
              '[$nestName] 둥지에서 $senderNickname님이 가지 ${amount}개를 기부했습니다!',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'data': {
            'nestId': nestId,
            'nestName': nestName,
            'amount': amount,
          },
        });
      }
    }

    await batch.commit();
  }

  // 오늘의 한마디 작성하기
  Future<void> postNestMessage(String nestId, String userId,
      String senderNickname, String nestName, String message) async {
    final batch = _db.batch();

    // 둥지 마지막 활동 시간 업데이트
    final nestRef = _nestsCollection.doc(nestId);
    batch.update(nestRef, {
      'lastActivityAt': FieldValue.serverTimestamp(),
    });

    // 둥지 멤버들에게 알림 보내기
    final nestDoc = await nestRef.get();
    if (nestDoc.exists) {
      final data = nestDoc.data() as Map<String, dynamic>?;
      final memberIds = List<String>.from(data?['memberIds'] ?? []);
      for (final memberId in memberIds) {
        if (memberId == userId) continue;

        final notificationRef = _db.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': memberId,
          'senderId': userId,
          'senderNickname': senderNickname,
          'type': 'cheerMessage',
          'message': '[$nestName] $senderNickname님이 한마디를 남겼습니다: $message',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'data': {
            'nestId': nestId,
            'nestName': nestName,
            'message': message,
          },
        });
      }
    }

    await batch.commit();
  }

  // 특정 둥지의 멤버 정보 스트림
  Stream<List<UserModel>> getNestMembersStream(String nestId) {
    // ignore: close_sinks
    StreamController<List<UserModel>>? controller;
    StreamSubscription? nestSub;
    StreamSubscription? usersSub;

    controller = StreamController<List<UserModel>>(
      onListen: () {
        nestSub = _nestsCollection.doc(nestId).snapshots().listen((nestDoc) {
          if (!nestDoc.exists) {
            controller?.add([]);
            return;
          }
          final data = nestDoc.data() as Map<String, dynamic>;
          final memberIds = List<String>.from(data['memberIds'] ?? []);

          if (memberIds.isEmpty) {
            controller?.add([]);
            return;
          }

          // memberIds가 변경될 때만 users 구독을 새로 시작
          usersSub?.cancel();
          usersSub = _db
              .collection('users')
              .where(FieldPath.documentId, whereIn: memberIds)
              .snapshots()
              .listen((snapshot) {
            final users =
                snapshot.docs.map((d) => UserModel.fromFirestore(d)).toList();

            users.sort((a, b) {
              return memberIds
                  .indexOf(a.uid)
                  .compareTo(memberIds.indexOf(b.uid));
            });

            if (controller?.isClosed == false) {
              controller?.add(users);
            }
          });
        });
      },
      onCancel: () {
        nestSub?.cancel();
        usersSub?.cancel();
      },
    );

    return controller.stream;
  }

  // 둥지 초대 보내기
  Future<void> inviteToNest(String nestId, String nestName, String senderId,
      String receiverId) async {
    final nestDoc = await _nestsCollection.doc(nestId).get();
    if (nestDoc.exists) {
      final nest =
          NestModel.fromMap(nestId, nestDoc.data() as Map<String, dynamic>);
      if (nest.memberIds.contains(receiverId)) {
        throw Exception('이미 둥지에 가입된 멤버입니다.');
      }
      // 레벨 1 가입 제한 (10명)
      if (nest.level == 1 && nest.memberIds.length >= 10) {
        throw Exception('nestFullError');
      }
    }

    final existingInviteQuery = await _invitesCollection
        .where('nestId', isEqualTo: nestId)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingInviteQuery.docs.isNotEmpty) {
      throw Exception('이미 초대를 보낸 상태입니다.');
    }

    final inviteRef = await _invitesCollection.add({
      'nestId': nestId,
      'nestName': nestName,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 알림 생성
    final senderSnapshot = await _db.collection('users').doc(senderId).get();
    final senderNickname = senderSnapshot.exists
        ? (senderSnapshot.data() as Map<String, dynamic>)['nickname'] ??
            '알 수 없음'
        : '알 수 없음';

    await _db.collection('notifications').add({
      'userId': receiverId,
      'senderId': senderId,
      'senderNickname': senderNickname,
      'type': 'nestInvite',
      'message': '$senderNickname님이 \'$nestName\' 둥지에 초대했습니다!',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'inviteId': inviteRef.id,
        'nestId': nestId,
        'nestName': nestName,
      },
    });
  }

  // 둥지 초대 수락
  Future<void> acceptNestInvite(
      String inviteId, String nestId, String userId) async {
    // 둥지 정원 확인
    final nestDoc = await _nestsCollection.doc(nestId).get();
    if (nestDoc.exists) {
      final data = nestDoc.data() as Map<String, dynamic>;
      final level = (data['level'] as num?)?.toInt() ?? 1;
      final memberIds = List<String>.from(data['memberIds'] ?? []);

      // 레벨 1 가입 제한 (10명)
      if (level == 1 && memberIds.length >= 10) {
        throw Exception('nestFullError');
      }
    }

    final batch = _db.batch();

    // 1. 초대 상태 업데이트
    final inviteRef = _invitesCollection.doc(inviteId);
    batch.update(inviteRef, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    // 2. 둥지 멤버 목록에 추가
    final nestRef = _nestsCollection.doc(nestId);
    batch.update(nestRef, {
      'memberIds': FieldValue.arrayUnion([userId]),
      'lastActivityAt': FieldValue.serverTimestamp(),
    });

    // 3. 사용자 문서에 nestId 추가
    final userRef = _db.collection('users').doc(userId);
    batch.update(userRef, {
      'nestIds': FieldValue.arrayUnion([nestId]),
    });

    // 4. 알림 업데이트
    final notificationsSnapshot = await _db
        .collection('notifications')
        .where('type', isEqualTo: 'nestInvite')
        .where('data.inviteId', isEqualTo: inviteId)
        .get();

    for (var doc in notificationsSnapshot.docs) {
      final data = doc.data();
      final nestName = data['data']?['nestName'] ?? '둥지';
      batch.update(doc.reference, {
        'message': '\'$nestName\' 둥지 초대를 수락했습니다.',
        'type': 'system',
        'isRead': true,
      });
    }

    await batch.commit();
  }

  // 둥지 초대 거절
  Future<void> rejectNestInvite(String inviteId) async {
    final batch = _db.batch();

    // 1. 초대 상태 업데이트
    final inviteRef = _invitesCollection.doc(inviteId);
    batch.update(inviteRef, {
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    // 2. 알림 업데이트
    final notificationsSnapshot = await _db
        .collection('notifications')
        .where('type', isEqualTo: 'nestInvite')
        .where('data.inviteId', isEqualTo: inviteId)
        .get();

    for (var doc in notificationsSnapshot.docs) {
      final data = doc.data();
      final nestName = data['data']?['nestName'] ?? '둥지';
      batch.update(doc.reference, {
        'message': '\'$nestName\' 둥지 초대를 거절했습니다.',
        'type': 'system',
        'isRead': true,
      });
    }

    await batch.commit();
  }

  // 받은 둥지 초대 스트림
  Stream<List<Map<String, dynamic>>> getReceivedNestInvitesStream(
      String userId) {
    return _invitesCollection
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> invites = [];
      for (var doc in snapshot.docs) {
        final senderId = doc['senderId'] as String;
        final senderSnapshot =
            await _db.collection('users').doc(senderId).get();

        if (senderSnapshot.exists) {
          final sender = UserModel.fromFirestore(senderSnapshot);
          invites.add({
            'inviteId': doc.id,
            'nestId': doc['nestId'],
            'nestName': doc['nestName'],
            'sender': sender,
            'createdAt': (doc['createdAt'] as Timestamp?)?.toDate(),
          });
        }
      }
      return invites;
    });
  }

  // 둥지 삭제 (방장 권한)
  Future<void> deleteNest(String nestId) async {
    final nestDoc = await _nestsCollection.doc(nestId).get();
    if (!nestDoc.exists) return;

    final memberIds = List<String>.from(nestDoc['memberIds'] ?? []);
    final batch = _db.batch();

    // 모든 멤버의 nestIds에서 이 둥지 ID 제거
    for (final memberId in memberIds) {
      batch.update(_db.collection('users').doc(memberId), {
        'nestIds': FieldValue.arrayRemove([nestId])
      });
    }

    // 둥지 문서 삭제
    batch.delete(_nestsCollection.doc(nestId));

    // 이 둥지와 관련된 모든 펜딩 초대 삭제 (선택적이지만 깔끔함을 위해)
    final invites =
        await _invitesCollection.where('nestId', isEqualTo: nestId).get();
    for (var doc in invites.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // 둥지 나가기 (멤버 권한)
  Future<void> leaveNest(String nestId, String userId) async {
    final batch = _db.batch();

    // 사용자의 nestIds에서 둥지 ID 제거
    batch.update(_db.collection('users').doc(userId), {
      'nestIds': FieldValue.arrayRemove([nestId])
    });

    // 둥지의 memberIds에서 사용자 ID 제거
    batch.update(_nestsCollection.doc(nestId), {
      'memberIds': FieldValue.arrayRemove([userId])
    });

    await batch.commit();
  }

  // 둥지 업그레이드 (방장 권한)
  Future<void> upgradeNest(String nestId) async {
    final nestDoc = await _nestsCollection.doc(nestId).get();
    if (!nestDoc.exists) return;

    final data = nestDoc.data() as Map<String, dynamic>;
    final memberIds = List<String>.from(data['memberIds'] ?? []);
    final creatorId = data['creatorId'] ?? '';
    final nestName = data['name'] ?? '둥지';

    final batch = _db.batch();

    // 둥지 정보 업데이트
    batch.update(_nestsCollection.doc(nestId), {
      'level': 2,
      'totalGaji': FieldValue.increment(-1000), // 업그레이드 시 가지 1000개 사용
      'lastActivityAt': FieldValue.serverTimestamp(),
    });

    // 멤버들에게 알림 생성 (방장 제외)
    for (final memberId in memberIds) {
      if (memberId == creatorId) continue;

      final notificationRef = _db.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': memberId,
        'senderId': creatorId,
        'type': 'nestUpgrade',
        'message': '[$nestName] 둥지가 레벨 2로 업그레이드 되었습니다! 🎉',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'nestId': nestId,
          'nestName': nestName,
          'level': 2,
        },
      });
    }

    await batch.commit();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nest_model.dart';
import '../data/models/user_model.dart';

class NestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _nestsCollection => _db.collection('nests');
  CollectionReference get _invitesCollection => _db.collection('nest_invites');

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
    return _nestsCollection.doc(nestId).snapshots().asyncMap((doc) async {
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(data['memberIds'] ?? []);

      if (memberIds.isEmpty) return [];

      final membersQuery = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: memberIds.take(10).toList())
          .get();

      final users =
          membersQuery.docs.map((d) => UserModel.fromFirestore(d)).toList();

      // memberIds 순서대로 정렬하여 UI에서 위치가 고정되도록 함
      users.sort((a, b) {
        return memberIds.indexOf(a.uid).compareTo(memberIds.indexOf(b.uid));
      });

      return users;
    });
  }

  // 둥지 초대 보내기
  Future<void> inviteToNest(String nestId, String nestName, String senderId,
      String receiverId) async {
    // 중복 초대 및 이미 멤버인지 확인해야 함.
    final existingMemberQuery = await _nestsCollection.doc(nestId).get();
    if (existingMemberQuery.exists) {
      final nest = NestModel.fromMap(
          nestId, existingMemberQuery.data() as Map<String, dynamic>);
      if (nest.memberIds.contains(receiverId)) {
        throw Exception('이미 둥지에 가입된 멤버입니다.');
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
}

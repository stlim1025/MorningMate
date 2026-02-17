import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserEmail;

  String? get currentUserEmail => _currentUserEmail;

  AdminController(this._currentUserEmail);

  // 관리자 계정 이메일 목록 (간단한 하드코딩)
  static const List<String> _adminEmails = [
    'admin@morningmate.com',
    'admin@test.com'
  ];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> get reports => _reports;

  // 관리자 여부 확인
  bool get isAdmin {
    if (_currentUserEmail == null) return false;
    return _adminEmails.contains(_currentUserEmail);
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // 신고 목록 가져오기
  Future<void> fetchReports() async {
    if (_isDisposed) return;
    _isLoading = true;
    notifyListeners();

    try {
      // status가 pending인 것만 가져오거나 전체 가져오기
      // 여기서는 처리되지 않은(pending) 신고만 우선으로 본다고 가정하거나 전체를 보고 필터링
      final snapshot = await _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .get();

      if (_isDisposed) return;

      _reports = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Timestamp to DateTime 변환
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        return data;
      }).toList();
    } catch (e) {
      print('신고 목록 가져오기 오류: $e');
    }

    if (_isDisposed) return;
    _isLoading = false;
    notifyListeners();
  }

  // 상점 할인 정보
  Map<String, int> _shopDiscounts = {};
  Map<String, int> get shopDiscounts => _shopDiscounts;

  // 상점 할인 정보 가져오기
  Future<void> fetchShopDiscounts() async {
    if (_isDisposed) return;
    try {
      final doc = await _firestore.collection('settings').doc('shop').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['discounts'] != null) {
          _shopDiscounts = Map<String, int>.from(data['discounts']);
        }
      } else {
        _shopDiscounts = {};
      }
    } catch (e) {
      print('할인 정보 불러오기 오류: $e');
    }
    if (_isDisposed) return;
    notifyListeners();
  }

  // 할인 설정
  Future<void> setShopDiscount(String itemId, int price) async {
    _isLoading = true;
    notifyListeners();
    try {
      _shopDiscounts[itemId] = price;
      await _firestore.collection('settings').doc('shop').set({
        'discounts': _shopDiscounts,
      }, SetOptions(merge: true));
    } catch (e) {
      print('할인 설정 오류: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // 할인 해제
  Future<void> removeShopDiscount(String itemId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _shopDiscounts.remove(itemId);
      await _firestore.collection('settings').doc('shop').set({
        'discounts': _shopDiscounts,
      }, SetOptions(merge: true));
    } catch (e) {
      print('할인 해제 오류: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // 모든 할인 제거
  Future<void> removeAllShopDiscounts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _shopDiscounts.clear();
      await _firestore.collection('settings').doc('shop').set({
        'discounts': {},
      }, SetOptions(merge: true));
    } catch (e) {
      print('모든 할인 제거 오류: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // 신고 처리 (삭제) - 노트 삭제 및 신고 상태 변경 (resolved)
  Future<void> deleteNote(String reportId, String targetUserId, String noteId,
      String reporterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. 유저의 roomDecoration에서 해당 prop 삭제
        final userRef = _firestore.collection('users').doc(targetUserId);
        final userSnapshot = await transaction.get(userRef);

        if (userSnapshot.exists) {
          final userData = userSnapshot.data()!;
          if (userData['roomDecoration'] != null) {
            final decorationMap =
                Map<String, dynamic>.from(userData['roomDecoration']);
            final props =
                List<Map<String, dynamic>>.from(decorationMap['props'] ?? []);

            // 해당 ID의 prop 삭제
            props.removeWhere((prop) => prop['id'] == noteId);
            decorationMap['props'] = props;

            transaction.update(userRef, {'roomDecoration': decorationMap});
          }
        }

        // 2. Memos 컬렉션에서 삭제 (아카이브용 컬렉션이 있다면)
        final memoRef = _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('memos')
            .doc(noteId);
        transaction.delete(memoRef);

        // 3. 신고 상태 업데이트
        final reportRef = _firestore.collection('reports').doc(reportId);
        transaction.update(reportRef, {'status': 'resolved'});

        // 4. 알림 전송 (신고자)
        final reporterNotiRef = _firestore.collection('notifications').doc();
        transaction.set(reporterNotiRef, {
          'userId': reporterId,
          'type': 'reportResult',
          'message': '신고하신 메모가 삭제 조치되었습니다. 건전한 커뮤니티를 위해 힘써주셔서 감사합니다.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 5. 알림 전송 (위반자)
        final violatorNotiRef = _firestore.collection('notifications').doc();
        transaction.set(violatorNotiRef, {
          'userId': targetUserId,
          'type': 'system',
          'message': '작성하신 메모가 신고 접수되어 커뮤니티 가이드라인 위반으로 삭제되었습니다.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // 목록 새로고침
      await fetchReports();
    } catch (e) {
      print('노트 삭제 오류: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // 신고 반려 (Reject) - 반려 사유 알림 전송 및 신고 상태 변경 (rejected)
  Future<void> rejectReport(
      String reportId, String reporterId, String rejectReason) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. 알림 전송 (Firestore Notification)
      await _firestore.collection('notifications').add({
        'userId': reporterId, // 신고자에게 알림
        'type': 'reportResult', // 신고 결과 알림으로 처리
        'message': '신고가 반려되었습니다. 사유: $rejectReason',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. 신고 상태 업데이트
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'rejected',
        'rejectReason': rejectReason,
      });

      // 목록 새로고침
      await fetchReports();
    } catch (e) {
      print('신고 반려 오류: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  int _dailyVisitorCount = 0;
  int get dailyVisitorCount => _dailyVisitorCount;

  int _totalUserCount = 0;
  int get totalUserCount => _totalUserCount;

  Future<void> fetchStats() async {
    if (_isDisposed) return;

    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      // Daily Visitors
      final dailyQuery = await _firestore
          .collection('users')
          .where('lastLoginDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .count()
          .get();

      _dailyVisitorCount = dailyQuery.count ?? 0;

      // Total Users
      final totalQuery = await _firestore.collection('users').count().get();
      _totalUserCount = totalQuery.count ?? 0;
    } catch (e) {
      print('통계 불러오기 오류: $e');
    }

    if (_isDisposed) return;
    notifyListeners();
  }
}

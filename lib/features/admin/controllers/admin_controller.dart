import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../services/question_service.dart';

class AdminController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final QuestionService _questionService = QuestionService();
  final String? _currentUserEmail;

  String? get currentUserEmail => _currentUserEmail;

  AdminController(this._currentUserEmail);

  static const List<String> _adminEmails = [
    'admin@morningmate.com',
    'admin@test.com'
  ];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> get reports => _reports;

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

  Future<void> fetchReports() async {
    if (_isDisposed) return;
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .get();

      if (_isDisposed) return;

      _reports = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        return data;
      }).toList();
    } catch (e) {
      debugPrint('신고 목록 가져오기 오류: $e');
    }

    if (_isDisposed) return;
    _isLoading = false;
    notifyListeners();
  }

  Map<String, int> _shopDiscounts = {};
  Map<String, int> get shopDiscounts => _shopDiscounts;

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
      debugPrint('할인 정보 불러오기 오류: $e');
    }
    if (_isDisposed) return;
    notifyListeners();
  }

  Future<void> setShopDiscount(String itemId, int price) async {
    _isLoading = true;
    notifyListeners();
    try {
      _shopDiscounts[itemId] = price;
      await _firestore.collection('settings').doc('shop').set({
        'discounts': _shopDiscounts,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('할인 설정 오류: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> removeShopDiscount(String itemId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _shopDiscounts.remove(itemId);
      await _firestore.collection('settings').doc('shop').set({
        'discounts': _shopDiscounts,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('할인 해제 오류: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> removeAllShopDiscounts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _shopDiscounts.clear();
      await _firestore.collection('settings').doc('shop').set({
        'discounts': {},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('모든 할인 제거 오류: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteNote(String reportId, String targetUserId, String noteId,
      String reporterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(targetUserId);
        final userSnapshot = await transaction.get(userRef);

        if (userSnapshot.exists) {
          final userData = userSnapshot.data()!;
          if (userData['roomDecoration'] != null) {
            final decorationMap =
                Map<String, dynamic>.from(userData['roomDecoration']);
            final props =
                List<Map<String, dynamic>>.from(decorationMap['props'] ?? []);
            props.removeWhere((prop) => prop['id'] == noteId);
            decorationMap['props'] = props;
            transaction.update(userRef, {'roomDecoration': decorationMap});
          }
        }

        final memoRef = _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('memos')
            .doc(noteId);
        transaction.delete(memoRef);

        final reportRef = _firestore.collection('reports').doc(reportId);
        transaction.update(reportRef, {'status': 'resolved'});

        final reporterNotiRef = _firestore.collection('notifications').doc();
        transaction.set(reporterNotiRef, {
          'userId': reporterId,
          'type': 'reportResult',
          'message': '신고하신 메모가 삭제 조치되었습니다. 건전한 커뮤니티를 위해 힘써주셔서 감사합니다.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final violatorNotiRef = _firestore.collection('notifications').doc();
        transaction.set(violatorNotiRef, {
          'userId': targetUserId,
          'type': 'system',
          'message': '작성하신 메모가 신고 접수되어 커뮤니티 가이드라인 위반으로 삭제되었습니다.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      await fetchReports();
    } catch (e) {
      debugPrint('노트 삭제 오류: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> rejectReport(
      String reportId, String reporterId, String rejectReason) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.collection('notifications').add({
        'userId': reporterId,
        'type': 'reportResult',
        'message': '신고가 반려되었습니다. 사유: $rejectReason',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('reports').doc(reportId).update({
        'status': 'rejected',
        'rejectReason': rejectReason,
      });

      await fetchReports();
    } catch (e) {
      debugPrint('신고 반려 오류: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> suspendUser({
    required String reportId,
    required String targetUserId,
    required String reporterId,
    required int days,
    String? reason,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(targetUserId);
        final reporterRef = _firestore.collection('users').doc(reporterId);
        final reportRef = _firestore.collection('reports').doc(reportId);

        // 1. 모든 읽기(Read) 작업은 처음에 수행해야 함
        final reporterSnapshot = await transaction.get(reporterRef);

        // 2. 데이터 계산
        DateTime suspendedUntil;
        String durationStr;

        if (days == -1) {
          suspendedUntil = DateTime(2099, 12, 31); // Permanent
          durationStr = '영구';
        } else {
          suspendedUntil = DateTime.now().add(Duration(days: days));
          durationStr = '${days}일';
        }

        // 3. 쓰기(Write) 작업 수행
        transaction.update(userRef, {
          'suspendedUntil': Timestamp.fromDate(suspendedUntil),
          'suspensionReason': reason ?? '커뮤니티 가이드라인 위반',
        });

        transaction.update(reportRef, {'status': 'resolved'});

        final reporterNotiRef = _firestore.collection('notifications').doc();
        transaction.set(reporterNotiRef, {
          'userId': reporterId,
          'type': 'reportResult',
          'message':
              '신고하신 회원이 $durationStr 정지 처리되었습니다. 보상으로 100가지가 지급되었습니다. 건전한 커뮤니티를 위해 힘써주셔서 감사합니다.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 신고자 보상 (100가지)
        if (reporterSnapshot.exists) {
          final currentPoints = reporterSnapshot.data()?['points'] ?? 0;
          transaction.update(reporterRef, {'points': currentPoints + 100});
        }
      });
      await fetchReports();
    } catch (e) {
      debugPrint('사용자 정지 오류: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // 사용자 관리 기능
  List<UserModel> _allUsers = [];
  List<UserModel> get allUsers => _allUsers;
  String? _searchQuery;
  String? get searchQuery => _searchQuery;
  DocumentSnapshot? _lastUserDoc;
  bool _hasMoreUsers = true;
  bool get hasMoreUsers => _hasMoreUsers;

  Future<void> fetchUsers({bool isRefresh = false, String? searchQuery}) async {
    if (_isLoading) return;
    if (!isRefresh && !_hasMoreUsers && searchQuery == _searchQuery) return;

    // 검색어 변경 시 초기화
    if (searchQuery != _searchQuery) {
      isRefresh = true;
      _searchQuery = searchQuery;
    }

    _isLoading = true;
    notifyListeners();

    try {
      Query query = _firestore.collection('users');

      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        // 닉네임 전방 일치 검색
        query = query
            .where('nickname', isGreaterThanOrEqualTo: _searchQuery)
            .where('nickname', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
            .orderBy('nickname');
      } else {
        query = query.orderBy('createdAt', descending: true);
      }

      query = query.limit(20);

      if (!isRefresh && _lastUserDoc != null) {
        query = query.startAfterDocument(_lastUserDoc!);
      }

      final snapshot = await query.get();

      if (isRefresh) {
        _allUsers = [];
        _lastUserDoc = null;
        _hasMoreUsers = true;
      }

      if (snapshot.docs.isNotEmpty) {
        final newUsers =
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        _allUsers.addAll(newUsers);
        _lastUserDoc = snapshot.docs.last;
        _hasMoreUsers = snapshot.docs.length == 20;
      } else {
        _hasMoreUsers = false;
      }
    } catch (e) {
      debugPrint('사용자 목록 가져오기 오류: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> unsuspendUser(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('users').doc(userId).update({
        'suspendedUntil': FieldValue.delete(),
        'suspensionReason': FieldValue.delete(),
      });

      _isLoading =
          false; // fetchUsers를 호출하기 전에 꺼주어서 fetchUsers 내부의 중복 실행 방지 로직을 통과하게 함
      await fetchUsers(isRefresh: true, searchQuery: _searchQuery);
    } catch (e) {
      debugPrint('정지 해제 오류: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserPoints(String userId, int points) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('users').doc(userId).update({
        'points': points,
      });

      _isLoading = false;
      await fetchUsers(isRefresh: true, searchQuery: _searchQuery);
    } catch (e) {
      debugPrint('가지 수정 오류: $e');
      _isLoading = false;
      notifyListeners();
    }
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
      final dailyQuery = await _firestore
          .collection('users')
          .where('lastLoginDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .count()
          .get();
      _dailyVisitorCount = dailyQuery.count ?? 0;

      final totalQuery = await _firestore.collection('users').count().get();
      _totalUserCount = totalQuery.count ?? 0;
    } catch (e) {
      debugPrint('통계 불러오기 오류: $e');
    }
    if (_isDisposed) return;
    notifyListeners();
  }

  // 전체 번역 맵 (100개+ 마스터 데이터)
  static const Map<String, String> questionTranslationMap = {
    // === 기존 50개 ===
    '지금 내 주변에서 가장 아름답게 느껴지는 사물이나 소리는?':
        'What objects or sounds around you feel the most beautiful right now?',
    '최근에 읽은 책이나 본 영상 중 기억에 남는 문구는?':
        'What is a memorable quote from a book you read or a video you watched recently?',
    '오늘 나에게 가장 필요한 위로 또는 격려는 무엇인가요?':
        'What comfort or encouragement do you need most today?',
    '나의 건강을 위해 오늘 할 수 있는 작은 행동 하나는?':
        'What is one small action you can do for your health today?',
    '오늘 하루가 지나기 전에 꼭 연락하고 싶은 사람이 있나요?':
        'Is there anyone you definitely want to contact before today is over?',
    '어제 꿈속에서 혹은 잠결에 느꼈던 특별한 감정이 있나요?':
        'Was there any special feeling you had in your dream or while sleeping yesterday?',
    '지금 내 기분을 색깔로 표현한다면 어떤 색일까요?':
        'If you were to express your mood right now in a color, what color would it be?',
    '내가 생각하는 \'행복한 하루\'의 정의는 무엇인가요?':
        'What is your definition of a \'happy day\'?',
    '오늘 하루를 무사히 마칠 수 있음에 대해 미리 감사해본다면?':
        'If you were to give thanks in advance for being able to finish today safely?',
    '내가 좋아하는 향기나 냄새를 오늘 떠올려 본다면?':
        'If you were to think of a scent or smell you like today?',
    '오늘 하루 중 나만의 온전한 휴식 시간은 몇 시인가요?':
        'What time today do you have for your own complete rest?',
    '어제의 나보다 오늘 조금 더 발전하고 싶은 부분은?':
        'What part of yourself do you want to develop a bit more today than yesterday?',
    '내가 존경하는 사람이 오늘 나의 모습이라면 어떻게 행동할까요?':
        'If the person I respect were in my shoes today, how would they act?',
    '내 주변 환경에서 오늘 소소한 변화를 주고 싶은 것은?':
        'What small change would I like to make to my surroundings today?',
    '오늘 하루가 끝나고 침대에 누웠을 때 어떤 기분을 느끼고 싶나요?':
        'What kind of feeling do you want to have when you lie in bed at the end of the day?',
    '오늘 마실 차나 커피 한 잔에 담고 싶은 마음은?':
        'What kind of heart do you want to put into a cup of tea or coffee you drink today?',
    '지금 내가 가장 간절히 바라는 소망 하나는 무엇인가요?':
        'What is the one wish that I most earnestly desire right now?',
    '오늘 저녁 식사로 무엇을 먹으며 행복을 느끼고 싶나요?':
        'What do you want to eat for dinner today and feel happy?',
    '오늘 하루 동안 나의 에너지를 가장 많이 쓰고 싶은 곳은?':
        'Where do you want to spend the most of your energy throughout the day today?',
    '오늘 하루 중 가장 평화로울 것 같은 시간은 언제인가요?':
        'When do you think will be the most peaceful time of your day today?',
    '오늘 나를 힘들게 할 것 같은 상황이 있다면 어떻게 대처할까요?':
        'How will I handle any situations that might make today difficult for me?',
    '내가 가장 좋아하는 계절의 분위기를 오늘 어떻게 느낄 수 있을까요?':
        'How can I feel the atmosphere of my favorite season today?',
    '내가 요즘 가장 몰입하고 있는 관심사는 무엇인가요?':
        'What is the interest that I am most immersed in these days?',
    '오늘 나의 패션이나 소품 중 가장 마음에 드는 포인트는?':
        'What is my favorite point of my fashion or accessories today?',
    '오늘 가장 완벽한 순간을 상상해본다면 어떤 모습일까요?':
        'What would my most perfect moment today look like if I were to imagine it?',
    '오늘 하루를 영화로 만든다면 어떤 장르였으면 좋겠나요?':
        'If today were made into a movie, what genre would I want it to be?',
    '어제 해결하지 못한 걱정이 있다면 어떻게 긍정적으로 바라볼까요?':
        'How can I look positively at any worries I couldn\'t resolve yesterday?',
    '오늘 꼭 완수하고 싶은 가장 중요한 일 하나는?':
        'What is the one most important thing I definitely want to complete today?',
    '오늘 하루 동안 내가 집중하고 싶은 단어 하나를 정한다면?':
        'If I were to choose one word to focus on throughout the day today?',
    '오늘 하루 동안 내가 도전해보고 싶은 아주 사소한 일은?':
        'What is a very small thing I want to challenge myself with today?',
    '오늘 누군가를 위해 할 수 있는 아주 작은 친절은?':
        'What is a small act of kindness you can do for someone today?',
    '어제 나를 가장 기쁘게 했던 일은 무엇인가요?': 'What made you the happiest yesterday?',
    '어제보다 오늘 더 향상시키고 싶은 나의 성격은?':
        'What part of your personality do you want to improve today more than yesterday?',
    '오늘 나에게 주는 작은 선물로 무엇을 선택하고 싶나요?':
        'What small gift would you like to give yourself today?',
    '오늘 내가 만날 사람들 중 가장 반가운 사람은 누구인가요?':
        'Who is the person you are most excited to meet today?',
    '지금 창밖의 풍경에서 발견할 수 있는 긍정적인 요소는?':
        'What is a positive element you can find in the view outside the window right now?',
    '나의 목표에 한 걸음 더 다가가기 위해 오늘 할 일은?':
        'What will you do today to get one step closer to your goal?',
    '세상에서 내가 가장 편안함을 느끼는 장소는 어디인가요?':
        'Where is the place where you feel the most comfortable in the world?',
    '내가 오늘 새롭게 배워보고 싶은 작은 지식이나 정보가 있나요?':
        'Is there any small piece of knowledge or information you want to learn today?',
    '누군가에게 오늘 전하고 싶은 따뜻한 감사의 말은?':
        'What warm words of gratitude do you want to convey to someone today?',
    '오늘 아침 가장 먼저 떠오른 생각은 무엇인가요?':
        'What was the very first thought that came to your mind this morning?',
    '나를 둘러싼 소중한 사람들 중 오늘 더 사랑을 표현하고 싶은 사람은?':
        'Of the precious people around you, who do you want to express more love to today?',
    '내가 가진 재능 중 오늘 더 빛내고 싶은 것은?':
        'Which of your talents do you want to shine more today?',
    '오늘 하루 동안 내가 피하고 싶은 부정적인 생각은?':
        'What negative thoughts do you want to avoid throughout the day today?',
    '나의 소소한 습관 중 오늘 꼭 지키고 싶은 것은?':
        'Which of your small habits do you definitely want to keep today?',
    '최근 나를 가장 크게 웃게 했던 일은 무엇인가요?':
        'What was the thing that made you laugh the most recently?',
    '오늘 하루를 시작하며 나에게 들려주고 싶은 노래는?':
        'What song do you want to play for yourself as you start the day today?',
    '내가 아끼는 물건이나 공간이 주는 의미는 무엇인가요?':
        'What is the meaning of the object or space you cherish?',
    '내가 어렸을 때 가졌던 꿈이 오늘 나의 삶에 어떤 영향을 주나요?':
        'How does the dream you had when you were young affect your life today?',
    '어제보다 오늘 더 성장하고 싶은 나의 모습은?':
        'In what way do you want to grow more today than yesterday?',
    '오늘 하루를 마무리하며 나에게 해주고 싶은 말은?':
        'What do you want to say to yourself at the end of the day?',
    '내가 오늘 가장 집중하고 싶은 일은 무엇인가요?':
        'What do you want to focus on the most today?',
    '오늘 나를 기쁘게 할 작은 계획이 있다면?':
        'What is a small plan that will make you happy today?',
    '오늘 내가 마주할 가장 큰 도전은 무엇일까요?':
        'What will be the biggest challenge you face today?',
    '나의 강점 중 오늘 가장 활용하고 싶은 부분은?':
        'Which of your strengths do you want to use the most today?',
    '오늘 하루 중 내가 가장 기대하는 시간은?':
        'What is the time of day you are most looking forward to today?',
    '내가 감사함을 느끼는 나의 신체 일부분은 어디인가요?':
        'What part of your body are you grateful for?',
    '오늘 내가 만난 풍경 중 가장 아름다운 것은?':
        'What was the most beautiful scenery you encountered today?',
    '나의 하루를 더 활기차게 만들어 줄 사소한 행동은?':
        'What small action will make your day more energetic?',
    '내 인생에서 가장 소중한 기억 중 하나를 떠올려 본다면?':
        'If you could recall one of the most precious memories in your life?',
    '오늘 내가 나 자신에게 허락하고 싶은 휴식은?':
        'What kind of rest do you want to allow yourself today?',
    '내가 오늘 하루 중 가장 많은 시간을 보낼 공간은 어디인가요?':
        'Where is the space where you will spend the most time today?',
    '오늘 내가 다른 사람에게 듣고 싶은 말은 무엇인가요?':
        'What do you want to hear from others today?',
    '나의 일상에서 당연하게 여겼던 것들 중 오늘 감사함을 느끼는 것은?':
        'Of the things you took for granted in your daily life, what are you grateful for today?',
    '내가 오늘 하루를 성공적으로 보냈다고 느킬 수 있는 기준은?':
        'What are the criteria for feeling that you spent today successfully?',
    '오늘 내가 버리고 싶은 마음의 짐이나 고민은?':
        'What mental burden or worry do you want to let go of today?',
    '내가 좋아하는 취미가 오늘 나의 기분에 어떤 영향을 주나요?':
        'How does your favorite hobby affect your mood today?',
    '오늘 내가 새롭게 만날 인연이나 상황에 대한 나의 기대는?':
        'What are your expectations for the new relationships or situations you will encounter today?',
    '나의 삶을 더욱 풍요롭게 만들어 주는 사소한 취향은?':
        'What are the small tastes that make your life richer?',
    '오늘 내가 나 자신을 위해 정성껏 준비하고 싶은 것은?':
        'What do you want to prepare carefully for yourself today?',
    '내가 오늘 실천하고 싶은 가장 솔직한 감정 표현은?':
        'What is the most honest expression of emotion you want to practice today?',
    '오늘 하루는 어땠나요?': 'How was your day?',
    '오늘 하루는 어떠셨나요?': 'How was your day?',
    '오늘 가장 고마웠던 사람은 누구인가요?': 'Who are you most grateful for today?',
    '오늘 나를 웃게 만든 일은 무엇인가요?': 'What made you smile today?',
    '오늘의 가장 행복했던 순간은 언제였나요?': 'When was the happiest moment today?',
    '오늘 배운 점이 있다면 무엇인가요?': 'What did you learn today?',
    '오늘의 나를 칭찬해주세요.': 'Please give yourself a compliment today.',
    '지금 이 순간 나 자신에게 해주고 싶은 칭찬 한마디는?':
        'What is one compliment you want to give yourself right now?',
    '오늘 가장 힘들었던 일은 무엇인가요?': 'What was the hardest thing today?',
    '지금 기분은 어떤가요?': 'How are you feeling right now?',
    '지금 기분이 어떤가요?': 'How are you feeling right now?',
    '오늘 하루를 한 단어로 표현한다면?': 'How would you describe today in one word?',
    '오늘 특별한 일이 있었나요?': 'Was there anything special today?',
    '내일 가장 기대되는 일은 무엇인가요?': 'What are you most looking forward to tomorrow?',
    '오늘 스스로를 위해 한 일은 무엇인가요?': 'What did you do for yourself today?',
    '오늘 마주친 기억에 남는 장면이 있나요?':
        'Is there a memorable scene you encountered today?',
    '오늘 하루 중 가장 평온했던 시간은 언제인가요?':
        'When was the most peaceful time of your day?',
    '오늘 날씨는 어땠나요?': 'How was the weather today?',
    '오늘 무엇을 먹었나요?': 'What did you eat today?',
    '오늘 가장 기억에 남는 대화는?': 'What was the most memorable conversation today?',
    '오늘 나의 기분 점수는 10점 만점에 몇 점인가요?':
        'On a scale of 1 to 10, how would you rate your mood today?',

    // === 신규 추가 50개 ===
    '오늘 아침 나를 미소 짓게 한 아주 작은 발견은?':
        'What was the tiny discovery that made you smile this morning?',
    '내가 어제보다 오늘 더 성숙해졌다고 느끼는 포인트는?':
        'In what way do you feel more mature today than yesterday?',
    '오늘 하루 중 내가 가장 창의적일 수 있는 시간은 언제인가요?':
        'When is the time of day you can be the most creative today?',
    '내가 요즘 가장 아끼는 노래의 가사 한 구절은?':
        'What is a line of lyrics from a song you cherish the most these days?',
    '오늘 나를 상쾌하게 만들어 줄 향기는 무엇인가요?':
        'What is the scent that will make you feel refreshed today?',
    '만약 오늘 내가 주인공인 세상이라면 어떤 일이 일어날까요?':
        'If today were a world where I am the main character, what would happen?',
    '내가 최근에 받은 친절 중 가장 기억에 남는 것은?':
        'What is the most memorable kindness you received recently?',
    '오늘 하루 동안 내가 꼭 지키고 싶은 고유한 성격은?':
        'What is the unique personality trait you definitely want to keep today?',
    '내 주변 공간에서 오늘 가장 먼저 정리하고 싶은 곳은?':
        'Where in your surrounding space do you want to organize first today?',
    '오늘 내가 시도해보고 싶은 새로운 음식이나 맛은?':
        'What is a new food or flavor you want to try today?',
    '내가 가진 것들 중 돈으로 환산할 수 없는 가치는 무엇인가요?':
        'What is a value you possess that cannot be converted into money?',
    '오늘 하루 동안 내가 느낄 수 있는 가장 평온한 감정은?':
        'What is the most peaceful emotion you can feel throughout the day today?',
    '오늘 아침 거울 속 나의 모습에게 해주고 싶은 말은?':
        'What do you want to say to your reflection in the mirror this morning?',
    '내가 최근에 경험한 사소하지만 확실한 행복은?':
        'What is a small but certain happiness you experienced recently?',
    '오늘 하루 중 내가 가장 에너지가 넘칠 순간은 언제일까요?':
        'When will be the moment you are most energetic today?',
    '오늘 내가 만날 사람들에게 어떤 인상을 남기고 싶나요?':
        'What kind of impression do you want to leave on the people you meet today?',
    '오늘 하루를 마치고 나를 위해 준비하고 싶은 보상은 무엇인가요?':
        'What is the reward you want to prepare for yourself after finishing today?',
    '오늘 하루 동안 내가 감사함을 표현할 수 있는 대상 3가지는?':
        'What are three things you can express gratitude for throughout the day today?',
    '만약 오늘 하루만 다른 사람이 될 수 있다면 누구의 삶을 살아볼까요?':
        'If I could be someone else for just today, whose life would I live?',
    '오늘 아침 내가 마신 물이나 차의 온도는 어떠했나요?':
        'How was the temperature of the water or tea you drank this morning?',
    '내가 오늘 하루 동안 꼭 실천하고 싶은 건강한 습관 하나는?':
        'What is one healthy habit you definitely want to practice today?',
    '오늘 내가 마주할 풍경 속에 숨겨진 아름다움을 찾아본다면?':
        'If you were to find the hidden beauty in the landscape you will encounter today?',
    '내가 최근에 배운 지식 중 다른 사람에게 공유하고 싶은 것은?':
        'Of the knowledge you recently learned, what do you want to share with others?',
    '오늘 하루 동안 내가 피곤함을 느낄 때 나를 위도해줄 문구는?':
        'What is a phrase that will comfort you when you feel tired during the day today?',
    '내가 오늘 완성하고 싶은 가장 작은 성취는 무엇인가요?':
        'What is the smallest achievement you want to complete today?',
    '오늘 하루 중 내가 가장 진솔해질 수 있는 순간은 언제인가요?':
        'When is the moment you can be the most sincere today?',
    '오늘 아침 나를 깨운 소리는 무엇이었나요?':
        'What was the sound that woke you up this morning?',
    '내가 요즘 가장 흥미를 느끼는 기술이나 문화는 무엇인가요?':
        'What is the technology or culture you are most interested in these days?',
    '오늘 하루 동안 내가 마주할 우연한 일들에 대한 나의 생각은?':
        'What are your thoughts on the accidental things you will encounter today?',
    '내가 오늘 스스로에게 허락하고 싶은 아주 사소한 일탈은?':
        'What is a very small deviation you want to allow yourself today?',
    '오늘 하루 중 내가 가장 고마움을 느낄 대상은 누구일까요?':
        'Who will be the person you feel the most grateful to today?',
    '오늘 아침 내가 느낀 공기의 상쾌함은 어떠했나요?':
        'How was the freshness of the air you felt this morning?',
    '오늘 하루 동안 내가 집중하고 싶은 나의 강점 하나는?':
        'What is one of your strengths you want to focus on throughout the day today?',
    '오늘 하루를 보내며 가장 많이 사용하게 될 물건은 무엇인가요?':
        'What is the object you will use the most while spending today?',
    '오늘 하루 중 내가 가장 평화롭게 느낄 장소는 어디인가요?':
        'Where is the place you will feel the most peaceful today?',
    '만약 오늘 새로운 취미를 시작한다면 무엇이 좋을까요?':
        'If I were to start a new hobby today, what would be good?',
    '오늘 아침 내가 본 첫 번째 이미지나 풍경은 무엇이었나요?':
        'What was the first image or landscape you saw this morning?',
    '내가 요즘 가장 많이 생각하는 미래의 나의 모습은?':
        'What is the image of my future self that I think about the most these days?',
    '오늘 하루 동안 내가 마주할 도전들을 어떻게 즐길 수 있을까요?':
        'How can I enjoy the challenges I will face throughout the day today?',
    '오늘 하루를 마칠 때 나 자신에게 해주고 싶은 칭찬은?':
        'What is the compliment you want to give yourself when you finish today?',
    '오늘 하루 중 내가 가장 기대하는 만남이나 이벤트는 무엇인가요?':
        'What is the meeting or event you are most looking forward to today?',
    '만약 오늘 하루만 자유롭게 여행할 수 있다면 어디로 갈까요?':
        'If I could travel freely for just today, where would I go?',
    '오늘 하루가 나에게 줄 가장 큰 선물은 무엇일까요?':
        'What will be the biggest gift today gives to me?',
    '오늘 나의 마음가짐을 한 문장의 좌우명으로 정한다면?':
        'If you were to set your mindset today as a one-sentence motto?',
    '내가 오늘 누군가에게 전하고픈 응원의 한마디는?':
        'What is a word of encouragement you want to give to someone today?',
    '오늘 하루 동안 내 마음을 가장 따뜻하게 해줄 추억은?':
        'What is the memory that will warm your heart the most today?',
    '내가 오늘 꼭 해결하고 싶은 사소한 고민거리는 무엇인가요?':
        'What is a small worry you definitely want to resolve today?',
    '오늘 하루 중 내가 가장 나다워지는 순간은 언제인가요?':
        'When is the moment you feel most like yourself today?',
    '내가 오늘 새롭게 발견하고 싶은 나의 또 다른 모습은?':
        'What is another side of yourself you want to discover today?',
    '오늘 하루가 끝났을 때 내가 가장 뿌듯해할 일은?':
        'What will you be most proud of when today is over?',
  };

  // 모든 질문을 DB에 초기화/업데이트하는 함수 (100개+) - updateQuestionTranslations에 통합됨
  // Future<void> seedQuestions() async { ... }

  Future<void> updateQuestionTranslations() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. DB에 있는 기존 질문들 가져오기
      final dbQuestions = await _questionService.getAllQuestions();
      final int initialDbCount = dbQuestions.length;

      debugPrint('==== 질문 동기화 및 번역 시작 (DB 기존: $initialDbCount개) ====');

      int updatedCount = 0;
      int addedCount = 0;

      // 정규식: 공백 및 문장부호 제거
      String normalize(String text) {
        return text.replaceAll(RegExp(r'[\s\?\!.,]'), '');
      }

      // 2. 마스터 맵(100개+) 순회하며 DB와 대조
      for (var entry in questionTranslationMap.entries) {
        final String masterKoreanText = entry.key;
        final String masterEngText = entry.value;
        final String normalizedMasterKey = normalize(masterKoreanText);

        // DB에 해당 질문이 있는지 확인
        bool existsInDb = false;
        String? existingDocId;

        for (var dbQ in dbQuestions) {
          final String normalizedDbText = normalize(dbQ.text);
          if (normalizedDbText == normalizedMasterKey ||
              normalizedDbText.contains(normalizedMasterKey) ||
              normalizedMasterKey.contains(normalizedDbText)) {
            existsInDb = true;
            existingDocId = dbQ.id;
            break;
          }
        }

        if (existsInDb && existingDocId != null) {
          // A. 이미 있으면 -> 번역 업데이트
          await _questionService.updateQuestionTranslation(
              existingDocId, masterEngText);
          updatedCount++;
        } else {
          // B. 없으면 -> 신규 추가
          await _questionService.addOrUpdateQuestion(
            text: masterKoreanText,
            category: 'daily', // 기본 카테고리
            engText: masterEngText,
          );
          addedCount++;
        }
      }

      debugPrint('결과 리포트:');
      debugPrint('- 번역 업데이트됨: $updatedCount개');
      debugPrint('- 신규 추가됨: $addedCount개');
      debugPrint('==== 질문 동기화 및 번역 종료 ====');

      // 최신 상태 반영을 위해 다시 로드 (선택 사항)
      // await fetchStats();
    } catch (e) {
      debugPrint('질문 번역/동기화 업데이트 오류: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}

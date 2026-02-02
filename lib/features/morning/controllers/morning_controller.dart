import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/diary_service.dart';
import '../../../services/question_service.dart';
import '../../../data/models/diary_model.dart';
import '../../../utils/encryption.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../services/user_service.dart';

class MorningController extends ChangeNotifier {
  final DiaryService _diaryService;
  final QuestionService _questionService;
  final UserService _userService;

  MorningController(
      this._diaryService, this._questionService, this._userService) {
    _loadCachedQuestion();
  }

  Future<void> _loadCachedQuestion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_question');
      if (cached != null && _currentQuestion == null) {
        _currentQuestion = cached;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('질문 캐시 로드 오류: $e');
    }
  }

  Future<void> _saveQuestionToCache(String question) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_question', question);
    } catch (e) {
      debugPrint('질문 캐시 저장 오류: $e');
    }
  }

  // 상태 변수
  bool _isLoading = false; // 초기값 false로 변경 (stuck 방지)
  bool _hasInitialized = false; // 초기 데이터 로드 여부
  bool _isWriting = false;
  String? _currentQuestion;
  DiaryModel? _todayDiary;
  Timer? _writingTimer;
  int _writingDuration = 0;
  int _charCount = 0; // 글자 수로 변경

  // Getters
  bool get isLoading => _isLoading;
  bool get hasInitialized => _hasInitialized;
  bool get isWriting => _isWriting;
  String? get currentQuestion => _currentQuestion;
  DiaryModel? get todayDiary => _todayDiary;
  int get writingDuration => _writingDuration;
  int get charCount => _charCount; // Getter 이름 변경
  bool get hasDiaryToday {
    if (_todayDiary == null || !_todayDiary!.isCompleted) return false;
    return _todayDiary!.dateKey == DiaryModel.buildDateKey(DateTime.now());
  }

  String _dateKey(DateTime date) {
    return DiaryModel.buildDateKey(date);
  }

  // 오늘 기준 연속 기록 동기화
  Future<void> syncConsecutiveDays(String userId) async {
    try {
      final user = await _userService.getUser(userId);
      if (user == null) return;

      final diaries = await _diaryService.getUserDiaries(userId);
      final completedDates = diaries
          .where((diary) => diary.isCompleted)
          .map((diary) => diary.dateKey)
          .toSet();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayKey = _dateKey(today);

      int consecutiveDays = 0;
      if (completedDates.contains(todayKey)) {
        DateTime cursor = today;
        while (completedDates.contains(_dateKey(cursor))) {
          consecutiveDays += 1;
          cursor = cursor.subtract(const Duration(days: 1));
        }
      }

      final maxConsecutiveDays = consecutiveDays > user.maxConsecutiveDays
          ? consecutiveDays
          : user.maxConsecutiveDays;

      if (consecutiveDays != user.consecutiveDays ||
          maxConsecutiveDays != user.maxConsecutiveDays) {
        await _userService.updateUser(userId, {
          'consecutiveDays': consecutiveDays,
          'maxConsecutiveDays': maxConsecutiveDays,
        });
      }
    } catch (e) {
      print('연속 기록 동기화 오류: $e');
    }
  }

  // 오늘의 일기 확인
  Future<void> checkTodayDiary(String userId) async {
    // 이미 메모리에 오늘의 일기가 있고 완료 상태라면 건너뜀
    if (hasDiaryToday) {
      _isLoading = false;
      _hasInitialized = true;
      Future.microtask(() => notifyListeners());
      return;
    }

    _isLoading = true;
    // Build 단계에서 호출될 경우를 대비해 처리
    Future.microtask(() => notifyListeners());

    try {
      // 1. 먼저 로컬 파일 확인 (가장 빠름)
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final fileName = '${userId}_${now.year}$month$day.enc';
      final file = File('${directory.path}/$fileName');

      if (await file.exists()) {
        final encryptedContent = await file.readAsString();
        // 로컬에 파일이 있으면 일단 작성 완료로 간주 (상세 메타데이터는 null이어도 isCompleted=true)
        _todayDiary = DiaryModel(
          id: 'local_temp',
          userId: userId,
          date: now,
          dateKey: _dateKey(now),
          encryptedContent: encryptedContent,
          isCompleted: true,
          createdAt: now,
        );
        _isLoading = false;
        _hasInitialized = true; // 로컬 파일 있으면 즉시 초기화 완료 처리
        notifyListeners();
        // 여기서 return하지 않고 서버에서도 최신 메타데이터를 가져오도록 진행
      }

      // 2. Firestore에서 실제 데이터(메타데이터 포함) 가져오기
      final diary = await _diaryService.getDiaryByDate(userId, DateTime.now());
      if (diary != null) {
        _todayDiary = diary;
      }
    } catch (e) {
      print('오늘의 일기 확인 오류: $e');
    } finally {
      _isLoading = false;
      _hasInitialized = true;
      Future.microtask(() => notifyListeners());
    }
  }

  // 강제로 로딩 종료 (예외 발생 대비)
  void finishLoading() {
    _isLoading = false;
    _hasInitialized = true;
    Future.microtask(() {
      notifyListeners();
    });
  }

  // 랜덤 질문 가져오기
  Future<void> fetchRandomQuestion() async {
    try {
      _currentQuestion = await _questionService.getRandomQuestion();
      _saveQuestionToCache(_currentQuestion!);
      Future.microtask(() {
        notifyListeners();
      });
    } catch (e) {
      print('랜덤 질문 가져오기 오류: $e');
      _currentQuestion = _currentQuestion ?? '오늘 하루는 어땠나요?';
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  // 작성 시작
  void startWriting() {
    _isWriting = true;
    _writingDuration = 0;
    _charCount = 0;

    // 기존 타이머가 있다면 취소
    _writingTimer?.cancel();

    // 작성 시간 타이머 시작
    _writingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _writingDuration++;
      Future.microtask(() {
        notifyListeners();
      });
    });

    Future.microtask(() {
      notifyListeners();
    });
  }

  // 글자 수 업데이트 (글자 수로 변경)
  void updateCharCount(String text) {
    _charCount = text.length; // 전체 글자 수 (공백 포함)
    Future.microtask(() {
      notifyListeners();
    });
  }

  // 일기 저장
  Future<bool> saveDiary({
    required String userId,
    required String content,
    String? mood,
  }) async {
    if (_writingTimer != null) {
      _writingTimer!.cancel();
      _writingTimer = null;
    }

    _isLoading = true;
    Future.microtask(() {
      notifyListeners();
    });

    try {
      // 1. 일기 내용 암호화
      final encryptedContent =
          await EncryptionUtil.encryptText(content, userId);

      // 2. 로컬에 암호화된 일기 저장
      await _saveEncryptedDiaryLocally(userId, encryptedContent);

      // 3. Firestore에 메타데이터만 저장
      final now = DateTime.now();
      final diaryDate = DateTime(now.year, now.month, now.day);
      final diary = DiaryModel(
        id: '',
        userId: userId,
        date: diaryDate,
        dateKey: _dateKey(now),
        encryptedContent: encryptedContent, // 암호화된 내용 포함
        wordCount: _charCount, // 글자 수 저장
        writingDuration: _writingDuration,
        mood: mood,
        isCompleted: true,
        createdAt: now,
        promptQuestion: _currentQuestion,
      );

      final diaryId = await _diaryService.createDiary(diary);
      _todayDiary = diary.copyWith(id: diaryId);

      // 4. 연속 기록 및 점수 업데이트
      await _userService.updateConsecutiveDays(userId);
      await _userService.updateUser(userId, {
        'points': FieldValue.increment(10), // 일기 작성 시 포인트 지급 예시
        'lastDiaryDate': Timestamp.fromDate(now),
      });

      _isLoading = false;
      _isWriting = false;
      Future.microtask(() {
        notifyListeners();
      });

      return true;
    } catch (e) {
      print('일기 저장 오류: $e');
      _isLoading = false;
      Future.microtask(() {
        notifyListeners();
      });
      return false;
    }
  }

  // 로컬에 암호화된 일기 저장
  Future<void> _saveEncryptedDiaryLocally(
      String userId, String encryptedContent) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final date = DateTime.now();
      // 날짜 패딩 추가 (월, 일 2자리 보장)
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final fileName = '${userId}_${date.year}$month$day.enc';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(encryptedContent);
    } catch (e) {
      throw Exception('로컬 저장 실패: $e');
    }
  }

  // 일기 내용 읽기 (전달된 데이터 우선 -> Firestore -> 로컬 파일 순)
  Future<String> loadDiaryContent({
    required String userId,
    required DateTime date,
    String? encryptedContent,
  }) async {
    try {
      String? contentToDecrypt = encryptedContent;

      // 1. 전달받은 내용이 없다면 Firestore에서 가져오기
      if (contentToDecrypt == null) {
        final diary = await _diaryService.getDiaryByDate(userId, date);
        contentToDecrypt = diary?.encryptedContent;
      }

      if (contentToDecrypt != null) {
        return await EncryptionUtil.decryptText(contentToDecrypt, userId);
      }

      // 2. Firestore에 없으면 로컬 파일에서 읽기 (하위 호환성)
      final directory = await getApplicationDocumentsDirectory();
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final fileName = '${userId}_${date.year}$month$day.enc';
      final file = File('${directory.path}/$fileName');

      if (await file.exists()) {
        final encryptedFromFile = await file.readAsString();
        return await EncryptionUtil.decryptText(encryptedFromFile, userId);
      }

      // 이전 버전 파일명 시도 (패딩 없음)
      final oldFileName = '${userId}_${date.year}${date.month}${date.day}.enc';
      final oldFile = File('${directory.path}/$oldFileName');
      if (await oldFile.exists()) {
        final encryptedFromFile = await oldFile.readAsString();
        return await EncryptionUtil.decryptText(encryptedFromFile, userId);
      }

      throw Exception('일기 내용을 찾을 수 없습니다.');
    } catch (e) {
      print('일기 읽기 오류: $e');
      rethrow; // 에러를 그대로 전달
    }
  }

  // 진행률 계산 (목표: 100자 또는 5분) - 테스트를 위해 100자로 낮춤, 실제로는 500자
  // 사용자 요청에 따라 글자 수가 제대로 측정되게 수정했으므로 다시 500자로 설정하거나 유지
  double getProgress({int targetChars = 500, int targetMinutes = 5}) {
    final charProgress = _charCount / targetChars;
    final timeProgress = _writingDuration / (targetMinutes * 60);
    return (charProgress + timeProgress) / 2;
  }

  // 목표 달성 여부
  bool isGoalReached({int targetChars = 10, int targetMinutes = 5}) {
    return _charCount >= targetChars ||
        _writingDuration >= (targetMinutes * 60);
  }

  // 모든 상태 초기화 (로그아웃용)
  void clear() {
    _writingTimer?.cancel();
    _writingTimer = null;
    _todayDiary = null;
    _currentQuestion = null;
    _writingDuration = 0;
    _charCount = 0;
    _isWriting = false;
    _isLoading = false;
    _hasInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _writingTimer?.cancel();
    super.dispose();
  }
}

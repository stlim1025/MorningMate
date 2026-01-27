import 'package:flutter/material.dart';
import '../../../services/firestore_service.dart';
import '../../../data/models/diary_model.dart';
import '../../../utils/encryption.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MorningController extends ChangeNotifier {
  final FirestoreService _firestoreService;

  MorningController(this._firestoreService);

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
    final now = DateTime.now();
    final diaryDate = _todayDiary!.date.toLocal(); // 로컬 시간으로 변환 후 비교
    return diaryDate.year == now.year &&
        diaryDate.month == now.month &&
        diaryDate.day == now.day;
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
      final diary =
          await _firestoreService.getDiaryByDate(userId, DateTime.now());
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
      _currentQuestion = await _firestoreService.getRandomQuestion();
      Future.microtask(() {
        notifyListeners();
      });
    } catch (e) {
      print('랜덤 질문 가져오기 오류: $e');
      _currentQuestion = '오늘 하루는 어땠나요?';
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
      final diary = DiaryModel(
        id: '',
        userId: userId,
        date: DateTime.now(),
        encryptedContent: encryptedContent, // 암호화된 내용 포함
        wordCount: _charCount, // 글자 수 저장
        writingDuration: _writingDuration,
        mood: mood,
        isCompleted: true,
        createdAt: DateTime.now(),
        promptQuestion: _currentQuestion,
      );

      final diaryId = await _firestoreService.createDiary(diary);
      _todayDiary = diary.copyWith(id: diaryId);

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
        final diary = await _firestoreService.getDiaryByDate(userId, date);
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

  @override
  void dispose() {
    _writingTimer?.cancel();
    super.dispose();
  }
}

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
  bool _isLoading = false;
  bool _isWriting = false;
  String? _currentQuestion;
  DiaryModel? _todayDiary;
  Timer? _writingTimer;
  int _writingDuration = 0;
  int _charCount = 0; // 글자 수로 변경

  // Getters
  bool get isLoading => _isLoading;
  bool get isWriting => _isWriting;
  String? get currentQuestion => _currentQuestion;
  DiaryModel? get todayDiary => _todayDiary;
  int get writingDuration => _writingDuration;
  int get charCount => _charCount; // Getter 이름 변경
  bool get hasDiaryToday => _todayDiary?.isCompleted ?? false;

  // 오늘의 일기 확인
  Future<void> checkTodayDiary(String userId) async {
    _isLoading = true;
    Future.microtask(() {
      notifyListeners();
    });

    try {
      _todayDiary =
          await _firestoreService.getDiaryByDate(userId, DateTime.now());
    } catch (e) {
      print('오늘의 일기 확인 오류: $e');
    }

    _isLoading = false;
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
      final encryptedContent = await EncryptionUtil.encryptText(content);

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
      final fileName = '${userId}_${date.year}${date.month}${date.day}.enc';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(encryptedContent);
    } catch (e) {
      throw Exception('로컬 저장 실패: $e');
    }
  }

  // 로컬에서 암호화된 일기 읽기
  Future<String?> loadDiaryContent(String userId, DateTime date) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${userId}_${date.year}${date.month}${date.day}.enc';
      final file = File('${directory.path}/$fileName');

      if (await file.exists()) {
        final encryptedContent = await file.readAsString();
        return await EncryptionUtil.decryptText(encryptedContent);
      }
      return null;
    } catch (e) {
      print('일기 읽기 오류: $e');
      return null;
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
  bool isGoalReached({int targetChars = 100, int targetMinutes = 5}) {
    return _charCount >= targetChars ||
        _writingDuration >= (targetMinutes * 60);
  }

  @override
  void dispose() {
    _writingTimer?.cancel();
    super.dispose();
  }
}

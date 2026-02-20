import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/diary_service.dart';
import '../../../services/question_service.dart';
import '../../../data/models/diary_model.dart';
import '../../../data/models/question_model.dart';
import '../../../utils/encryption.dart';
import 'dart:async';
import 'dart:convert';
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
      final cached = prefs.getString('cached_question_json');
      if (cached != null && _currentQuestion == null) {
        final data = json.decode(cached);
        _currentQuestion = QuestionModel(
          id: data['id'] ?? '',
          text: data['text'] ?? '',
          engText: data['engText'],
          category: data['category'] ?? 'default',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('질문 캐시 로드 오류: $e');
    }
  }

  Future<void> _saveQuestionToCache(QuestionModel question) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final questionData = {
        'id': question.id,
        'text': question.text,
        'engText': question.engText,
        'category': question.category,
      };
      await prefs.setString('cached_question_json', json.encode(questionData));
    } catch (e) {
      debugPrint('질문 캐시 저장 오류: $e');
    }
  }

  // 상태 변수
  bool _isLoading = false;
  bool _hasInitialized = false;
  bool _isWriting = false;
  QuestionModel? _currentQuestion;
  DiaryModel? _todayDiary;
  Timer? _writingTimer;
  int _writingDuration = 0;
  int _charCount = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get hasInitialized => _hasInitialized;
  bool get isWriting => _isWriting;
  QuestionModel? get currentQuestion => _currentQuestion;
  DiaryModel? get todayDiary => _todayDiary;
  int get writingDuration => _writingDuration;
  int get charCount => _charCount;
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
      debugPrint('연속 기록 동기화 오류: $e');
    }
  }

  // 오늘의 일기 확인
  Future<void> checkTodayDiary(String userId) async {
    if (hasDiaryToday) {
      _isLoading = false;
      _hasInitialized = true;
      Future.microtask(() => notifyListeners());
      return;
    }

    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      final now = DateTime.now();
      final filePath = await _getDiaryFilePath(userId, now);
      final file = File(filePath);

      if (await file.exists()) {
        final encryptedContent = await file.readAsString();
        _todayDiary = DiaryModel(
          id: 'local_temp',
          userId: userId,
          date: now,
          dateKey: _dateKey(now),
          encryptedContent: encryptedContent,
          isCompleted: false,
          createdAt: now,
        );
        _isLoading = false;
        _hasInitialized = true;
        notifyListeners();
      }

      final diary = await _diaryService.getDiaryByDate(userId, DateTime.now());
      if (diary != null) {
        _todayDiary = diary;
      } else {
        if (_todayDiary != null) {
          _todayDiary = null;
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('오늘의 일기 확인 오류: $e');
    } finally {
      _isLoading = false;
      _hasInitialized = true;
      Future.microtask(() => notifyListeners());
    }
  }

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
      final question = await _questionService.getRandomQuestion();
      if (question != null) {
        _currentQuestion = question;
        _saveQuestionToCache(_currentQuestion!);
      }
      Future.microtask(() {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('랜덤 질문 가져오기 오류: $e');
      _currentQuestion = _currentQuestion ??
          QuestionModel(
              id: 'fallback', text: '오늘 하루는 어땠나요?', category: 'default');
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

    _writingTimer?.cancel();

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

  // 글자 수 업데이트
  void updateCharCount(String text) {
    _charCount = text.length;
    Future.microtask(() {
      notifyListeners();
    });
  }

  // 일기 저장 (완료)
  Future<bool> saveDiary({
    required String userId,
    required String content,
    List<String>? moods,
    DateTime? customDate,
    String? existingId,
  }) async {
    return _saveDiaryInternal(
      userId: userId,
      content: content,
      moods: moods,
      isDraft: false,
      customDate: customDate,
      existingId: existingId,
    );
  }

  // 임시 저장
  Future<bool> saveDraft({
    required String userId,
    required String content,
    List<String>? moods,
    DateTime? customDate,
    String? existingId,
  }) async {
    return _saveDiaryInternal(
      userId: userId,
      content: content,
      moods: moods,
      isDraft: true,
      customDate: customDate,
      existingId: existingId,
    );
  }

  // 내부 저장 로직 (통합)
  Future<bool> _saveDiaryInternal({
    required String userId,
    required String content,
    List<String>? moods,
    required bool isDraft,
    DateTime? customDate,
    String? existingId,
  }) async {
    if (_writingTimer != null) {
      if (!isDraft) {
        _writingTimer!.cancel();
        _writingTimer = null;
      }
    }

    if (_isLoading) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final encryptedContent =
          await EncryptionUtil.encryptText(content, userId);

      final now = DateTime.now();
      final diaryDate = customDate ?? DateTime(now.year, now.month, now.day);

      await _saveEncryptedDiaryLocally(userId, encryptedContent,
          date: diaryDate);

      String? targetId = existingId ?? _todayDiary?.id;
      if (targetId == 'local_temp') targetId = null;

      final diary = DiaryModel(
        id: targetId ?? '',
        userId: userId,
        date: diaryDate,
        dateKey: _dateKey(diaryDate),
        encryptedContent: encryptedContent,
        wordCount: content.length,
        writingDuration: _writingDuration,
        moods: moods ?? [],
        isCompleted: !isDraft,
        createdAt: (targetId != null && targetId.isNotEmpty)
            ? (_todayDiary?.createdAt ?? now)
            : now,
        promptQuestion: _currentQuestion?.text,
        promptQuestionEng: _currentQuestion?.engText,
      );

      final bool isNewDiary = targetId == null || targetId.isEmpty;

      if (!isNewDiary) {
        await _diaryService.updateDiary(targetId, diary.toFirestore());
        // 오늘 일기인 경우에만 상태 업데이트
        if (_todayDiary?.id == targetId ||
            _dateKey(diaryDate) == _dateKey(now)) {
          _todayDiary = diary;
        }
      } else {
        final newId = await _diaryService.createDiary(diary);
        // 오늘 일기인 경우에만 상태 저장
        if (_dateKey(diaryDate) == _dateKey(now)) {
          _todayDiary = diary.copyWith(id: newId);
        }
      }

      // 새로 완료된 경우에만 보상 (임시저장 아님 AND (새 일기거나 기존에 미완료였던 경우))
      // 단, 과거 일기 수정 시에는 보상을 주지 않음 (isNewDiary && 오늘 날짜인 경우에만 지급하는 것이 안전할 수도 있음)
      if (!isDraft) {
        bool shouldReward = false;
        if (isNewDiary && _dateKey(diaryDate) == _dateKey(now)) {
          shouldReward = true;
        } else if (!isNewDiary &&
            _todayDiary != null &&
            !_todayDiary!.isCompleted &&
            _dateKey(diaryDate) == _dateKey(now)) {
          // 기존에 오늘 날짜 임시저장이었는데 지금 완료하는 경우
          shouldReward = true;
        }

        if (shouldReward) {
          await _userService.updateConsecutiveDays(userId);
          await _userService.updateUser(userId, {
            'points': FieldValue.increment(10),
            'diaryCount': FieldValue.increment(1),
            'lastDiaryDate': Timestamp.fromDate(now),
            'lastDiaryMood': moods?.isNotEmpty == true ? moods!.first : null,
          });
        }

        _isWriting = false;
      }

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('일기 저장 오류: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 로컬에 암호화된 일기 저장
  Future<void> _saveEncryptedDiaryLocally(
      String userId, String encryptedContent,
      {DateTime? date}) async {
    try {
      final now = date ?? DateTime.now();
      final filePath = await _getDiaryFilePath(userId, now, createDir: true);
      final file = File(filePath);

      await file.writeAsString(encryptedContent, flush: true);
      debugPrint('로컬 저장 성공: $filePath');
    } catch (e) {
      debugPrint('로컬 저장 상세 오류: $e');
      throw Exception('로컬 저장 실패: ${e.toString()}');
    }
  }

  // 일기 파일 경로 가져오기
  Future<String> _getDiaryFilePath(String userId, DateTime date,
      {bool createDir = false}) async {
    final directory = await getApplicationDocumentsDirectory();

    if (createDir && !await directory.exists()) {
      await directory.create(recursive: true);
    }

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final fileName = '${userId}_${date.year}$month$day.enc';

    final pathSeparator = Platform.isWindows ? '\\' : '/';
    return '${directory.path}$pathSeparator$fileName';
  }

  // 일기 내용 읽기
  Future<String> loadDiaryContent({
    required String userId,
    required DateTime date,
    String? encryptedContent,
  }) async {
    try {
      String? contentToDecrypt = encryptedContent;

      if (contentToDecrypt == null) {
        final diary = await _diaryService.getDiaryByDate(userId, date);
        contentToDecrypt = diary?.encryptedContent;
      }

      if (contentToDecrypt != null) {
        return await EncryptionUtil.decryptText(contentToDecrypt, userId);
      }

      final filePath = await _getDiaryFilePath(userId, date);
      final file = File(filePath);

      if (await file.exists()) {
        final encryptedFromFile = await file.readAsString();
        return await EncryptionUtil.decryptText(encryptedFromFile, userId);
      }

      final directory = await getApplicationDocumentsDirectory();
      final oldFileName = '${userId}_${date.year}${date.month}${date.day}.enc';
      final pathSeparator = Platform.isWindows ? '\\' : '/';
      final oldFile = File('${directory.path}$pathSeparator$oldFileName');
      if (await oldFile.exists()) {
        final encryptedFromFile = await oldFile.readAsString();
        return await EncryptionUtil.decryptText(encryptedFromFile, userId);
      }

      throw Exception('일기 내용을 찾을 수 없습니다.');
    } catch (e) {
      debugPrint('일기 읽기 오류: $e');
      rethrow;
    }
  }

  double getProgress({int targetChars = 500, int targetMinutes = 5}) {
    final charProgress = _charCount / targetChars;
    final timeProgress = _writingDuration / (targetMinutes * 60);
    return (charProgress + timeProgress) / 2;
  }

  bool isGoalReached({int targetChars = 10, int targetMinutes = 5}) {
    return _charCount >= targetChars ||
        _writingDuration >= (targetMinutes * 60);
  }

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

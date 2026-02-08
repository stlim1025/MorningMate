import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:intl/intl.dart';
import 'package:morning_mate/features/morning/controllers/morning_controller.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../services/alarm_service.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  bool _isWakingUp = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.extension<AppColorScheme>();

    final primaryColor = colorScheme?.primaryButton ?? theme.primaryColor;
    final textPrimary = colorScheme?.textPrimary ?? Colors.black;
    final textSecondary = colorScheme?.textSecondary ?? Colors.grey;

    final currentTime = DateFormat('HH:mm').format(DateTime.now());
    final dateText = DateFormat('M월 d일 EEEE', 'ko_KR').format(DateTime.now());
    const String characterImage = 'assets/animations/bouncing_egg.gif';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.15),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Text(dateText,
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 18,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Text(currentTime,
                        style: TextStyle(
                            color: textPrimary,
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'BMJUA')),
                  ],
                ),
              ),
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    padding: EdgeInsets.all(_isWakingUp ? 50 : 40),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      characterImage,
                      width: 150,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.face_retouching_natural,
                        size: 100,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isWakingUp ? "하암~ 잘 잤다!" : "좋은 아침이에요!",
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'BMJUA'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isWakingUp
                        ? "오늘 하루도 힘차게 시작해봐요!"
                        : widget.alarmSettings.notificationSettings.body,
                    style: TextStyle(color: textSecondary, fontSize: 16),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 60, left: 30, right: 30),
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _isWakingUp
                        ? null
                        : _handleDiaryStart, // 🚨 로직을 별도 메서드로 분리
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(
                      _isWakingUp ? '캐릭터 기상 중...' : '일기 작성하기',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚨 [수정 2] 근본적인 초기화 에러를 잡는 비동기 로직
  Future<void> _handleDiaryStart() async {
    setState(() => _isWakingUp = true);

      // 1. 알람 소리 먼저 끄기
      await AlarmService.stopAlarm(widget.alarmSettings.id);

      // 2. 중요: Provider나 시스템이 안정화될 시간을 확보 (1.5초)
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      // 3. Provider 안전하게 호출 (try-catch로 감싸서 Provider 없음 에러 방지)
      MorningController? morningController;
      try {
        morningController =
            Provider.of<MorningController>(context, listen: false);
      } catch (providerError) {
        debugPrint('Controller Not Found: $providerError');
      }

      // 4. 질문 데이터 가져오기 시도
      String? question;
      if (morningController != null) {
        try {
          if (morningController.currentQuestion == null) {
            await morningController
                .fetchRandomQuestion()
                .timeout(const Duration(seconds: 3));
          }
          question = morningController.currentQuestion;
          morningController.startWriting();
        } catch (apiError) {
          debugPrint('질문 로드 중 API 에러: $apiError');
        }
      }

      // 5. 무조건 화면 이동 (데이터 없으면 기본값이라도 들고 가야 앱이 안 죽음)
      if (mounted) {
        context.go('/writing', extra: question ?? "오늘 하루는 어떠셨나요?");
      }

  }
}

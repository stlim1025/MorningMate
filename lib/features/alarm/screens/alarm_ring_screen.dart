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
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    final currentTime = DateFormat('HH:mm').format(DateTime.now());
    final dateText = DateFormat('M월 d일 EEEE', 'ko_KR').format(DateTime.now());

    // 캐릭터 컨트롤러의 메서드를 활용해 이미지를 가져옵니다.
    const String characterImage = 'assets/animations/bouncing_egg.gif';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryButton.withOpacity(0.15),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 상단 정보 섹션
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Text(
                      dateText,
                      style: TextStyle(
                          color: colorScheme.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentTime,
                      style: TextStyle(
                        color: colorScheme.textPrimary,
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'BMJUA',
                      ),
                    ),
                  ],
                ),
              ),

              // 중앙 캐릭터 섹션
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    padding: EdgeInsets.all(_isWakingUp ? 50 : 40),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryButton.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      characterImage,
                      width: 150,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.face_retouching_natural,
                        size: 100,
                        color: colorScheme.primaryButton,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isWakingUp ? "하암~ 잘 잤다!" : "좋은 아침이에요!",
                    style: TextStyle(
                      color: colorScheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'BMJUA',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isWakingUp
                        ? "오늘 하루도 힘차게 시작해봐요!"
                        : widget.alarmSettings.notificationSettings.body,
                    style: TextStyle(
                        color: colorScheme.textSecondary, fontSize: 16),
                  ),
                ],
              ),

              // 하단 액션 버튼 섹션
              Padding(
                padding: const EdgeInsets.only(bottom: 60, left: 30, right: 30),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _isWakingUp
                            ? null
                            : () async {
                                setState(() => _isWakingUp = true);

                                // 알람 중단
                                await AlarmService.stopAlarm(
                                    widget.alarmSettings.id);

                                // 캐릭터 깨어남 애니메이션 대기 (약 1.5초)
                                await Future.delayed(
                                    const Duration(milliseconds: 1500));

                                if (context.mounted) {
                                  final morningController =
                                      Provider.of<MorningController>(context,
                                          listen: false);

                                  if (morningController.currentQuestion ==
                                      null) {
                                    await morningController
                                        .fetchRandomQuestion();
                                  }

                                  morningController.startWriting();

                                  // 작성 페이지로 이동
                                  context.pushReplacement('/writing',
                                      extra: morningController.currentQuestion);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primaryButton,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

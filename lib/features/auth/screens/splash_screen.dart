import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/localization/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitializing = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
      _hasError = false;
    });

    // AuthController의 초기화 완료를 기다림
    final authController = context.read<AuthController>();

    // AuthCheckDone이 완료될 때까지 잠시 대기 (필요 시)
    while (!authController.isAuthCheckDone) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    final user = authController.userModel;

    // 로그인이 안 되어 있으면 /login으로 이동
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    // 정지 상태 확인
    if (user.suspendedUntil != null &&
        user.suspendedUntil!.isAfter(DateTime.now())) {
      if (mounted) {
        await _showSuspendedDialog(context, user);
      }
      return;
    }

    if (user.biometricEnabled && !authController.isBiometricVerified) {
      // 생체 인증이 켜져 있고 아직 인증되지 않은 경우
      final authenticated = await authController.authenticateWithBiometric();

      if (authenticated) {
        authController.setBiometricVerified(true);
        // 여기서 context.go('/morning')을 호출하지 않아도
        // notifyListeners() -> Router redirect에서 자동으로 이동함
        if (mounted) context.go('/morning');
      } else {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _hasError = true;
          });

          // 다이얼로그도 옵션으로 제공 (사용자 선택에 따라 다시 시도하거나 로그아웃)
          final retry = await _showBiometricRetryDialog(context);
          if (retry && mounted) {
            _checkInitialState();
          }
        }
      }
    } else {
      // 생체 인증이 필요 없거나 이미 완료된 경우
      if (mounted) context.go('/morning');
    }
  }

  Future<bool> _showBiometricRetryDialog(BuildContext context) async {
    final result = await AppDialog.show<bool>(
      context: context,
      key: AppDialogKey.biometricRetry,
      barrierDismissible: false,
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('logout') ?? '로그아웃',
          onPressed: () {
            context.read<AuthController>().signOut();
            Navigator.pop(context, false);
          },
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('retry') ?? '다시 시도',
          onPressed: () => Navigator.pop(context, true),
          useHighlight: true,
        ),
      ],
    );
    return result ?? false;
  }

  Future<void> _showSuspendedDialog(
    BuildContext context,
    UserModel user,
  ) async {
    String remainingTime = '';
    final suspendedUntil = user.suspendedUntil!;
    final now = DateTime.now();
    final diff = suspendedUntil.difference(now);

    final l10n = AppLocalizations.of(context);
    if (suspendedUntil.year >= 2090) {
      remainingTime = l10n?.get('permanentSuspension') ?? '영구 정지';
    } else if (diff.inDays > 0) {
      remainingTime = l10n?.getFormat('daysRemaining', {
            'days': diff.inDays.toString(),
            'hours': (diff.inHours % 24).toString(),
          }) ??
          '${diff.inDays}일 ${diff.inHours % 24}시간 남음';
    } else if (diff.inHours > 0) {
      remainingTime = l10n?.getFormat('hoursRemaining', {
            'hours': diff.inHours.toString(),
            'minutes': (diff.inMinutes % 60).toString(),
          }) ??
          '${diff.inHours}시간 ${diff.inMinutes % 60}분 남음';
    } else {
      remainingTime = l10n?.getFormat('minutesRemaining', {
            'minutes': diff.inMinutes.toString(),
          }) ??
          '${diff.inMinutes}분 남음';
    }

    await AppDialog.show(
      context: context,
      key: AppDialogKey.suspension,
      barrierDismissible: false,
      content: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n?.get('suspensionContent') ??
                  '커뮤니티 가이드라인 위반으로 인해\n서비스 이용이 일시적으로 제한되었습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'BMJUA',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Option_Area.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n?.get('remainingTimeTitle') ?? '해제까지 남은 시간',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontFamily: 'BMJUA',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remainingTime,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontFamily: 'BMJUA',
                    ),
                  ),
                ],
              ),
            ),
            if (user.suspensionReason != null) ...[
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  String reasonStr = user.suspensionReason!;
                  if (reasonStr == '커뮤니티 가이드라인 위반') {
                    reasonStr =
                        l10n?.get('reason_community_violation') ?? reasonStr;
                  }
                  return Text(
                    l10n?.getFormat('suspensionReason', {
                          'reason': reasonStr,
                        }) ??
                        '사유: $reasonStr',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                      fontFamily: 'BMJUA',
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppDialogAction(
          label: l10n?.get('logout') ?? '로그아웃',
          isPrimary: true,
          onPressed: (BuildContext dialogContext) async {
            // Re-accessing authController through the dialog's context
            final auth = dialogContext.read<AuthController>();
            Navigator.pop(dialogContext);
            await auth.signOut();
            // AuthController.signOut notifies GoRouter to redirect,
            // no need to call GoRouter here on a potentially deactivated context.
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/Charactor_Icon.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              "Morni",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'BMJUA',
                color: Color(0xFF4E342E),
              ),
            ),
            const SizedBox(height: 40),
            if (_hasError)
              Column(
                children: [
                  const Text(
                    "인증에 실패했습니다.",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontFamily: 'BMJUA',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkInitialState,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E342E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "다시 시도",
                      style: TextStyle(fontFamily: 'BMJUA'),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await context.read<AuthController>().signOut();
                      if (mounted) context.go('/login');
                    },
                    child: const Text(
                      "다른 계정으로 로그인",
                      style: TextStyle(fontFamily: 'BMJUA', color: Colors.grey),
                    ),
                  ),
                ],
              )
            else
              const CircularProgressIndicator(color: Color(0xFF4E342E)),
          ],
        ),
      ),
    );
  }
}

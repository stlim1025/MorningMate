import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import '../theme/app_color_scheme.dart';

enum AppDialogKey {
  biometricRetry,
  changeNickname,
  changePassword,
  logout,
  deleteAccount,
  addFriend,
  guestbook,
  exitWriting,
  sentMessages,
  purchase,
  purchaseComplete,
  levelUp,
  deleteStickyNote,
}

class AppDialogAction {
  const AppDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.useHighlight = false,
    this.isFullWidth = false,
    this.isEnabled,
    this.labelWidget,
  });

  final String label;
  final Widget? labelWidget;
  final dynamic onPressed;
  final bool isPrimary;
  final bool useHighlight;
  final bool isFullWidth;
  final ValueListenable<bool>? isEnabled;
}

class AppDialogConfig {
  const AppDialogConfig({
    required this.title,
    this.leading,
    this.content,
    this.actions = const [],
    this.actionsAlignment,
    this.showConfetti = false,
  });

  final String title;
  final Widget? leading;
  final Widget? content;
  final List<AppDialogAction> actions;
  final MainAxisAlignment? actionsAlignment;
  final bool showConfetti;
}

class AppDialog {
  const AppDialog._();

  static void showError(BuildContext context, String? message) {
    final scope = context.findAncestorWidgetOfExactType<_AppDialogErrorScope>();
    scope?.setError(message);
  }

  static AppDialogConfig buildConfig({
    required AppDialogKey key,
    required BuildContext context,
    Widget? content,
    Widget? leading,
    List<AppDialogAction>? actions,
  }) {
    // ... (rest of buildConfig stays same)
    switch (key) {
      case AppDialogKey.biometricRetry:
        return AppDialogConfig(
          title: '생체 인증 실패',
          content: content ??
              const Text(
                '생체 인증에 실패했습니다. 다시 시도하거나 로그아웃할 수 있습니다.',
              ),
          actions: actions ?? const [],
        );
      case AppDialogKey.changeNickname:
        return AppDialogConfig(
          title: '닉네임 변경',
          content: content,
          actions: actions ?? const [],
        );
      case AppDialogKey.changePassword:
        return AppDialogConfig(
          title: '비밀번호 변경',
          content: content,
          actions: actions ?? const [],
        );
      case AppDialogKey.logout:
        return AppDialogConfig(
          title: '로그아웃',
          content: content ?? const Text('정말 로그아웃 하시겠습니까?'),
          actions: actions ?? const [],
        );
      case AppDialogKey.deleteAccount:
        return AppDialogConfig(
          title: '회원탈퇴',
          content: content ??
              const Text(
                '정말 회원탈퇴 하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.',
              ),
          actions: actions ?? const [],
        );
      case AppDialogKey.addFriend:
        return AppDialogConfig(
          title: '친구 추가',
          leading: leading,
          content: content,
          actions: actions ?? const [],
        );
      case AppDialogKey.guestbook:
        return AppDialogConfig(
          title: '응원 메시지',
          content: content,
          actions: actions ?? const [],
        );
      case AppDialogKey.exitWriting:
        return AppDialogConfig(
          title: '작성을 중단하시겠어요?',
          content: content,
          actions: actions ?? const [],
        );
      case AppDialogKey.sentMessages:
        return AppDialogConfig(
          title: '보낸 메시지',
          content: content,
          actions: actions ?? const [],
        );
      case AppDialogKey.purchase:
        return AppDialogConfig(
          title: '아이템 구매',
          content: content,
          actions: actions ??
              [
                AppDialogAction(
                  label: '취소',
                  onPressed: (context) => Navigator.pop(context, false),
                ),
                AppDialogAction(
                  label: '구매',
                  isPrimary: true,
                  onPressed: (context) => Navigator.pop(context, true),
                ),
              ],
        );
      case AppDialogKey.purchaseComplete:
        return AppDialogConfig(
          title: '구매 완료',
          content: content,
          actionsAlignment: MainAxisAlignment.center,
          showConfetti: true,
          actions: actions ??
              [
                AppDialogAction(
                  label: '확인',
                  isPrimary: true,
                  isFullWidth: true,
                  onPressed: (context) => Navigator.pop(context),
                ),
              ],
        );
      case AppDialogKey.levelUp:
        return AppDialogConfig(
          title: '🎊 축하합니다! 🎊',
          showConfetti: true,
          content: content ??
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '캐릭터가 새로운 단계로 성장했어요!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '앞으로도 꾸준히 성장을 도와주세요.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
          actions: actions ??
              [
                AppDialogAction(
                  label: '확인',
                  isPrimary: true,
                  onPressed: (context) => Navigator.pop(context, true),
                ),
              ],
        );
      case AppDialogKey.deleteStickyNote:
        return AppDialogConfig(
          title: '메모 삭제',
          content: content ?? const Text('메모를 삭제하시겠습니까?'),
          actions: actions ??
              [
                AppDialogAction(
                  label: '취소',
                  onPressed: (context) => Navigator.pop(context, false),
                ),
                AppDialogAction(
                  label: '확인',
                  isPrimary: true,
                  onPressed: (context) => Navigator.pop(context, true),
                ),
              ],
        );
    }
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required AppDialogKey key,
    Widget? content,
    Widget? leading,
    List<AppDialogAction>? actions,
    bool barrierDismissible = true,
  }) {
    final config = buildConfig(
      key: key,
      context: context,
      content: content,
      leading: leading,
      actions: actions,
    );
    // final colors = Theme.of(context).extension<AppColorScheme>(); // Removed unused variable

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return _AppDialogWrapper(config: config);
      },
    );
  }

  static Widget _buildActionButton(
    BuildContext context,
    AppDialogAction action,
    AppColorScheme? colors,
  ) {
    Color backgroundColor;
    Color foregroundColor;

    if (action.useHighlight) {
      backgroundColor =
          colors?.dialogHighlightBackground ?? Theme.of(context).primaryColor;
      foregroundColor =
          colors?.dialogHighlightForeground ?? Theme.of(context).primaryColor;
    } else if (action.isPrimary) {
      backgroundColor =
          colors?.dialogConfirmBackground ?? Theme.of(context).primaryColor;
      foregroundColor = colors?.dialogConfirmForeground ?? Colors.white;
    } else if (action.label == '탈퇴') {
      backgroundColor = colors?.error ?? Colors.red;
      foregroundColor = Colors.white;
    } else {
      backgroundColor = colors?.dialogCancelBackground ?? Colors.grey.shade200;
      foregroundColor = colors?.dialogCancelForeground ?? Colors.grey.shade800;
    }

    return ValueListenableBuilder<bool>(
      valueListenable: action.isEnabled ?? const AlwaysStoppedAnimation(true),
      builder: (context, isEnabled, child) {
        final button = ElevatedButton(
          onPressed: isEnabled
              ? () {
                  if (action.onPressed is Function(BuildContext)) {
                    action.onPressed(context);
                  } else {
                    action.onPressed?.call();
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled
                ? backgroundColor
                : colors?.textHint.withOpacity(0.2) ?? Colors.grey.shade300,
            foregroundColor: foregroundColor,
            elevation: isEnabled &&
                    (action.isPrimary ||
                        action.useHighlight ||
                        action.label == '탈퇴')
                ? 2
                : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: action.labelWidget ??
              Text(
                action.label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        );

        if (action.isFullWidth) {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: button,
          );
        }

        return button;
      },
    );
  }
}

class _AppDialogErrorScope extends InheritedWidget {
  const _AppDialogErrorScope({
    required this.setError,
    required super.child,
  });

  final Function(String?) setError;

  @override
  bool updateShouldNotify(_AppDialogErrorScope oldWidget) => false;
}

class _AppDialogWrapper extends StatefulWidget {
  final AppDialogConfig config;

  const _AppDialogWrapper({required this.config});

  @override
  State<_AppDialogWrapper> createState() => _AppDialogWrapperState();
}

class _AppDialogWrapperState extends State<_AppDialogWrapper> {
  String? _errorMessage;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    if (widget.config.showConfetti) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>();
    final config = widget.config;

    return Stack(
      children: [
        if (config.showConfetti) ...[
          // Center Explosion
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 50,
                emissionFrequency: 0.2,
                maxBlastForce: 40,
                minBlastForce: 20,
                colors: const [
                  Color(0xFFFFD700), // Gold
                  Color(0xFFFFDF00), // Bright Gold
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.white,
                ],
                createParticlePath: drawStar,
              ),
            ),
          ),
          // Left Bottom Burst
          Align(
            alignment: Alignment.bottomLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 4,
              emissionFrequency: 0.1,
              numberOfParticles: 20,
              maxBlastForce: 50,
              minBlastForce: 20,
              colors: const [Color(0xFFFFD700), Colors.pink, Colors.orange],
            ),
          ),
          // Right Bottom Burst
          Align(
            alignment: Alignment.bottomRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -3 * pi / 4,
              emissionFrequency: 0.1,
              numberOfParticles: 20,
              maxBlastForce: 50,
              minBlastForce: 20,
              colors: const [Color(0xFFFFD700), Colors.blue, Colors.purple],
            ),
          ),
        ],
        _AppDialogErrorScope(
          setError: (msg) => setState(() => _errorMessage = msg),
          child: AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                if (config.leading != null) ...[
                  config.leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    config.title,
                    style: TextStyle(
                      color: colors?.dialogTitle ??
                          Theme.of(context).textTheme.titleLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (config.content != null)
                  DefaultTextStyle.merge(
                    style: TextStyle(
                      color: colors?.dialogBody ??
                          Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    child: config.content!,
                  ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: colors?.error ?? Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            actionsAlignment: config.actionsAlignment,
            actions: config.actions
                .map((action) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child:
                          AppDialog._buildActionButton(context, action, colors),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (3.1415926535897932 / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}

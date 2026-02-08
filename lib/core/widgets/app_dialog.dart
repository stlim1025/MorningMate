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
  writeMemo,
  diaryCompletion,
  adReward,
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
      case AppDialogKey.writeMemo:
        return AppDialogConfig(
          title: '메모 작성',
          content: content,
          actions: actions ?? const [],
        );
      case AppDialogKey.diaryCompletion:
        return AppDialogConfig(
          title: '🎉 작성 완료!',
          showConfetti: true,
          content: content,
          actionsAlignment: MainAxisAlignment.center,
          actions: actions ?? const [],
        );
      case AppDialogKey.adReward:
        return AppDialogConfig(
          title: '가지 획득!',
          showConfetti: true,
          content: content ??
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/branch.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '광고 시청 보상으로\n10 가지를 획득했습니다!',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          actionsAlignment: MainAxisAlignment.center,
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
    // '탈퇴' actions are excluded to keep their specific red styling.
    // 'Brown' buttons (isPrimary) come here, along with specific labels.
    // '계속 작성'은 '취소'와 같은 스타일(아니오 등의 부정적 의미)로 처리하기 위해 isConfirmStyle에서 제외
    final isConfirmStyle = action.isPrimary ||
        ['확인', '변경', '구매', '전송', '수락', '등록', '요청', '탈퇴'].contains(action.label);

    // 'Cancel' or 'Close' style buttons. Includes '계속 작성'
    final isCancelStyle =
        ['취소', '닫기', '거절', '아니오', '계속 작성'].contains(action.label);

    if (isConfirmStyle || isCancelStyle) {
      final imagePath = isConfirmStyle
          ? 'assets/images/Confirm_Button.png'
          : 'assets/images/Cancel_Button.png';

      const textColor = Color(0xFF4E342E);

      return _ImageActionButton(
        imagePath: imagePath,
        label: action.label,
        child: action.labelWidget,
        onPressed: () {
          if (action.onPressed is Function(BuildContext)) {
            action.onPressed(context);
          } else {
            action.onPressed?.call();
          }
        },
        isEnabled: action.isEnabled,
        textColor: textColor,
      );
    }

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
          child: Builder(
            builder: (dialogContext) => Dialog(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background Container with rounded corners
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        // Background Image
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/Popup_Background.png',
                            fit: BoxFit.fill,
                            cacheWidth: 800, // Optimized
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              24, 40, 24, 28), // 상단 패딩을 늘려 전체적으로 내림
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              if (config.title.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (config.leading != null) ...[
                                      config.leading!,
                                      const SizedBox(width: 10),
                                    ],
                                    Text(
                                      config.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'BMJUA',
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4E342E), // Dark Brown
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                              // Content
                              if (config.content != null)
                                DefaultTextStyle.merge(
                                  style: TextStyle(
                                    color: colors?.dialogBody ??
                                        Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                    fontFamily: 'BMJUA', // 팝업 내용에도 폰트 적용
                                    fontSize: 18,
                                  ),
                                  child: config.content!,
                                ),
                              if (_errorMessage != null)
                                Container(
                                  width: double.infinity,
                                  margin:
                                      const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDD8D8),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFD32F2F)
                                            .withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'BMJUA',
                                    ),
                                  ),
                                ),
                              // Actions
                              if (config.actions.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        config.actionsAlignment ??
                                            MainAxisAlignment.end,
                                    children: config.actions
                                        .map((action) => Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4),
                                                child: AppDialog
                                                    ._buildActionButton(
                                                        dialogContext,
                                                        action,
                                                        colors),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sticker Image (왼쪽 위) - 배경 Container 밖에 배치
                  Positioned(
                    top: -25,
                    left: -10,
                    child: Image.asset(
                      'assets/images/Popup_Sticker.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      cacheWidth: 300, // Optimized
                    ),
                  ),
                ],
              ),
            ),
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

class _ImageActionButton extends StatefulWidget {
  final String imagePath;
  final String label;
  final Widget? child;
  final VoidCallback? onPressed;
  final ValueListenable<bool>? isEnabled;
  final Color? textColor;

  const _ImageActionButton({
    required this.imagePath,
    required this.label,
    this.child,
    this.onPressed,
    this.isEnabled,
    this.textColor,
  });

  @override
  State<_ImageActionButton> createState() => _ImageActionButtonState();
}

class _ImageActionButtonState extends State<_ImageActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isEnabled ?? const AlwaysStoppedAnimation(true),
      builder: (context, isEnabled, child) {
        return GestureDetector(
          onTapDown:
              isEnabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel:
              isEnabled ? () => setState(() => _isPressed = false) : null,
          onTap: isEnabled ? widget.onPressed : null,
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.5,
            child: Transform.scale(
              scale: _isPressed ? 0.95 : 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    widget.imagePath,
                    fit: BoxFit.fill,
                    width: double.infinity,
                    height: 52, // Fixed height to match standard button
                    cacheHeight: 150, // Optimized
                  ),
                  widget.child ??
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: 'BMJUA',
                          color: widget.textColor ?? const Color(0xFF4E342E),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PopupTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final int? maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final bool autofocus;

  const PopupTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.maxLength,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine height based on maxLines
    final double height = (maxLines ?? 1) == 1 ? 60.0 : 120.0;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/TextBox_Background.png'),
          fit: BoxFit.fill,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: maxLines == 1 ? Alignment.center : Alignment.topLeft,
      child: validator != null
          ? TextFormField(
              autofocus: autofocus,
              controller: controller,
              obscureText: obscureText,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: const TextStyle(
                color: Color(0xFF4E342E),
                fontFamily: 'BMJUA',
                fontSize: 18,
              ),
              onChanged: onChanged,
              validator: validator,
              maxLength: maxLength,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: const Color(0xFF4E342E).withOpacity(0.5),
                  fontFamily: 'BMJUA',
                  fontSize: 16,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorStyle: const TextStyle(
                  fontFamily: 'BMJUA',
                  color: Colors.red,
                  fontSize: 12,
                ),
                isDense: true,
                contentPadding: maxLines == 1
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(vertical: 16),
                filled: false,
                fillColor: Colors.transparent,
                counterText: '',
              ),
            )
          : TextField(
              autofocus: autofocus,
              controller: controller,
              obscureText: obscureText,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: const TextStyle(
                color: Color(0xFF4E342E),
                fontFamily: 'BMJUA',
                fontSize: 18,
              ),
              onChanged: onChanged,
              maxLength: maxLength,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: const Color(0xFF4E342E).withOpacity(0.5),
                  fontFamily: 'BMJUA',
                  fontSize: 16,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: maxLines == 1
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(vertical: 16),
                filled: false,
                fillColor: Colors.transparent,
                counterText: '',
              ),
            ),
    );
  }
}

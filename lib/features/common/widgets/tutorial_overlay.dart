import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/localization/app_localizations.dart';

class InteractiveTutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;
  final Function(int)? onStepChanged;

  const InteractiveTutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    this.onSkip,
    this.onStepChanged,
  });

  @override
  State<InteractiveTutorialOverlay> createState() =>
      InteractiveTutorialOverlayState();
}

class InteractiveTutorialOverlayState
    extends State<InteractiveTutorialOverlay> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final GlobalKey _overlayKey = GlobalKey();
  int _currentStepIndex = 0;
  int get currentStepIndex => _currentStepIndex;

  @override
  void initState() {
    super.initState();
    // 매 프레임마다 setState를 호출하여 하이라이트 위치를 실시간으로 추적 (애니메이션 대응)
    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() {});
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void nextStep() {
    setState(() {
      if (_currentStepIndex < widget.steps.length - 1) {
        _currentStepIndex++;
        if (widget.onStepChanged != null) {
          widget.onStepChanged!(_currentStepIndex);
        }
      } else {
        widget.onComplete();
      }
    });
  }

  void _handleSkip() async {
    final shouldSkip = await AppDialog.show<bool>(
      context: context,
      key: AppDialogKey.skipTutorial,
    );

    if (shouldSkip == true && mounted) {
      if (widget.onSkip != null) {
        widget.onSkip!();
      } else {
        widget.onComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.steps[_currentStepIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          key: _overlayKey,
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // Background Dim with hole
              if (currentStep.targetKey != null && !currentStep.isPopupCard)
                _TutorialMask(
                  targetKey: currentStep.targetKey!,
                  overlayKey: _overlayKey,
                )
              else
                Container(color: Colors.black.withOpacity(0.7)),

              // Dialogue/Card
              _buildContent(currentStep),

              // Skip Button
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                child: GestureDetector(
                  onTap: _handleSkip,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.get('skip') ?? '스킵',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'BMJUA',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.fast_forward, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(TutorialStep step) {
    if (step.isPopupCard) {
      return Center(
        child: _buildPopupCard(step),
      );
    }

    // Force fixed position if requested
    if (step.isFixedBottom) {
      return Positioned(
        bottom: 80,
        left: 20,
        right: 20,
        child: _buildDialogueBubble(step, isBelow: true),
      );
    }

    // Dynamic positioning based on target
    final targetContext = step.targetKey?.currentContext;
    if (targetContext != null) {
      try {
        final renderObject = targetContext.findRenderObject();
        if (renderObject is RenderBox && renderObject.attached && renderObject.hasSize) {
          final renderBox = renderObject;
          final offset = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          final screenHeight = MediaQuery.of(context).size.height;

          // Decide above or below based on target position and available space
          final bool placeBelow = (offset.dy + size.height) < screenHeight * 0.65;

          if (placeBelow) {
            return Positioned(
              top: offset.dy + size.height + 10,
              left: 20,
              right: 20,
              child: _buildDialogueBubble(step, isBelow: true),
            );
          } else {
            return Positioned(
              bottom: screenHeight - offset.dy + 10,
              left: 20,
              right: 20,
              child: _buildDialogueBubble(step, isBelow: false),
            );
          }
        }
      } catch (e) {
        // 레이아웃 도중 에러 발생 시 이번 프레임은 건너뜀
        return const SizedBox.shrink();
      }
    }

    // If target is specified but not yet available, show nothing to avoid jumping
    if (step.targetKey != null && !step.isPopupCard) {
      return const SizedBox.shrink();
    }

    // Default position (No target)
    return Positioned(
      bottom: 120,
      left: 20,
      right: 20,
      child: _buildDialogueBubble(step, isBelow: false),
    );
  }

  Widget _buildDialogueBubble(TutorialStep step, {required bool isBelow}) {
    if ((step.title == null || step.title!.isEmpty) && step.text.isEmpty && step.extraContent == null) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isBelow) _buildBirdAndButton(step),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/images/Archive_Background.png'),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              if (step.title != null) ...[
                Text(
                  step.title!,
                  style: const TextStyle(
                    fontFamily: 'BMJUA',
                    fontSize: 18,
                    color: Color(0xFF5D4037),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                step.text,
                style: const TextStyle(
                  fontFamily: 'NanumPenScript-Regular',
                  fontSize: 22,
                  color: Color(0xFF5D4037),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              if (step.extraContent != null) ...[
                const SizedBox(height: 12),
                step.extraContent!,
              ],
            ],
          ),
        ),
        if (isBelow) ...[
          const SizedBox(height: 5),
          _buildBirdAndButton(step),
        ],
      ],
    );
  }

  Widget _buildBirdAndButton(TutorialStep step) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/icons/Charactor_Icon.png',
          width: 70,
          height: 70,
        ),
        if (step.showNextButton) _buildNextButton(),
      ],
    );
  }

  Widget _buildPopupCard(TutorialStep step) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/Archive_Background.png'),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (step.imagePath != null)
            Container(
              height: 150,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: AssetImage(step.imagePath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          Text(
            step.title ?? '',
            style: const TextStyle(
              fontFamily: 'BMJUA',
              fontSize: 22,
              color: Color(0xFF5D4037),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            step.text,
            style: const TextStyle(
              fontFamily: 'NanumPenScript-Regular',
              fontSize: 20,
              color: Color(0xFF6D4C41),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (step.showNextButton) _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final l10n = AppLocalizations.of(context);
    return _TutorialImageButton(
      onPressed: nextStep,
      label: _currentStepIndex < widget.steps.length - 1
          ? (l10n?.get('next') ?? '다음')
          : (l10n?.get('completed') ?? '완료'),
    );
  }
}

class _TutorialMask extends StatelessWidget {
  final GlobalKey targetKey;
  final GlobalKey overlayKey;

  const _TutorialMask({
    required this.targetKey,
    required this.overlayKey,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: _HoleClipper(
        targetKey: targetKey,
        overlayKey: overlayKey,
        child: Container(
          color: Colors.black.withOpacity(0.7),
        ),
      ),
    );
  }
}

class _HoleClipper extends StatelessWidget {
  final GlobalKey targetKey;
  final GlobalKey overlayKey;
  final Widget child;

  const _HoleClipper({
    required this.targetKey,
    required this.overlayKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _InvertedHoleClipper(
        targetKey: targetKey,
        overlayKey: overlayKey,
      ),
      child: child,
    );
  }
}

class _InvertedHoleClipper extends CustomClipper<Path> {
  final GlobalKey targetKey;
  final GlobalKey overlayKey;

  _InvertedHoleClipper({
    required this.targetKey,
    required this.overlayKey,
  });

  @override
  Path getClip(Size size) {
    final targetContext = targetKey.currentContext;
    if (targetContext == null) {
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final renderObject = targetContext.findRenderObject();
    if (renderObject == null ||
        renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      // 아직 레이아웃이 완료되지 않았으면 구멍을 뚫지 않고 전체 마스킹 처리
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    final renderBox = renderObject;
    final overlayBox = overlayKey.currentContext?.findRenderObject() as RenderBox?;

    // Calculate offset relative to overlayBox if available
    final offset = overlayBox != null
        ? renderBox.localToGlobal(Offset.zero, ancestor: overlayBox)
        : renderBox.localToGlobal(Offset.zero);

    final targetSize = renderBox.size;

    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(
            offset.dx - 4,
            offset.dy - 4,
            targetSize.width + 8,
            targetSize.height + 8,
          ),
          const Radius.circular(12),
        )),
    );
  }

  @override
  bool shouldReclip(_InvertedHoleClipper oldDelegate) => true;
}

class _TutorialImageButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const _TutorialImageButton({
    required this.onPressed,
    required this.label,
  });

  @override
  State<_TutorialImageButton> createState() => _TutorialImageButtonState();
}

class _TutorialImageButtonState extends State<_TutorialImageButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: Transform.scale(
        scale: _isPressed ? 0.95 : 1.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/Confirm_Button.png',
              width: 100,
              height: 44,
              fit: BoxFit.fill,
            ),
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'BMJUA',
                color: Color(0xFF4E342E),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TutorialStep {
  final GlobalKey? targetKey;
  final String text;
  final String? title;
  final String? imagePath;
  final bool isPopupCard;
  final bool isFixedBottom;
  final bool showNextButton;

  TutorialStep({
    this.targetKey,
    required this.text,
    this.title,
    this.imagePath,
    this.isPopupCard = false,
    this.isFixedBottom = false,
    this.extraContent,
    this.showNextButton = true,
  });

  final Widget? extraContent;
}

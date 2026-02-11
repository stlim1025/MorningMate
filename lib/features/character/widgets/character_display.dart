import 'package:flutter/material.dart';

class CharacterDisplay extends StatefulWidget {
  final bool isAwake;
  final int characterLevel;
  final double size;
  final bool isTapped;
  final bool enableAnimation;

  const CharacterDisplay({
    super.key,
    required this.isAwake,
    required this.characterLevel,
    required this.size,
    this.isTapped = false,
    this.enableAnimation = true,
  });

  @override
  State<CharacterDisplay> createState() => _CharacterDisplayState();
}

class _CharacterDisplayState extends State<CharacterDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.enableAnimation) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(CharacterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableAnimation != oldWidget.enableAnimation) {
      if (widget.enableAnimation) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Shared dimensions for the character components
    final double charWidth = widget.size;
    final double charHeight = widget.size;

    return Transform.scale(
      scale: widget.isAwake ? 1.0 : 0.8,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Wings (Level 2+) - Static layer
            if (widget.characterLevel >= 2)
              Image.asset(
                widget.characterLevel >= 3
                    ? 'assets/images/Egg_Wing2.png'
                    : 'assets/images/Egg_Wing.png',
                width: widget.characterLevel >= 3
                    ? (widget.isAwake ? charWidth * 2 : charWidth * 2.4)
                    : (widget.isAwake ? charWidth * 1.2 : charWidth * 1.44),
                height: widget.characterLevel >= 3
                    ? (widget.isAwake ? charHeight * 2 : charHeight * 2.4)
                    : (widget.isAwake ? charHeight : charHeight * 1.2),
                fit: BoxFit.contain,
                cacheWidth: 400,
              ),

            // 2. Base Body - Static layer
            Image.asset(
              widget.isAwake
                  ? 'assets/images/Body.png'
                  : 'assets/images/Sleep_Body.png',
              width: charWidth,
              height: charHeight,
              fit: BoxFit.contain,
              cacheWidth: 500,
            ),

            // 3. Expression Layer - Position face
            Positioned(
              top: widget.isAwake
                  ? charHeight * 0.18
                  : charHeight * 0.13, // 자고 있을 때 위로
              left: charWidth * 0.075,
              child: SizedBox(
                width: charWidth * 0.85,
                height: charHeight * 0.85,
                child: widget.enableAnimation
                    ? AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.center,
                        crossFadeState: widget.isTapped
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: Image.asset(
                          widget.isAwake
                              ? 'assets/images/Face_Default.png'
                              : 'assets/images/Face_Sleep.png',
                          fit: BoxFit.contain,
                          key: const ValueKey('face_normal'),
                          cacheWidth: 300,
                        ),
                        secondChild: Padding(
                          padding: EdgeInsets.only(
                            top: widget.isAwake
                                ? 10
                                : 0, // 자고 있을 때 패딩 제거하여 위로 올림
                          ),
                          child: Image.asset(
                            widget.isAwake
                                ? 'assets/images/Face_Wink.png'
                                : 'assets/images/Face_Drool.png',
                            fit: BoxFit.contain,
                            key: const ValueKey('face_tapped'),
                            cacheWidth: 300,
                          ),
                        ),
                      )
                    : Image.asset(
                        widget.isAwake
                            ? 'assets/images/Face_Default.png'
                            : 'assets/images/Face_Sleep.png',
                        fit: BoxFit.contain,
                        cacheWidth: 300,
                      ),
              ),
            ),

            // Zzz animation (if sleeping and animation enabled)
            if (!widget.isAwake && widget.enableAnimation)
              Positioned(
                top: -widget.size * 0.05,
                right: widget.size * 0.05,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        10 * (1 - _animationController.value),
                        -20 * _animationController.value,
                      ),
                      child: Opacity(
                        opacity:
                            (1 - _animationController.value).clamp(0.0, 1.0),
                        child: const Text(
                          'Z',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

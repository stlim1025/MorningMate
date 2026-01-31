import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';

class EnhancedCharacterRoomWidget extends StatefulWidget {
  final bool isAwake;
  final int characterLevel;
  final int consecutiveDays;

  const EnhancedCharacterRoomWidget({
    super.key,
    required this.isAwake,
    this.characterLevel = 1,
    this.consecutiveDays = 0,
  });

  @override
  State<EnhancedCharacterRoomWidget> createState() =>
      _EnhancedCharacterRoomWidgetState();
}

class _EnhancedCharacterRoomWidgetState
    extends State<EnhancedCharacterRoomWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  bool _isTapped = false;
  Timer? _tapTimer;

  void _handleTap() {
    if (_isTapped) return;
    setState(() {
      _isTapped = true;
    });
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isTapped = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    return Column(
      children: [
        _buildRoomInterior(widget.isAwake, colorScheme),
      ],
    );
  }

  Widget _buildRoomInterior(bool isAwake, AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isAwake
            ? colorScheme.backgroundLight // 테마 연동: 밝은 베이지
            : colorScheme.backgroundDark.withOpacity(0.8), // 테마 연동: 다크 모드 배경
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isAwake ? Colors.white.withOpacity(0.5) : Colors.white12,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildWallDecoration(isAwake, colorScheme),
          const SizedBox(height: 20),
          _buildBedAndCharacter(isAwake, colorScheme),
          const SizedBox(height: 20),
          _buildFloorDecoration(colorScheme),
        ],
      ),
    );
  }

  Widget _buildWallDecoration(bool isAwake, AppColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFrame(
          Icons.local_florist,
          isAwake
              ? colorScheme.secondary
              : colorScheme.secondary.withOpacity(0.5),
          colorScheme,
        ),
        const SizedBox(width: 40),
        _buildFrame(
          Icons.spa,
          isAwake ? colorScheme.accent : colorScheme.accent.withOpacity(0.5),
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildFrame(IconData icon, Color color, AppColorScheme colorScheme) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        border: Border.all(
            color: colorScheme.textSecondary.withOpacity(0.5), width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }

  Widget _buildBedAndCharacter(bool isAwake, AppColorScheme colorScheme) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            top: isAwake ? 0 : 20,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: isAwake
                    ? colorScheme.textSecondary.withOpacity(0.8)
                    : colorScheme.textSecondary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: isAwake
                          ? colorScheme.textSecondary
                          : colorScheme.textSecondary.withOpacity(0.6),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isAwake
                                ? colorScheme.secondary
                                : colorScheme.accent)
                            .withOpacity(0.5),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            top: widget.isAwake ? 80 : 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _handleTap,
                child: AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    double verticalOffset =
                        widget.isAwake ? -_bounceAnimation.value : 0;
                    if (_isTapped) verticalOffset -= 20;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform:
                          Matrix4.translationValues(0, verticalOffset, 0),
                      child: _buildCharacter(widget.isAwake, colorScheme),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacter(bool isAwake, AppColorScheme colorScheme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.5),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 90,
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.primaryButton, // 캐릭터 몸색을 테마 기본색으로
              borderRadius: const BorderRadius.all(Radius.circular(45)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // 얼굴색
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 25,
                        left: 18,
                        child: _isTapped
                            ? const Text('>',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16))
                            : isAwake
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : Container(
                                    width: 12,
                                    height: 2,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                      ),
                      Positioned(
                        top: 25,
                        right: 18,
                        child: _isTapped
                            ? const Text('<',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16))
                            : isAwake
                                ? Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : Container(
                                    width: 12,
                                    height: 2,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                      ),
                      Positioned(
                        top: 32,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _isTapped ? 16 : 12,
                            height: isAwake ? 10 : 6,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: isAwake
                                  ? const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                      topLeft: Radius.circular(2),
                                      topRight: Radius.circular(2),
                                    )
                                  : BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        right: 12,
                        child: Container(
                          width: 15,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colorScheme.error.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 5,
            top: 25,
            child: Container(
              width: 20,
              height: 30,
              decoration: BoxDecoration(
                color: colorScheme.primaryButton,
                borderRadius: const BorderRadius.all(Radius.circular(15)),
              ),
            ),
          ),
          if (!isAwake)
            Positioned(
              top: -20,
              right: 0,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Transform.translate(
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
                      ),
                      Transform.translate(
                        offset: Offset(
                          20 * (1 - ((_animationController.value + 0.5) % 1.0)),
                          -30 * ((_animationController.value + 0.5) % 1.0),
                        ),
                        child: Opacity(
                          opacity:
                              (1 - ((_animationController.value + 0.5) % 1.0))
                                  .clamp(0.0, 1.0),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 15, top: 10),
                            child: Text(
                              'z',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloorDecoration(AppColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPlant(colorScheme.accent, colorScheme),
        const SizedBox(width: 20),
        _buildPlant(colorScheme.success, colorScheme),
      ],
    );
  }

  Widget _buildPlant(Color color, AppColorScheme colorScheme) {
    return SizedBox(
      width: 50,
      height: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.spa, color: color, size: 35),
          Container(
            width: 50,
            height: 25,
            decoration: BoxDecoration(
              color: Colors.brown.withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

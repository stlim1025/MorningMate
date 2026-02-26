import 'package:flutter/material.dart';

/// 앱 공통 로딩 위젯 — 캐릭터가 제자리에서 통통 튀는 애니메이션
class BouncingCharacterLoader extends StatefulWidget {
  const BouncingCharacterLoader({super.key});

  @override
  State<BouncingCharacterLoader> createState() =>
      _BouncingCharacterLoaderState();
}

class _BouncingCharacterLoaderState extends State<BouncingCharacterLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInQuart,
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _bounceController,
        builder: (context, child) {
          final t = _bounceAnimation.value;
          final jumpOffset = -30.0 * (1.0 - t);
          final scaleX = 1.0 + 0.12 * t;
          final scaleY = 1.0 - 0.10 * t;

          return Transform.translate(
            offset: Offset(0, jumpOffset),
            child: Transform.scale(
              scaleX: scaleX,
              scaleY: scaleY,
              alignment: Alignment.bottomCenter,
              child: Image.asset(
                'assets/icons/Charactor_Icon.png',
                width: 110,
                height: 110,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

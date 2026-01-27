import 'package:flutter/material.dart';
import 'dart:math' as math;

class NightSkyBackground extends StatefulWidget {
  final Widget child;
  final bool isDayTime;

  const NightSkyBackground({
    super.key,
    required this.child,
    this.isDayTime = false,
  });

  @override
  State<NightSkyBackground> createState() => _NightSkyBackgroundState();
}

class _NightSkyBackgroundState extends State<NightSkyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 배경 그라데이션
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.isDayTime
                  ? [
                      const Color(0xFF87CEEB), // 하늘색
                      const Color(0xFFB0E0E6),
                    ]
                  : [
                      const Color(0xFF0F2027), // 어두운 밤
                      const Color(0xFF203A43),
                      const Color(0xFF2C5364),
                    ],
            ),
          ),
        ),

        // 해/달/별 배경 레이어
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 1000),
          child: widget.isDayTime
              ? _buildDaylight(key: const ValueKey('day'))
              : _buildNight(key: const ValueKey('night')),
        ),

        // 자식 위젯
        widget.child,
      ],
    );
  }

  Widget _buildDaylight({required Key key}) {
    return Stack(
      key: key,
      children: [
        Positioned(
          top: 80,
          right: 40,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD700),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNight({required Key key}) {
    return Stack(
      key: key,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: StarsPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
        Positioned(
          top: 80,
          right: 40,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF8DC),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFF8DC).withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 15,
                  left: 20,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8DCC0),
                    ),
                  ),
                ),
                Positioned(
                  top: 35,
                  left: 35,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8DCC0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class StarsPainter extends CustomPainter {
  final double animation;
  final math.Random random = math.Random(42); // 고정된 시드로 별 위치 일정하게

  StarsPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    // 50개의 별 그리기
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final starSize = random.nextDouble() * 2 + 1;

      // 깜빡임 효과
      final twinkle = (math.sin(animation * 2 * math.pi + i) + 1) / 2;
      paint.color = Colors.white.withOpacity(0.3 + twinkle * 0.7);

      canvas.drawCircle(Offset(x, y), starSize, paint);

      // 밝은 별은 십자 모양 추가
      if (starSize > 2) {
        paint.color = Colors.white.withOpacity(0.2 + twinkle * 0.5);
        canvas.drawLine(
          Offset(x - 3, y),
          Offset(x + 3, y),
          paint..strokeWidth = 0.5,
        );
        canvas.drawLine(
          Offset(x, y - 3),
          Offset(x, y + 3),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

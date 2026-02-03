import 'dart:math';
import 'package:flutter/material.dart';

class TwinklingStarsWidget extends StatefulWidget {
  final int starCount;
  const TwinklingStarsWidget({super.key, this.starCount = 60});

  @override
  State<TwinklingStarsWidget> createState() => _TwinklingStarsWidgetState();
}

class _TwinklingStarsWidgetState extends State<TwinklingStarsWidget>
    with SingleTickerProviderStateMixin {
  late List<StarData> _stars;
  late AnimationController _controller;
  final Random _random = Random();

  // 별똥별 관리를 위한 변수들
  double _shootingStarProgress = 0.0;
  bool _isShootingStarActive = false;
  late Offset _startPos;
  late Offset _endPos;

  @override
  void initState() {
    super.initState();
    _stars = List.generate(widget.starCount, (index) => _generateStar());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // 전체적인 애니메이션 주기를 길게 가져감
    )..repeat();

    _controller.addListener(() {
      // 별똥별 랜덤 발생 로직 (1% 확률로 새로운 별똥별 시작)
      if (!_isShootingStarActive && _random.nextDouble() < 0.005) {
        _startShootingStar();
      }
    });
  }

  void _startShootingStar() {
    setState(() {
      _isShootingStarActive = true;
      _shootingStarProgress = 0.0;

      // 랜덤 시작 위치 (상단 좌측 영역)
      _startPos =
          Offset(_random.nextDouble() * 0.7, _random.nextDouble() * 0.4);

      // 랜덤 끝 위치 (시작 위치에서 대각선 방향으로)
      _endPos = Offset(_startPos.dx + 0.3 + _random.nextDouble() * 0.2,
          _startPos.dy + 0.2 + _random.nextDouble() * 0.2);
    });

    // 별똥별 전용 애니메이션 (한 번만 실행)
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) return false;

      setState(() {
        _shootingStarProgress += 0.02; // 속도 조절
      });

      if (_shootingStarProgress >= 1.5) {
        // 꼬리까지 완전히 사라질 때까지
        setState(() {
          _isShootingStarActive = false;
        });
        return false;
      }
      return true;
    });
  }

  StarData _generateStar() {
    return StarData(
      x: _random.nextDouble(),
      y: _random.nextDouble() * 0.7, // 상단 70% 영역
      size: _random.nextDouble() * 2.2 + 0.3,
      // 깜빡임 속도를 더 늦춤
      twinkleSpeed: _random.nextDouble() * 0.02 + 0.005,
      twinkleOffset: _random.nextDouble() * pi * 2,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: StarsPainter(
            stars: _stars,
            animationValue: _controller.value,
            shootingStarProgress:
                _isShootingStarActive ? _shootingStarProgress : null,
            startPos: _isShootingStarActive ? _startPos : null,
            endPos: _isShootingStarActive ? _endPos : null,
          ),
        );
      },
    );
  }
}

class StarData {
  final double x;
  final double y;
  final double size;
  final double twinkleSpeed;
  final double twinkleOffset;

  StarData({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
    required this.twinkleOffset,
  });
}

class StarsPainter extends CustomPainter {
  final List<StarData> stars;
  final double animationValue;
  final double? shootingStarProgress;
  final Offset? startPos;
  final Offset? endPos;

  StarsPainter({
    required this.stars,
    required this.animationValue,
    this.shootingStarProgress,
    this.startPos,
    this.endPos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseStarColor = const Color(0xFFE6F3FF);
    final paint = Paint()..color = baseStarColor;

    // 1. 일반 별 그리기
    for (var star in stars) {
      // sin wave를 이용한 부드러운 깜빡임 (속도 더 천천히)
      final opacity = (sin(animationValue * pi * 2 * (star.twinkleSpeed * 150) +
                  star.twinkleOffset) +
              1) /
          2;

      final finalOpacity = 0.08 + (opacity * 0.45);
      paint.color = baseStarColor.withOpacity(finalOpacity);

      final position = Offset(star.x * size.width, star.y * size.height);
      canvas.drawCircle(position, star.size, paint);

      if (finalOpacity > 0.6) {
        final glowPaint = Paint()
          ..color = baseStarColor.withOpacity(finalOpacity * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        canvas.drawCircle(position, star.size * 1.8, glowPaint);
      }
    }

    // 2. 별똥별 그리기
    if (shootingStarProgress != null && startPos != null && endPos != null) {
      _drawShootingStar(canvas, size);
    }
  }

  void _drawShootingStar(Canvas canvas, Size size) {
    final progress = shootingStarProgress!;
    if (progress > 1.2) return;

    final actualStart =
        Offset(startPos!.dx * size.width, startPos!.dy * size.height);
    final actualEnd = Offset(endPos!.dx * size.width, endPos!.dy * size.height);

    // 현재 헤드 위치
    final headProg = progress.clamp(0.0, 1.0);
    final currentPos = Offset.lerp(actualStart, actualEnd, headProg)!;

    // 꼬리 위치 (헤드보다 약간 뒤처짐)
    final tailProg = (progress - 0.25).clamp(0.0, 1.0);
    final tailPos = Offset.lerp(actualStart, actualEnd, tailProg)!;

    final starPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          baseStarColor.withOpacity(0.85),
          baseStarColor.withOpacity(0.0),
        ],
        begin: Alignment(
          (currentPos.dx / size.width) * 2 - 1,
          (currentPos.dy / size.height) * 2 - 1,
        ),
        end: Alignment(
          (tailPos.dx / size.width) * 2 - 1,
          (tailPos.dy / size.height) * 2 - 1,
        ),
      ).createShader(Rect.fromPoints(currentPos, tailPos));

    final path = Path()
      ..moveTo(currentPos.dx, currentPos.dy)
      ..lineTo(tailPos.dx, tailPos.dy);

    canvas.drawPath(
      path,
      Paint()
        ..shader = starPaint.shader
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // 헤드 부분의 작은 빛
    canvas.drawCircle(
        currentPos,
        1.2 * (1.0 - progress.clamp(0.0, 1.0)),
        Paint()
          ..color =
              baseStarColor.withOpacity((1.0 - progress).clamp(0.0, 1.0)));
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) => true;
}

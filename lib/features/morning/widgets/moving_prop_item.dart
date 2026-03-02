import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/widgets/network_or_asset_image.dart';

/// 움직이는 소품을 위한 공통 컴포넌트
class MovingPropItem extends StatefulWidget {
  final String imagePath;
  final double size;
  final int durationSeconds;
  final double yOffset;
  final bool flipped; // 이미지 기본 방향이 반대인 경우 사용
  final double moveRange; // 좌우 이동 폭
  final bool useWaveEffect; // 상하로 일렁이는 효과 사용 여부

  const MovingPropItem({
    super.key,
    required this.imagePath,
    required this.size,
    required this.durationSeconds,
    this.yOffset = 0,
    this.flipped = false,
    this.moveRange = 100,
    this.useWaveEffect = true,
  });

  @override
  State<MovingPropItem> createState() => _MovingPropItemState();
}

class _MovingPropItemState extends State<MovingPropItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _faceRight = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _faceRight = false);
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          setState(() => _faceRight = true);
          _controller.forward();
        }
      });

    _animation = Tween<double>(begin: -0.35, end: 0.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 각 인스턴스가 다른 타이밍에 시작하도록 무작위 시작점 설정
    _controller.forward(from: Random().nextDouble());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double rotationY = 0;
        if (widget.flipped) {
          rotationY = _faceRight ? pi : 0;
        } else {
          rotationY = _faceRight ? 0 : pi;
        }

        return Center(
          child: Transform.translate(
            offset: Offset(
              _animation.value * widget.moveRange,
              widget.yOffset +
                  (widget.useWaveEffect ? sin(_animation.value * 5) * 5 : 0),
            ),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(rotationY),
              child: NetworkOrAssetImage(
                imagePath: widget.imagePath,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}

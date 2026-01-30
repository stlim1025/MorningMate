import 'dart:math';
import 'package:flutter/material.dart';

class TwinklingStars extends StatefulWidget {
  const TwinklingStars({super.key});

  @override
  State<TwinklingStars> createState() => _TwinklingStarsState();
}

class _TwinklingStarsState extends State<TwinklingStars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Star> _stars = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Generate random stars
    for (int i = 0; i < 20; i++) {
      _stars.add(_Star(
        left: _random.nextDouble(),
        top: _random.nextDouble() * 0.5, // Only in top half
        size: _random.nextDouble() * 3 + 1,
        opacity: _random.nextDouble(),
      ));
    }
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
        return Stack(
          children: _stars.map((star) {
            final opacity = (star.opacity + sin(_controller.value * pi) * 0.5)
                .clamp(0.2, 1.0);
            return Positioned(
              left: MediaQuery.of(context).size.width * star.left,
              top: MediaQuery.of(context).size.height * star.top,
              child: Opacity(
                opacity: opacity,
                child: Icon(
                  Icons.star,
                  color: Colors.white,
                  size: star.size,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Star {
  final double left;
  final double top;
  final double size;
  final double opacity;

  _Star({
    required this.left,
    required this.top,
    required this.size,
    required this.opacity,
  });
}

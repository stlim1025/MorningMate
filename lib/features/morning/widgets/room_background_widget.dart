import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../data/models/room_decoration_model.dart';
import 'twinkling_stars_widget.dart';

class RoomBackgroundWidget extends StatelessWidget {
  final RoomDecorationModel decoration;
  final bool isDarkMode;
  final AppColorScheme colorScheme;
  final bool isAwake;

  const RoomBackgroundWidget({
    super.key,
    required this.decoration,
    required this.isDarkMode,
    required this.colorScheme,
    this.isAwake = true, // Default to true if not provided, or use logic
  });

  @override
  Widget build(BuildContext context) {
    final backgroundImagePath = _backgroundImagePath(decoration.backgroundId);
    return Stack(
      children: [
        if (backgroundImagePath == null)
          Container(
            color: isAwake
                ? const Color(0xFFBFE7FF)
                : const Color(0xFF101525),
          ),
        if (backgroundImagePath != null)
          Positioned.fill(
            child: Image.asset(
              backgroundImagePath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

        // Stars (if night)
        if (decoration.backgroundId == 'starry_night' ||
            decoration.backgroundId == 'blue_moon')
          const Positioned.fill(
            child: TwinklingStarsWidget(starCount: 100),
          ),

        if (decoration.backgroundId == 'golden_sun')
          const Positioned.fill(
            child: AuroraBurstEffect(),
          ),
      ],
    );
  }

  String? _backgroundImagePath(String backgroundId) {
    switch (backgroundId) {
      case 'blue_moon':
        return 'assets/images/BlueMoon.png';
      case 'golden_sun':
        return 'assets/images/SunShine.png';
      case 'starry_night':
        return 'assets/images/NightMoon.png';
      default:
        return null;
    }
  }

}

class AuroraBurstEffect extends StatefulWidget {
  const AuroraBurstEffect({super.key});

  @override
  State<AuroraBurstEffect> createState() => _AuroraBurstEffectState();
}

class _AuroraBurstEffectState extends State<AuroraBurstEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
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
          painter: _AuroraPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double progress;

  _AuroraPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center =
        Offset(size.width - 80, 120); // Align with sun position roughly
    final maxRadius = size.shortestSide * 0.9;

    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + (i * 0.25)) % 1.0;
      final radius = maxRadius * (0.35 + waveProgress * 0.65);
      final opacity = (1 - waveProgress).clamp(0.0, 1.0) * 0.35;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF0A6).withOpacity(opacity),
            const Color(0xFFFFB347).withOpacity(opacity * 0.7),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

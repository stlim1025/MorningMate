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
    // 1. Determine Background Colors
    List<Color> gradientColors;

    // Use Background ID to decide colors
    // We can also mix in 'isAwake' logic if we want "Day/Night" versions of each background
    switch (decoration.backgroundId) {
      case 'golden_sun': // Sunset (노을)
        gradientColors = [
          const Color(0xFFFF5F6D), // Soft Pinkish Red
          const Color(0xFFFF8C00), // Dark Orange
          const Color(0xFFFFD194), // Warm Sand/Yellow
        ];
        break;
      case 'blue_moon': // Night
      case 'starry_night':
        gradientColors = [
          const Color(0xFF0D0221), // Dark Navy
          const Color(0xFF240B36), // Deep Purple
        ];
        break;
      default: // Default (depends on isAwake, but NOT on UI theme)
        if (decoration.backgroundId != 'default' &&
            decoration.backgroundId.isNotEmpty) {
          // If it's some other ID we don't know, fallback to default logic
        }

        // Fixed colors for room background (independent of UI theme)
        gradientColors = isAwake
            ? [
                const Color(0xFF87CEEB), // Sky Blue
                const Color(0xFFB0E0E6), // Powder Blue
                const Color(0xFFE0F7FA), // Light Cyan
              ]
            : [
                const Color(0xFF0D0221), // Dark Navy
                const Color(0xFF1A1A2E), // Deep Blue
                const Color(0xFF240B36), // Deep Purple
              ];
    }

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

        // Clouds (specifically for golden_sun/sunset)
        if (decoration.backgroundId == 'golden_sun') ..._buildSunsetClouds(),
        if (decoration.backgroundId == 'golden_sun')
          const Positioned.fill(
            child: AuroraBurstEffect(),
          ),

        // Celestial Body (Sun/Moon)
        if (decoration.backgroundId != 'none')
          Positioned(
            top: 90, // Position matches MorningScreen
            right: 30,
            child: _buildCelestialBody(),
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

  List<Widget> _buildSunsetClouds() {
    return [
      Positioned(
        top: 60,
        left: -10,
        child: _buildCloud(
          width: 170,
          height: 65,
          color: const Color(0xFFFF7E5F).withOpacity(0.8),
        ),
      ),
      Positioned(
        top: 140,
        right: -20,
        child: _buildCloud(
          width: 200,
          height: 75,
          color: const Color(0xFFFEB47B).withOpacity(0.75),
        ),
      ),
      Positioned(
        top: 240,
        left: 50,
        child: _buildCloud(
          width: 140,
          height: 55,
          color: const Color(0xFFFF6A88).withOpacity(0.7),
        ),
      ),
    ];
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

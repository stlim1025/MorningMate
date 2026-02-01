import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../data/models/room_decoration_model.dart';

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
    // 1. Determine Background Colors
    List<Color> gradientColors;

    // Use Background ID to decide colors
    // We can also mix in 'isAwake' logic if we want "Day/Night" versions of each background
    switch (decoration.backgroundId) {
      case 'golden_sun': // Sunny Day
        gradientColors = [
          const Color(0xFF87CEEB), // Sky Blue
          const Color(0xFFE0F7FA), // Light Cyan
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
        // Gradient Base
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
        ),

        // Stars (if night)
        if (decoration.backgroundId == 'starry_night' ||
            decoration.backgroundId == 'blue_moon')
          ...List.generate(20, (index) {
            final x = (index * 0.17 + 0.1) % 1.0;
            final y = (index * 0.23 + 0.05) % 0.6; // Only top half
            final size = (index % 3 + 1.5).toDouble();
            return Positioned(
              left: x * 400, // Approximate width
              top: y * 600, // Approximate height
              child: Opacity(
                opacity: 0.3 + (index % 5) * 0.1,
                child: Icon(Icons.circle, color: Colors.white, size: size),
              ),
            );
          }),

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

  Widget _buildCelestialBody() {
    Color color;
    List<BoxShadow> shadows;

    switch (decoration.backgroundId) {
      case 'golden_sun':
        color = Colors.orangeAccent;
        shadows = [
          BoxShadow(
              color: Colors.orange.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: 10),
        ];
        break;
      case 'blue_moon':
        color = Colors.blueAccent.shade100;
        shadows = [
          BoxShadow(
              color: Colors.blueAccent.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: 10),
        ];
        break;
      case 'starry_night':
        color = Colors.white;
        shadows = [
          BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5),
        ];
        break;
      default: // Default checks isAwake
        color = isAwake ? colorScheme.pointStar : const Color(0xFFFFF8DC);
        shadows = [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 8,
          ),
        ];
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: shadows,
      ),
    );
  }
}

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
          const Positioned.fill(
            child: TwinklingStarsWidget(starCount: 100),
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

  Widget _buildCelestialBody() {
    Color color;
    List<BoxShadow> shadows;

    switch (decoration.backgroundId) {
      case 'golden_sun':
        color = const Color(0xFFFF4500); // Deep Orange Red
        shadows = [
          BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 50,
              spreadRadius: 15),
          BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 80,
              spreadRadius: 5),
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
        gradient: (decoration.backgroundId == 'blue_moon' ||
                decoration.backgroundId == 'starry_night' ||
                decoration.backgroundId == 'golden_sun')
            ? RadialGradient(
                colors: [
                  decoration.backgroundId == 'golden_sun'
                      ? const Color(0xFFFFD700) // Gold
                      : color,
                  decoration.backgroundId == 'golden_sun'
                      ? const Color(0xFFFF4500) // Deep Orange
                      : color.withOpacity(0.8),
                ],
                center: decoration.backgroundId == 'golden_sun'
                    ? const Alignment(0, 0)
                    : const Alignment(-0.3, -0.3),
              )
            : null,
        boxShadow: shadows,
      ),
      child: (decoration.backgroundId == 'blue_moon' ||
              decoration.backgroundId == 'starry_night')
          ? Stack(
              children: [
                // Crater 1
                Positioned(
                  top: 12,
                  left: 15,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.08),
                    ),
                  ),
                ),
                // Crater 2
                Positioned(
                  bottom: 15,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.06),
                    ),
                  ),
                ),
                // Crater 3
                Positioned(
                  top: 25,
                  right: 18,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

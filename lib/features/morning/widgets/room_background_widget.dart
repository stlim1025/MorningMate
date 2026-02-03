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
    this.isAwake = true,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundImagePath = _backgroundImagePath(decoration.backgroundId);

    return Stack(
      children: [
        // 1. 기본 배경색 (이미지가 없을 경우)
        if (backgroundImagePath == null)
          Container(
            color: isAwake ? const Color(0xFFBFE7FF) : const Color(0xFF101525),
          ),

        // 2. 배경 이미지
        if (backgroundImagePath != null)
          Positioned.fill(
            child: Image.asset(
              backgroundImagePath,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

        // 3. 별 및 별똥별 효과 (푸른달, 별이 빛나는 밤 테마에서만 적용)
        if (decoration.backgroundId == 'starry_night' ||
            decoration.backgroundId == 'blue_moon')
          const Positioned.fill(
            child: TwinklingStarsWidget(starCount: 100),
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

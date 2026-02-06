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
    this.isAwake = true,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundImagePath = _backgroundImagePath(decoration.backgroundId);

    Widget backgroundContent = Stack(
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
              cacheWidth: 400, // Reduced from 800 as it's for a small window
              alignment: Alignment.topCenter,
            ),
          ),
      ],
    );

    // 밤 모드 어두운 효과는 morning_screen.dart에서 전체 오버레이로 처리됨

    return backgroundContent;
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

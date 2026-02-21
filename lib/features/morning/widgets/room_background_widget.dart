import 'package:flutter/material.dart';
import 'package:morni/core/constants/room_assets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../data/models/room_decoration_model.dart';
import '../../../core/widgets/network_or_asset_image.dart';

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
            child: NetworkOrAssetImage(
              imagePath: backgroundImagePath,
              fit: BoxFit.cover,
            ),
          ),
      ],
    );

    // 밤 모드 어두운 효과는 morning_screen.dart에서 전체 오버레이로 처리됨

    return backgroundContent;
  }

  String? _backgroundImagePath(String backgroundId) {
    List<RoomAsset> assets = RoomAssets.backgrounds;
    try {
      final asset = RoomAssets.backgrounds.firstWhere(
        (item) => item.id == backgroundId,
      );
      return asset.imagePath ?? null;
    } catch (e) {
      // 해당 ID가 리스트에 없을 경우 예외 처리
      return null;
    }
  }
}

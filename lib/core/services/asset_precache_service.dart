import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/room_assets.dart';
import '../constants/character_assets.dart';

class AssetPrecacheService {
  static final AssetPrecacheService _instance =
      AssetPrecacheService._internal();
  factory AssetPrecacheService() => _instance;
  AssetPrecacheService._internal();

  bool _isPrecaching = false;
  bool _isDone = false;

  bool get isPrecaching => _isPrecaching;
  bool get isDone => _isDone;

  ImageProvider _getProvider(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImageProvider(path);
    }
    return AssetImage(path);
  }

  /// 개별 이미지 프리캐싱 - 실패해도 다른 이미지에 영향 없음
  Future<void> _safePrecache(String path, BuildContext context) async {
    try {
      await precacheImage(_getProvider(path), context);
    } catch (e) {
      // Firebase Storage URL(403 등) 또는 로컬 에셋 로드 실패 시 조용히 무시.
      // 실제 화면 표시는 CachedNetworkImage/Image.asset이 직접 처리함.
      if (path.startsWith('http')) {
        debugPrint('[Precache] 네트워크 이미지 프리캐싱 실패 (무시됨): $path');
      }
    }
  }

  /// Pre-caches all essential room assets.
  /// This should be called early in the app lifecycle (e.g., in MorningScreen).
  Future<void> precacheAllRoomAssets(BuildContext context) async {
    if (_isPrecaching || _isDone) return;
    _isPrecaching = true;

    try {
      final List<Future<void>> precacheTasks = [];

      // 1. Wallpapers
      for (var asset in RoomAssets.wallpapers) {
        if (asset.imagePath != null) {
          precacheTasks.add(_safePrecache(asset.imagePath!, context));
        }
      }

      // 2. Backgrounds
      for (var asset in RoomAssets.backgrounds) {
        if (asset.imagePath != null) {
          precacheTasks.add(_safePrecache(asset.imagePath!, context));
        }
      }

      // 3. Floors
      for (var asset in RoomAssets.floors) {
        if (asset.imagePath != null) {
          precacheTasks.add(_safePrecache(asset.imagePath!, context));
        }
      }

      // 4. Essential Props
      for (var asset in RoomAssets.props) {
        if (asset.imagePath != null) {
          precacheTasks.add(_safePrecache(asset.imagePath!, context));
        }
      }

      // 5. Emoticons
      for (var asset in RoomAssets.emoticons) {
        if (asset.imagePath != null) {
          precacheTasks.add(_safePrecache(asset.imagePath!, context));
        }
      }

      // 개별 실패가 있어도 나머지는 정상 완료됨
      await Future.wait(precacheTasks);
      _isDone = true;
    } catch (e) {
      debugPrint('Error during asset precaching: $e');
    } finally {
      _isPrecaching = false;
    }
  }

  /// Pre-caches items in a specific category (opportunistic caching).
  Future<void> precacheCategory(BuildContext context, String category) async {
    final List<Future<void>> precacheTasks = [];

    if (category == 'wallpaper') {
      for (var asset in RoomAssets.wallpapers) {
        if (asset.imagePath != null) {
          precacheTasks.add(_safePrecache(asset.imagePath!, context));
        }
      }
    } else if (category == 'background') {
      for (var asset in RoomAssets.backgrounds) {
        if (asset.imagePath != null) {
          precacheTasks.add(_safePrecache(asset.imagePath!, context));
        }
      }
    } else if (category == 'floor') {
      for (var asset in RoomAssets.floors) {
        if (asset.imagePath != null) {
          precacheTasks.add(_safePrecache(asset.imagePath!, context));
        }
      }
    } else if (category == 'props' || category == 'prop') {
      for (var asset in RoomAssets.props) {
        if (asset.imagePath != null) {
          precacheTasks.add(_safePrecache(asset.imagePath!, context));
        }
      }
    } else if (category == 'emoticon') {
      for (var asset in RoomAssets.emoticons) {
        if (asset.imagePath != null) {
          precacheTasks.add(_safePrecache(asset.imagePath!, context));
        }
      }
    } else if (category == 'character') {
      for (var asset in CharacterAssets.items) {
        if (asset.imagePath != null) {
          precacheTasks.add(_safePrecache(asset.imagePath!, context));
        }
      }
    }

    if (precacheTasks.isNotEmpty) {
      await Future.wait(precacheTasks);
    }
  }
}

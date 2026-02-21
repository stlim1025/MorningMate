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
          precacheTasks
              .add(precacheImage(_getProvider(asset.imagePath!), context));
        }
      }

      // 2. Backgrounds
      for (var asset in RoomAssets.backgrounds) {
        if (asset.imagePath != null) {
          precacheTasks
              .add(precacheImage(_getProvider(asset.imagePath!), context));
        }
      }

      // 3. Floors
      for (var asset in RoomAssets.floors) {
        if (asset.imagePath != null) {
          precacheTasks
              .add(precacheImage(_getProvider(asset.imagePath!), context));
        }
      }

      // 4. Essential Props (Icons and common items)
      for (var asset in RoomAssets.props) {
        if (asset.imagePath != null) {
          // Pre-cache with a smaller size for performance if needed,
          // but precacheImage uses the default cache.
          precacheTasks
              .add(precacheImage(_getProvider(asset.imagePath!), context));
        }
      }

      // 5. Emoticons
      for (var asset in RoomAssets.emoticons) {
        if (asset.imagePath != null) {
          precacheTasks
              .add(precacheImage(_getProvider(asset.imagePath!), context));
        }
      }

      // Wait for all to complete
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
          precacheTasks
              .add(precacheImage(_getProvider(asset.imagePath!), context));
        }
      }
    } else if (category == 'background') {
      for (var asset in RoomAssets.backgrounds) {
        if (asset.imagePath != null) {
          precacheTasks
              .add(precacheImage(_getProvider(asset.imagePath!), context));
        }
      }
    } else if (category == 'floor') {
      for (var asset in RoomAssets.floors) {
        if (asset.imagePath != null) {
          precacheTasks
              .add(precacheImage(_getProvider(asset.imagePath!), context));
        }
      }
    } else if (category == 'props' || category == 'prop') {
      for (var asset in RoomAssets.props) {
        if (asset.imagePath != null) {
          precacheTasks
              .add(precacheImage(_getProvider(asset.imagePath!), context));
        }
      }
    } else if (category == 'emoticon') {
      for (var asset in RoomAssets.emoticons) {
        if (asset.imagePath != null) {
          precacheTasks
              .add(precacheImage(_getProvider(asset.imagePath!), context));
        }
      }
    } else if (category == 'character') {
      for (var asset in CharacterAssets.items) {
        if (asset.imagePath != null) {
          precacheTasks
              .add(precacheImage(_getProvider(asset.imagePath!), context));
        }
      }
    }

    if (precacheTasks.isNotEmpty) {
      await Future.wait(precacheTasks);
    }
  }
}

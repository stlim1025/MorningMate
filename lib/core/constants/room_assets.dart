import 'package:flutter/material.dart';
import '../theme/app_theme_type.dart';

class RoomAsset {
  final String id;
  final String name;
  final int price;
  final IconData icon;
  final Color? color;
  final AppThemeType? themeType;
  final String? imagePath;
  final double sizeMultiplier;

  const RoomAsset({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    this.color,
    this.themeType,
    this.imagePath,
    this.sizeMultiplier = 1.0,
  });
}

class RoomAssets {
  static const List<RoomAsset> themes = [
    RoomAsset(
      id: 'light',
      name: '라이트',
      price: 0,
      icon: Icons.wb_sunny,
      themeType: AppThemeType.light,
      color: Color(0xFFFFF9DB), // Warm Light
    ),
    RoomAsset(
      id: 'dark',
      name: '다크',
      price: 100,
      icon: Icons.dark_mode,
      themeType: AppThemeType.dark,
      color: Color(0xFF2C3E50), // Dark Navy
    ),
    RoomAsset(
      id: 'sky',
      name: '하늘',
      price: 100,
      icon: Icons.wb_sunny_outlined,
      themeType: AppThemeType.sky,
      color: Color(0xFF87CEEB), // Sky Blue
    ),
    RoomAsset(
      id: 'purple',
      name: '퍼플',
      price: 100,
      icon: Icons.auto_awesome,
      themeType: AppThemeType.purple,
      color: Color(0xFFDCD6F7), // Light Purple
    ),
    RoomAsset(
      id: 'pink',
      name: '핑크',
      price: 100,
      icon: Icons.favorite,
      themeType: AppThemeType.pink,
      color: Color(0xFFFFC0CB), // Pink
    ),
  ];

  static const List<RoomAsset> wallpapers = [
    RoomAsset(
        id: 'default',
        name: '기본',
        price: 0,
        icon: Icons.check_box_outline_blank, // Plain
        color: Color(0xFFF5F5DC)),
    RoomAsset(
        id: 'classic',
        name: '클래식',
        price: 100,
        icon: Icons.window, // Grid-like
        color: Color(0xFFD7CCC8)),
    RoomAsset(
        id: 'stripe',
        name: '스트라이프',
        price: 100,
        icon: Icons.view_week, // Vertical stripes
        color: Color(0xFFB3E5FC),
        imagePath: 'assets/images/SpliteSky.png'),
    RoomAsset(
        id: 'check',
        name: '체크',
        price: 100,
        icon: Icons.grid_4x4, // Checks
        color: Color(0xFFC8E6C9),
        imagePath: 'assets/images/CheckGreen.png'),
    RoomAsset(
        id: 'dot',
        name: '도트',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        color: Color(0xFFFFF9C4),
        imagePath: 'assets/images/DotPink.png'),
    RoomAsset(
        id: 'dark_wall',
        name: '다크벽지',
        price: 100,
        icon: Icons.brightness_3, // Dark theme hint
        color: Color(0xFF424242)),
  ];

  static const List<RoomAsset> backgrounds = [
    RoomAsset(
        id: 'default', name: '기본(달)', price: 0, icon: Icons.nightlight_round),
    RoomAsset(
        id: 'blue_moon',
        name: '푸른 달',
        price: 100,
        icon: Icons.circle,
        color: Colors.blueAccent),
    RoomAsset(
        id: 'golden_sun',
        name: '황금 태양',
        price: 100,
        icon: Icons.wb_sunny,
        color: Colors.orangeAccent),
    RoomAsset(
        id: 'starry_night',
        name: '별이 빛나는 밤',
        price: 100,
        icon: Icons.star,
        color: Colors.indigo),
  ];

  static const List<RoomAsset> props = [
    RoomAsset(id: 'bed', name: '침대', price: 100, icon: Icons.bed),
    RoomAsset(id: 'plant', name: '화분', price: 100, icon: Icons.local_florist),
    RoomAsset(id: 'bear', name: '곰돌이', price: 100, icon: Icons.pets),
    RoomAsset(id: 'lamp', name: '램프', price: 100, icon: Icons.lightbulb),
    RoomAsset(id: 'frame', name: '액자', price: 100, icon: Icons.crop_original),
    RoomAsset(
      id: 'alarm_clock',
      name: '알람시계',
      price: 150,
      icon: Icons.alarm,
      imagePath: 'assets/items/AlarmClock.png',
    ),
    RoomAsset(
      id: 'wood_desk',
      name: '원목 책상',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/WoodDesk.png',
      sizeMultiplier: 3.0,
    ),
  ];

  static const List<RoomAsset> floors = [
    RoomAsset(
        id: 'default',
        name: '기본 바닥',
        price: 0,
        icon: Icons.grid_view,
        color: Color(0xFFD2B48C)),
    RoomAsset(
        id: 'wood',
        name: '나무 바닥',
        price: 150,
        icon: Icons.view_quilt,
        imagePath: 'assets/images/WoodFloor.svg'),
    RoomAsset(
        id: 'tile_sky',
        name: '하늘 타일',
        price: 150,
        icon: Icons.apps,
        imagePath: 'assets/images/TileFloorSky.svg'),
    RoomAsset(
        id: 'carpet_pink',
        name: '핑크 카펫',
        price: 200,
        icon: Icons.texture,
        imagePath: 'assets/images/CarpetFloorPink.svg'),
  ];
}

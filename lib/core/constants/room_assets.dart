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
  final double aspectRatio;

  const RoomAsset({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    this.color,
    this.themeType,
    this.imagePath,
    this.sizeMultiplier = 1.0,
    this.aspectRatio = 1.0,
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
        imagePath: 'assets/images/Default_wall.png'),
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
        icon: Icons.brightness_3,
        color: Color(0xFF424242)),
    RoomAsset(
        id: 'flower_sky',
        name: '꽃하늘',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        color: Color(0xFFFFF9C4),
        imagePath: 'assets/images/FlowerSky.png'),
    RoomAsset(
        id: 'pink_lace',
        name: '핑크레이스',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        color: Color(0xFFFFF9C4),
        imagePath: 'assets/images/PinkLace.png'),
    RoomAsset(
        id: 'red_heart',
        name: '빨간하트',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        color: Color(0xFFFFF9C4),
        imagePath: 'assets/images/RedHeart.png'),
    RoomAsset(
        id: 'white_cloud',
        name: '흰구름',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        color: Color(0xFFFFF9C4),
        imagePath: 'assets/images/White_Cloud.png'),
    RoomAsset(
        id: 'colorful_hexagon',
        name: '컬러풀육각형',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        color: Color(0xFFFFF9C4),
        imagePath: 'assets/images/Colorful_hexagon.png'),
  ];

  static const List<RoomAsset> backgrounds = [
    RoomAsset(
        id: 'default', name: '기본(달)', price: 0, icon: Icons.nightlight_round),
    RoomAsset(
        id: 'blue_moon',
        name: '푸른 달',
        price: 300,
        icon: Icons.circle,
        color: Colors.blueAccent,
        imagePath: 'assets/images/BlueMoon.png'),
    RoomAsset(
        id: 'golden_sun',
        name: '황금 태양',
        price: 300,
        icon: Icons.wb_sunny,
        color: Colors.orangeAccent,
        imagePath: 'assets/images/SunShine.png'),
    RoomAsset(
        id: 'starry_night',
        name: '별이 빛나는 밤',
        price: 300,
        icon: Icons.star,
        color: Colors.indigo,
        imagePath: 'assets/images/NightMoon.png'),
  ];

  static const List<RoomAsset> props = [
    RoomAsset(
      id: 'alarm_clock',
      name: '알람시계',
      price: 150,
      icon: Icons.alarm,
      sizeMultiplier: 0.6,
      imagePath: 'assets/items/AlarmClock.png',
    ),
    RoomAsset(
      id: 'wood_desk',
      name: '원목 책상',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/WoodDesk.png',
      sizeMultiplier: 1.2,
      aspectRatio: 1.8,
    ),
    RoomAsset(
      id: 'book_desk',
      name: '독서대',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/Book_Desk.png',
      sizeMultiplier: 1.2,
      aspectRatio: 1.8,
    ),
    RoomAsset(
      id: 'wooden_desk_sprite',
      name: '원목 책상2',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/wooden_desk_sprite.png',
      sizeMultiplier: 1.2,
      aspectRatio: 1.8,
    ),
    RoomAsset(
      id: 'wood_chair',
      name: '원목 의자',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/Wood_Chair.png',
      sizeMultiplier: 1.2,
      aspectRatio: 1.8,
    ),
    RoomAsset(
      id: 'pogeun_sofa',
      name: '포근소파',
      price: 200,
      icon: Icons.chair,
      imagePath: 'assets/items/PogeunSofa.png',
      sizeMultiplier: 1.2,
      aspectRatio: 1.5,
    ),
    RoomAsset(
      id: 'cozy_bean',
      name: '낮잠소파',
      price: 200,
      icon: Icons.chair,
      imagePath: 'assets/items/CozyBean.png',
      sizeMultiplier: 1.0,
      aspectRatio: 1.2,
    ),
    RoomAsset(
      id: 'pot_1',
      name: '식물 화분',
      price: 120,
      icon: Icons.local_florist,
      imagePath: 'assets/items/Pot1.svg',
      sizeMultiplier: 0.8,
    ),
    RoomAsset(
      id: 'white_bear',
      name: '흰 곰 인형',
      price: 180,
      icon: Icons.pets,
      imagePath: 'assets/items/WhiteBear.png',
      sizeMultiplier: 0.8,
    ),
    RoomAsset(
      id: 'pink_chair',
      name: '핑크 의자',
      price: 180,
      icon: Icons.chair,
      imagePath: 'assets/items/PinkChair.png',
      sizeMultiplier: 1.0,
    ),
    RoomAsset(
      id: 'blue_chair',
      name: '파란 의자',
      price: 180,
      icon: Icons.chair,
      imagePath: 'assets/items/BlueChair.png',
      sizeMultiplier: 1.0,
    ),
    RoomAsset(
      id: 'mug_cup',
      name: '머그컵',
      price: 100,
      icon: Icons.local_cafe,
      imagePath: 'assets/items/MugCup.png',
      sizeMultiplier: 0.6,
    ),
    RoomAsset(
      id: 'wood_cup',
      name: '원목 컵',
      price: 100,
      icon: Icons.local_cafe,
      imagePath: 'assets/items/WoodCup.png',
      sizeMultiplier: 0.6,
    ),
    RoomAsset(
      id: 'cloud_watch',
      name: '구름 시계',
      price: 100,
      icon: Icons.access_time,
      imagePath: 'assets/items/CloudDigital.png',
      sizeMultiplier: 1.0,
    ),
    RoomAsset(
      id: 'red_carpet',
      name: '레드 카펫',
      price: 100,
      icon: Icons.access_time,
      imagePath: 'assets/items/RedCarpet.png',
      sizeMultiplier: 1.0,
      aspectRatio: 1.8,
    ),
    RoomAsset(
      id: 'sticky_note',
      name: '메모 노트',
      price: 50,
      icon: Icons.note_alt_outlined,
      imagePath: 'assets/items/StickyNote.png',
      sizeMultiplier: 0.6,
      aspectRatio: 1.0,
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
        imagePath: 'assets/images/Wood_tile1.png'),
    RoomAsset(
        id: 'wood2',
        name: '나무 바닥2',
        price: 150,
        icon: Icons.view_quilt,
        imagePath: 'assets/images/Wood_Tile2.png'),
    RoomAsset(
        id: 'tile_sky',
        name: '하늘 타일',
        price: 150,
        icon: Icons.apps,
        imagePath: 'assets/images/TileFloorSky.svg'),
    RoomAsset(
        id: 'pink_wood',
        name: '핑크 나무 바닥',
        price: 200,
        icon: Icons.texture,
        imagePath: 'assets/images/Pink_Wood.png'),
    RoomAsset(
        id: 'peach_break',
        name: '피치피치',
        price: 200,
        icon: Icons.texture,
        imagePath: 'assets/images/Peach_Break.png'),
    RoomAsset(
        id: 'pink_carpet',
        name: '핑크 카펫',
        price: 200,
        icon: Icons.texture,
        imagePath: 'assets/images/Pink_Carpet.png'),
    RoomAsset(
        id: 'alokdalok',
        name: '알록달록',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        imagePath: 'assets/images/alokdalok.png'),
  ];
}

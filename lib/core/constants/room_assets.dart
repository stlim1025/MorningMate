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
  final bool isWallMounted;
  final bool noShadow;
  final double shadowDyCorrection;

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
    this.isWallMounted = false,
    this.noShadow = false,
    this.shadowDyCorrection = 0.0,
    this.category,
    this.charWidthPct,
    this.charTopPctAwake,
    this.charTopPctSleep,
    this.charBottomPct,
    this.charScaleAwake,
    this.charScaleSleep,
  });

  final String? category;
  final double? charWidthPct;
  final double? charTopPctAwake;
  final double? charTopPctSleep;
  final double? charBottomPct;
  final double? charScaleAwake;
  final double? charScaleSleep;
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
  ];

  static const List<RoomAsset> emoticons = [
    // 기본 이모티콘 (무료)
    RoomAsset(
      id: 'happy',
      name: '행복',
      price: 0,
      icon: Icons.sentiment_satisfied_alt,
      imagePath: 'assets/imoticon/Imoticon_Happy.png',
    ),
    RoomAsset(
      id: 'normal',
      name: '평범',
      price: 0,
      icon: Icons.sentiment_neutral,
      imagePath: 'assets/imoticon/Imoticon_Normal.png',
    ),
    RoomAsset(
      id: 'sad',
      name: '슬픔',
      price: 0,
      icon: Icons.sentiment_dissatisfied,
      imagePath: 'assets/imoticon/Imoticon_Sad.png',
    ),
    RoomAsset(
      id: 'love',
      name: '사랑',
      price: 0,
      icon: Icons.favorite,
      imagePath: 'assets/imoticon/Imoticon_Love.png',
    ),
    // 판매용 이모티콘
    RoomAsset(
      id: 'angry',
      name: '화남',
      price: 100,
      icon: Icons.mood_bad,
      imagePath: 'assets/imoticon/Imoticon_Angry.png',
    ),
    RoomAsset(
      id: 'awkward',
      name: '당황',
      price: 100,
      icon: Icons.sick,
      imagePath: 'assets/imoticon/Imoticon_Awkward.png',
    ),
    RoomAsset(
      id: 'move',
      name: '감동',
      price: 100,
      icon: Icons.emoji_emotions,
      imagePath: 'assets/imoticon/Imoticon_Move.png',
    ),
    RoomAsset(
      id: 'sleep',
      name: '졸림',
      price: 100,
      icon: Icons.bedtime,
      imagePath: 'assets/imoticon/Imoticon_Sleep.png',
    ),
  ];

  static const List<RoomAsset> wallpapers = [
    RoomAsset(
        id: 'default',
        name: '기본',
        price: 0,
        icon: Icons.check_box_outline_blank, // Plain
        imagePath: 'assets/images/wallpapers/Default_wall.png'),
    RoomAsset(
        id: 'stripe',
        name: '스트라이프',
        price: 100,
        icon: Icons.view_week, // Vertical stripes
        color: Color(0xFFB3E5FC),
        imagePath: 'assets/images/wallpapers/SpliteSky.png'),
    RoomAsset(
        id: 'check',
        name: '체크',
        price: 100,
        icon: Icons.grid_4x4, // Checks
        color: Color(0xFFC8E6C9),
        imagePath: 'assets/images/wallpapers/CheckGreen.png'),
    RoomAsset(
        id: 'dot',
        name: '도트',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        color: Color(0xFFFFF9C4),
        imagePath: 'assets/images/wallpapers/DotPink.png'),
    RoomAsset(
        id: 'flower_sky',
        name: '꽃하늘',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        color: Color(0xFFFFF9C4),
        imagePath: 'assets/images/wallpapers/FlowerSky.png'),
    RoomAsset(
        id: 'pink_lace',
        name: '핑크레이스',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        color: Color(0xFFFFF9C4),
        imagePath: 'assets/images/wallpapers/PinkLace.png'),
    RoomAsset(
        id: 'red_heart',
        name: '빨간하트',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        color: Color(0xFFFFF9C4),
        imagePath: 'assets/images/wallpapers/RedHeart.png'),
    RoomAsset(
        id: 'colorful_hexagon',
        name: '컬러풀육각형',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        color: Color(0xFFFFF9C4),
        imagePath: 'assets/images/wallpapers/Colorful_hexagon.png'),
    RoomAsset(
        id: 'Space_Background',
        name: '우주',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        imagePath: 'assets/images/wallpapers/Space_Background.png'),
    RoomAsset(
        id: 'Castle_Stone_Wall',
        name: '중세 성 벽지',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        imagePath: 'assets/images/wallpapers/Castle_Stone_Wall.png'),
    RoomAsset(
        id: 'lego_wallpaper',
        name: '블럭 벽지',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        imagePath: 'assets/images/wallpapers/Lego_WallPaper.png'),
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
        imagePath: 'assets/images/backgrounds/BlueMoon.png'),
    RoomAsset(
        id: 'blue_moon2',
        name: '푸른 달2',
        price: 300,
        icon: Icons.circle,
        color: Colors.blueAccent,
        imagePath: 'assets/images/backgrounds/BlueMoon2.png'),
    RoomAsset(
        id: 'golden_sun',
        name: '황금 태양',
        price: 300,
        icon: Icons.wb_sunny,
        color: Colors.orangeAccent,
        imagePath: 'assets/images/backgrounds/SunShine.png'),
    RoomAsset(
        id: 'starry_night',
        name: '별이 빛나는 밤',
        price: 300,
        icon: Icons.star,
        color: Colors.indigo,
        imagePath: 'assets/images/backgrounds/NightMoon.png'),
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
      sizeMultiplier: 0.9,
      aspectRatio: 1.8,
    ),
    RoomAsset(
      id: 'book_desk',
      name: '독서대',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/Book_Desk.png',
      sizeMultiplier: 1.0,
      aspectRatio: 1.8,
    ),
    RoomAsset(
      id: 'wooden_desk_sprite',
      name: '원목 책상2',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/wooden_desk_sprite.png',
      sizeMultiplier: 1.0,
      aspectRatio: 1.8,
    ),
    RoomAsset(
      id: 'space_desk',
      name: '우주 책상',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/Space_Desk.png',
      sizeMultiplier: 1.2,
      aspectRatio: 1.2,
    ),
    RoomAsset(
      id: 'space_desk2',
      name: '우주 책상2',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/Space_Desk2.png',
      sizeMultiplier: 0.8,
      aspectRatio: 1.2,
    ),
    RoomAsset(
      id: 'space_drawer',
      name: '우주 서랍장',
      price: 200,
      icon: Icons.kitchen,
      imagePath: 'assets/items/Space_drawer.png',
      sizeMultiplier: 1.2,
      aspectRatio: 1.0,
    ),
    RoomAsset(
      id: 'space_drawer2',
      name: '우주 서랍장2',
      price: 200,
      icon: Icons.kitchen,
      imagePath: 'assets/items/Space_drawer2.png',
      sizeMultiplier: 0.7,
      aspectRatio: 1.0,
    ),
    RoomAsset(
      id: 'wood_chair',
      name: '원목 의자',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/Wood_Chair.png',
      sizeMultiplier: 0.9,
      aspectRatio: 1,
    ),
    RoomAsset(
      id: 'wood_bed',
      name: '원목 침대',
      price: 100,
      icon: Icons.note_alt_outlined,
      imagePath: 'assets/items/Wood_Bed.png',
      sizeMultiplier: 1.5,
      aspectRatio: 1.6,
    ),
    RoomAsset(
      id: 'space_chair',
      name: '우주 의자',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/Space_Chair.png',
      sizeMultiplier: 1.2,
      aspectRatio: 1,
    ),
    RoomAsset(
      id: 'space_bed',
      name: '우주 침대',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/Space_bed.png',
      sizeMultiplier: 2.0,
      aspectRatio: 1.0,
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
      imagePath: 'assets/items/Pot.png',
      sizeMultiplier: 0.6,
    ),
    RoomAsset(
      id: 'analog_clock',
      name: '아날로그 시계',
      price: 120,
      icon: Icons.access_time,
      imagePath: 'assets/items/Analog_Clock.png',
      sizeMultiplier: 0.6,
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
      sizeMultiplier: 0.4,
    ),
    RoomAsset(
      id: 'wood_cup',
      name: '원목 컵',
      price: 100,
      icon: Icons.local_cafe,
      imagePath: 'assets/items/WoodCup.png',
      sizeMultiplier: 0.4,
    ),
    RoomAsset(
      id: 'cloud_watch',
      name: '구름 시계',
      price: 100,
      icon: Icons.access_time,
      imagePath: 'assets/items/CloudDigital.png',
      sizeMultiplier: 1.0,
      isWallMounted: true,
    ),
    RoomAsset(
      id: 'red_carpet',
      name: '레드 카펫',
      price: 100,
      icon: Icons.access_time,
      imagePath: 'assets/items/RedCarpet.png',
      sizeMultiplier: 1.6,
      aspectRatio: 1.8,
      noShadow: true,
    ),
    RoomAsset(
      id: 'sticky_note',
      name: '메모 노트',
      price: 50,
      icon: Icons.note_alt_outlined,
      imagePath: 'assets/items/StickyNote.png',
      sizeMultiplier: 0.6,
      aspectRatio: 1.0,
      isWallMounted: true,
    ),
    RoomAsset(
      id: 'lego_book_desk',
      name: '블럭 독서 책상',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/Lego_BookDesk.png',
      sizeMultiplier: 0.8,
      aspectRatio: 2.0,
    ),
    RoomAsset(
      id: 'lego_chair',
      name: '블럭 의자',
      price: 180,
      icon: Icons.chair,
      imagePath: 'assets/items/Lego_Chair.png',
      sizeMultiplier: 0.7,
    ),
    RoomAsset(
      id: 'lego_clock',
      name: '블럭 시계',
      price: 120,
      icon: Icons.access_time,
      imagePath: 'assets/items/Lego_Clock.png',
      sizeMultiplier: 0.6,
    ),
    RoomAsset(
      id: 'lego_cloth_desk',
      name: '블럭 옷장',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/Lego_ClothDesk.png',
      sizeMultiplier: 1.2,
      aspectRatio: 1.0,
    ),
    RoomAsset(
      id: 'lego_desk',
      name: '블럭 책상',
      price: 200,
      icon: Icons.table_restaurant,
      imagePath: 'assets/items/Lego_Desk.png',
      sizeMultiplier: 0.8,
      aspectRatio: 2.2,
    ),
    RoomAsset(
      id: 'lego_door',
      name: '블럭 문',
      price: 200,
      icon: Icons.meeting_room,
      imagePath: 'assets/items/Lego_Door.png',
      sizeMultiplier: 1.3,
      aspectRatio: 0.8,
    ),
    RoomAsset(
      id: 'lego_flower',
      name: '블럭 꽃',
      price: 100,
      icon: Icons.local_florist,
      imagePath: 'assets/items/Lego_Flower.png',
      sizeMultiplier: 0.6,
    ),
    RoomAsset(
      id: 'lego_frame',
      name: '블럭 액자',
      price: 100,
      icon: Icons.image,
      imagePath: 'assets/items/Lego_Frame.png',
      sizeMultiplier: 0.8,
      isWallMounted: true,
      noShadow: true,
    ),
    RoomAsset(
      id: 'lego_frame2',
      name: '블럭 액자2',
      price: 100,
      icon: Icons.image,
      imagePath: 'assets/items/Lego_Frame2.png',
      sizeMultiplier: 0.8,
      isWallMounted: true,
      noShadow: true,
    ),
    RoomAsset(
      id: 'lego_game_machine',
      name: '블럭 게임기',
      price: 250,
      icon: Icons.videogame_asset,
      imagePath: 'assets/items/Lego_GameMachine.png',
      sizeMultiplier: 1.2,
      aspectRatio: 1.0,
    ),
    RoomAsset(
      id: 'lego_lamp',
      name: '블럭 램프',
      price: 120,
      icon: Icons.light,
      imagePath: 'assets/items/Lego_Lamp.png',
      sizeMultiplier: 0.7,
    ),
    RoomAsset(
      id: 'lego_mailbox',
      name: '블럭 우체통',
      price: 150,
      icon: Icons.mail,
      imagePath: 'assets/items/Lego_MailBox.png',
      sizeMultiplier: 0.6,
      aspectRatio: 1.2,
    ),
    RoomAsset(
      id: 'lego_piano',
      name: '블럭 피아노',
      price: 300,
      icon: Icons.piano,
      imagePath: 'assets/items/Lego_Piano.png',
      sizeMultiplier: 0.6,
      aspectRatio: 1.8,
    ),
    RoomAsset(
      id: 'lego_sink',
      name: '블럭 세면대',
      price: 200,
      icon: Icons.wash,
      imagePath: 'assets/items/Lego_Sink.png',
      sizeMultiplier: 1.0,
      aspectRatio: 1.0,
    ),
    RoomAsset(
      id: 'castle_candle',
      name: '성 촛대',
      price: 150,
      icon: Icons.light_mode,
      imagePath: 'assets/items/Castle_Candle.png',
      sizeMultiplier: 0.8,
    ),
    RoomAsset(
      id: 'castle_knight_statue',
      name: '기사 조각상',
      price: 250,
      icon: Icons.account_balance,
      imagePath: 'assets/items/Castle_KnightStatue.png',
      sizeMultiplier: 1.6,
      aspectRatio: 0.8,
    ),
    RoomAsset(
      id: 'castle_treasure_chest',
      name: '보물 상자',
      price: 200,
      icon: Icons.inventory_2,
      imagePath: 'assets/items/Castle_TreasureChest.png',
      sizeMultiplier: 1.4,
    ),
    RoomAsset(
      id: 'castle_gargoyle_statue',
      name: '가고일 석상',
      price: 250,
      icon: Icons.pets,
      imagePath: 'assets/items/Caslte_GargoyleStatue.png',
      sizeMultiplier: 1.4,
      aspectRatio: 0.8,
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
        imagePath: 'assets/images/floors/Wood_tile1.png'),
    RoomAsset(
        id: 'wood2',
        name: '나무 바닥2',
        price: 150,
        icon: Icons.view_quilt,
        imagePath: 'assets/images/floors/Wood_Tile2.png'),
    RoomAsset(
        id: 'pink_wood',
        name: '핑크 나무 바닥',
        price: 200,
        icon: Icons.texture,
        imagePath: 'assets/images/floors/Pink_Wood.png'),
    RoomAsset(
        id: 'peach_break',
        name: '피치피치',
        price: 200,
        icon: Icons.texture,
        imagePath: 'assets/images/floors/Peach_Break.png'),
    RoomAsset(
        id: 'pink_carpet',
        name: '핑크 카펫',
        price: 200,
        icon: Icons.texture,
        imagePath: 'assets/images/floors/Pink_Carpet.png'),
    RoomAsset(
        id: 'alokdalok',
        name: '알록달록',
        price: 100,
        icon: Icons.scatter_plot, // Dots
        imagePath: 'assets/images/floors/alokdalok.png'),
    RoomAsset(
        id: 'castle_stone',
        name: '중세 성 바닥',
        price: 300,
        icon: Icons.star,
        imagePath: 'assets/images/floors/Castle_Stone_Floor.png'),
    RoomAsset(
        id: 'space_floor',
        name: '우주 바닥',
        price: 300,
        icon: Icons.star,
        imagePath: 'assets/images/floors/Space_Floor.png'),
    RoomAsset(
        id: 'lego_floor',
        name: '블럭 바닥',
        price: 300,
        icon: Icons.star,
        imagePath: 'assets/images/floors/lego_Floor.png'),
  ];
}

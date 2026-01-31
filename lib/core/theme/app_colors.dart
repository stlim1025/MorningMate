import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - 따뜻한 다이어리 테마
  static const Color primary = Color(0xFFD4A574); // 골드/카라멜
  static const Color secondary = Color(0xFFFFB6C1); // 파스텔 핑크
  static const Color accent = Color(0xFF95E1D3); // 민트

  // Sky Theme Colors - 맑은 하늘 톤
  static const Color skyPrimary = Color(0xFF5AA9E6); // 청량한 하늘색
  static const Color skySecondary = Color(0xFFBEE3F8); // 파스텔 블루
  static const Color skyBackground = Color(0xFFEFF7FF); // 연한 하늘 배경
  static const Color skyCard = Color(0xFFFFFFFF); // 밝은 카드
  static const Color skyTextPrimary = Color(0xFF2B4C7E); // 딥 블루
  static const Color skyTextSecondary = Color(0xFF4A6FA5); // 미디엄 블루

  // Purple Theme Colors
  static const Color purplePrimary = Color(0xFF9B6BFF); // 선명한 보라
  static const Color purpleSecondary = Color(0xFFEBE2FF); // 연한 보라
  static const Color purpleBackground = Color(0xFFF8F5FF); // 보라 배경
  static const Color purpleTextPrimary = Color(0xFF4A3A75); // 딥 퍼플

  // Pink Theme Colors
  static const Color pinkPrimary = Color(0xFFFF7EB3); // 화사한 핑크
  static const Color pinkSecondary = Color(0xFFFFE3EE); // 연한 핑크
  static const Color pinkBackground = Color(0xFFFFF5F8); // 핑크 배경
  static const Color pinkTextPrimary = Color(0xFF7D3C58); // 딥 핑크

  // Background Colors - 밝고 따뜻한 베이지 톤
  // Background Colors - 밝고 따뜻한 베이지 톤
  static const Color backgroundLight = Color(0xFFFAF3E0); // 따뜻한 베이지
  static const Color backgroundDark = Color(0xFF121212); // 리얼 다크

  static const Color cardLight = Color(0xFFFFFFFF); // 흰색 카드
  static const Color cardDark = Color(0xFF1E1E1E); // 다크 모드 카드

  // Character States
  static const Color sleepMode = Color(0xFFB8A89E); // 부드러운 회갈색
  static const Color awakeMode = Color(0xFFFFD93D); // 밝은 노랑

  // Functional Colors - 파스텔 톤
  static const Color success = Color(0xFF95E1D3); // 민트
  static const Color error = Color(0xFFFFB6B9); // 연한 핑크
  static const Color warning = Color(0xFFFFE66D); // 따뜻한 노랑
  static const Color info = Color(0xFFAEC6CF); // 파스텔 블루

  // Text Colors
  static const Color textPrimary = Color(0xFF5D4E37); // 다크 브라운
  static const Color textSecondary = Color(0xFF8B7355); // 밝은 브라운
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textHint = Color(0xFFD4C4B0); // 연한 브라운

  // Streak & Gamification
  static const Color streakGold = Color(0xFFFFD700);
  static const Color pointStar = Color(0xFFFFE66D);

  // Social Colors
  static const Color friendActive = Color(0xFF95E1D3); // 민트
  static const Color friendSleep = Color(0xFFD4C4B0); // 베이지 그레이

  // Gradients - 따뜻한 그라데이션
  static const LinearGradient morningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF8E7), // 밝은 크림
      Color(0xFFFFE4E1), // 미스티 로즈
    ],
  );

  static const LinearGradient eveningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF0E6), // 라이트 피치
      Color(0xFFFFE4E1), // 미스티 로즈
    ],
  );

  // 카드 그림자
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFFD4A574).withOpacity(0.15),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  // 작은 카드 그림자
  static List<BoxShadow> smallCardShadow = [
    BoxShadow(
      color: const Color(0xFFD4A574).withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}

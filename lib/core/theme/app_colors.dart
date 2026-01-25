import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - 따뜻한 아침 분위기
  static const Color primary = Color(0xFF6B9AC4); // 차분한 블루
  static const Color secondary = Color(0xFFF4C2A2); // 따뜻한 파스텔 오렌지
  static const Color accent = Color(0xFFA8D5BA); // 힐링 그린
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF1A1D2E);
  static const Color cardDark = Color(0xFF22283A);
  
  // Character States
  static const Color sleepMode = Color(0xFF7B8AA2); // 수면 상태
  static const Color awakeMode = Color(0xFFF9D77E); // 기상 상태
  
  // Functional Colors
  static const Color success = Color(0xFF66BB6A);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Streak & Gamification
  static const Color streakGold = Color(0xFFFFD700);
  static const Color pointStar = Color(0xFFFFEB3B);
  
  // Social Colors
  static const Color friendActive = Color(0xFF81C784);
  static const Color friendSleep = Color(0xFFB0BEC5);
  
  // Gradients
  static const LinearGradient morningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6B9AC4),
      Color(0xFFA8D5BA),
    ],
  );
  
  static const LinearGradient eveningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2C3E50),
      Color(0xFF3E5266),
    ],
  );
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CharacterRoomWidget extends StatelessWidget {
  final bool isAwake;
  final String characterState;

  const CharacterRoomWidget({
    super.key,
    required this.isAwake,
    this.characterState = 'egg',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 방 상단 (창문)
          _buildWindow(),

          const SizedBox(height: 24),

          // 캐릭터 영역 (가운데)
          _buildCharacterArea(),

          const SizedBox(height: 24),

          // 방 하단 (가구)
          _buildFurniture(),
        ],
      ),
    );
  }

  Widget _buildWindow() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isAwake
            ? const Color(0xFF87CEEB).withOpacity(0.4)
            : const Color(0xFF1a1a2e).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 3,
        ),
      ),
      child: Stack(
        children: [
          // 창틀
          Center(
            child: Container(
              width: 3,
              height: 100,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          Center(
            child: Container(
              width: double.infinity,
              height: 3,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          // 하늘/밤 풍경
          if (!isAwake) ...[
            Positioned(
              top: 20,
              right: 30,
              child: Icon(
                Icons.star,
                color: Colors.yellow.withOpacity(0.8),
                size: 20,
              ),
            ),
            Positioned(
              top: 35,
              right: 50,
              child: Icon(
                Icons.star,
                color: Colors.yellow.withOpacity(0.6),
                size: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCharacterArea() {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 캐릭터 그림자
          Positioned(
            bottom: 0,
            child: Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),

          // 캐릭터 메인
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            bottom: isAwake ? 80 : 40,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: isAwake ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color:
                          isAwake ? AppColors.awakeMode : AppColors.sleepMode,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isAwake
                                  ? AppColors.awakeMode
                                  : AppColors.sleepMode)
                              .withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      isAwake ? Icons.wb_sunny : Icons.bedtime,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),

          // 깨어났을 때 반짝임 이펙트
          if (isAwake)
            Positioned(
              top: 20,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: 1.0 - value,
                    child: Transform.scale(
                      scale: 1.0 + value,
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppColors.pointStar,
                        size: 40 + (value * 20),
                      ),
                    ),
                  );
                },
              ),
            ),

          // 잠잘 때 Z 표시
          if (!isAwake)
            Positioned(
              top: 30,
              right: 80,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: (value * 2) % 1.0,
                    child: const Text(
                      'Z',
                      style: TextStyle(
                        fontSize: 40,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFurniture() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 책상
        _buildDesk(),
        // 화분
        _buildPlant(),
      ],
    );
  }

  Widget _buildDesk() {
    return Container(
      width: 70,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF8B7355).withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // 책상 다리
          Positioned(
            left: 8,
            bottom: 0,
            child: Container(
              width: 5,
              height: 40,
              color: const Color(0xFF654321),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 0,
            child: Container(
              width: 5,
              height: 40,
              color: const Color(0xFF654321),
            ),
          ),
          // 램프
          Positioned(
            top: -12,
            right: 15,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isAwake
                    ? Colors.yellow.withOpacity(0.8)
                    : Colors.grey.withOpacity(0.4),
                shape: BoxShape.circle,
                boxShadow: isAwake
                    ? [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ]
                    : [],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlant() {
    return SizedBox(
      width: 40,
      height: 50,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 화분
          Container(
            width: 40,
            height: 25,
            decoration: BoxDecoration(
              color: const Color(0xFFD2691E).withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(6),
              ),
            ),
          ),
          // 식물
          Positioned(
            bottom: 20,
            child: Icon(
              Icons.spa,
              color: AppColors.accent.withOpacity(0.8),
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

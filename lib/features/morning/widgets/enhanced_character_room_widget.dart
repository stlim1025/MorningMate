import 'package:flutter/material.dart';

class EnhancedCharacterRoomWidget extends StatefulWidget {
  final bool isAwake;
  final int characterLevel;
  final int consecutiveDays; // 연속 일기 작성 횟수 등 표시용?
  // MorningScreen에서는 AnimationController를 공유했지만, 여기서는 내부에서 관리하거나 외부에서 받을 수 있음.
  // MorningScreen의 동작을 그대로 가져오기 위해 내부에서 애니메이션 관리하도록 함.

  const EnhancedCharacterRoomWidget({
    super.key,
    required this.isAwake,
    this.characterLevel = 1,
    this.consecutiveDays = 0,
  });

  @override
  State<EnhancedCharacterRoomWidget> createState() =>
      _EnhancedCharacterRoomWidgetState();
}

class _EnhancedCharacterRoomWidgetState
    extends State<EnhancedCharacterRoomWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 방 내부 (태양/달 제거됨 - 상위 스크린에서 처리)
        _buildRoomInterior(widget.isAwake),
      ],
    );
  }

  Widget _buildRoomInterior(bool isAwake) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // 낮/밤에 따라 방 배경색을 극명하게 변경
        color: isAwake
            ? const Color(0xFFFDF5E6) // 밝은 베이지
            : const Color(0xFF2C3E50).withOpacity(0.8), // 어두운 남색
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isAwake ? Colors.white : Colors.white10,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 벽 장식 (액자들)
          _buildWallDecoration(isAwake),

          const SizedBox(height: 20),

          // 침대와 캐릭터
          _buildBedAndCharacter(isAwake),

          const SizedBox(height: 20),

          // 바닥 장식 (화분들)
          _buildFloorDecoration(),
        ],
      ),
    );
  }

  Widget _buildWallDecoration(bool isAwake) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFrame(Icons.local_florist,
            isAwake ? const Color(0xFFDEB887) : Colors.brown.shade800),
        const SizedBox(width: 40),
        _buildFrame(Icons.spa,
            isAwake ? const Color(0xFF90EE90) : Colors.green.shade900),
      ],
    );
  }

  Widget _buildFrame(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        border: Border.all(color: const Color(0xFF8B7355), width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }

  Widget _buildBedAndCharacter(bool isAwake) {
    return SizedBox(
      height: 200, // 캐릭터 이동 공간 확보
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 침대 (잠잘 때는 중앙, 깨어나면 뒤쪽으로 배치된 효과)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            top: isAwake ? 0 : 20,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color:
                    isAwake ? const Color(0xFF8B7355) : const Color(0xFF5D4037),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: isAwake
                          ? const Color(0xFFA0826D)
                          : const Color(0xFF4E342E),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isAwake
                                ? const Color(0xFFFFB6C1)
                                : const Color(0xFF9575CD))
                            .withOpacity(0.7),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 캐릭터
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            // 잠잘 때는 침대 위(top: 40), 깨어나면 바닥 중앙(top: 100)
            top: isAwake ? 80 : 30,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, isAwake ? -_bounceAnimation.value : 0),
                    child: _buildCharacter(isAwake),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacter(bool isAwake) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF0F5).withOpacity(0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 캐릭터 몸
          Container(
            width: 90,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF87CEEB), // 하늘색
              borderRadius: BorderRadius.all(Radius.circular(45)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 얼굴 부분 (크림색)
                Container(
                  width: 70,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8DC),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: Stack(
                    children: [
                      // 눈
                      Positioned(
                        top: 25,
                        left: 20,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 25,
                        right: 20,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // 부리
                      Positioned(
                        top: 32,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF8C00),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 볼터치
                      Positioned(
                        top: 40,
                        right: 12,
                        child: Container(
                          width: 15,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB6C1).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 날개
          Positioned(
            right: 5,
            top: 25,
            child: Container(
              width: 20,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF87CEEB),
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
            ),
          ),

          // Z 표시 (잠잘 때)
          if (!isAwake)
            Positioned(
              top: -20,
              right: 0,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // 첫 번째 Z
                      Transform.translate(
                        offset: Offset(
                          10 * (1 - _animationController.value),
                          -20 * _animationController.value,
                        ),
                        child: Opacity(
                          opacity:
                              (1 - _animationController.value).clamp(0.0, 1.0),
                          child: const Text(
                            'Z',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // 두 번째 Z (약간의 시차)
                      Transform.translate(
                        offset: Offset(
                          20 * (1 - ((_animationController.value + 0.5) % 1.0)),
                          -30 * ((_animationController.value + 0.5) % 1.0),
                        ),
                        child: Opacity(
                          opacity:
                              (1 - ((_animationController.value + 0.5) % 1.0))
                                  .clamp(0.0, 1.0),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 15, top: 10),
                            child: Text(
                              'z',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white60,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloorDecoration() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPlant(const Color(0xFF90EE90)),
        const SizedBox(width: 20),
        _buildPlant(const Color(0xFF98FB98)),
      ],
    );
  }

  Widget _buildPlant(Color color) {
    return Container(
      width: 50,
      height: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 잎
          Icon(Icons.spa, color: color, size: 35),
          // 화분
          Container(
            width: 50,
            height: 25,
            decoration: BoxDecoration(
              color: const Color(0xFFD2691E).withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// 마이룸과 친구 상세 페이지에서 사용하는 공통 액션 버튼
///
/// Button_Background.png를 배경으로 사용하고,
/// 그 안에 아이콘과 텍스트를 표시합니다.
class RoomActionButton extends StatefulWidget {
  /// 버튼 아이콘 이미지 경로 (예: 'assets/icons/Store_Icon.png')
  final String iconPath;

  /// 버튼 텍스트 (예: '상점', '꾸미기', '보낸기록')
  final String label;

  /// 버튼 클릭 시 실행될 콜백
  final VoidCallback onTap;

  /// 버튼 크기 (기본값: 56)
  final double size;

  /// 버튼 배경 이미지 경로 (기본값: 'assets/icons/Button_Background.png')
  final String? backgroundImagePath;

  /// 아이콘 크기 (기본값: size * 0.6)
  final double? iconSize;

  const RoomActionButton({
    super.key,
    required this.iconPath,
    required this.label,
    required this.onTap,
    this.size = 56,
    this.backgroundImagePath,
    this.iconSize,
  });

  @override
  State<RoomActionButton> createState() => _RoomActionButtonState();
}

class _RoomActionButtonState extends State<RoomActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 배경 이미지
              Positioned.fill(
                child: Image.asset(
                  widget.backgroundImagePath ??
                      'assets/icons/Button_Background.png',
                  fit: BoxFit.fill,
                  cacheWidth: 200, // Optimize memory
                ),
              ),
              // 아이콘과 텍스트 - Flexible로 감싸서 오버플로우 방지
              Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 아이콘 이미지 - Flexible로 감싸서 자동 조정
                    Flexible(
                      flex: 2,
                      child: Image.asset(
                        widget.iconPath,
                        width: widget.iconSize ?? widget.size * 0.6,
                        height: widget.iconSize ?? widget.size * 0.6,
                        fit: BoxFit.contain,
                        cacheWidth: 150, // Optimize memory
                      ),
                    ),
                    const SizedBox(height: 2),
                    // 버튼 텍스트 - Flexible로 감싸서 잘리지 않도록
                    Flexible(
                      flex: 1,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth:
                                60, // 'Decorate' 단어가 잘리지 않도록 폭을 약간 넓힘 (60 정도면 Decorate가 한 줄에 들어감)
                          ),
                          child: Text(
                            widget.label,
                            style: const TextStyle(
                              fontFamily: 'BMJUA',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4E342E), // Dark Brown
                              height: 1.0,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

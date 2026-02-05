import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // Fixed height for transparency and background
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Down_Tab2.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _TabItem(
              iconPath: 'assets/icons/Home_Icon.png',
              label: '홈',
              width: 32,
              height: 32,
              isSelected: currentIndex == 0,
              onTap: () => _handleNavigation(context, 0),
            ),
            _TabItem(
              iconPath: 'assets/icons/Charactor_Icon.png',
              label: '캐릭터',
              width: 45,
              height: 32,
              isSelected: currentIndex == 1,
              onTap: () => _handleNavigation(context, 1),
            ),
            _TabItem(
              iconPath: 'assets/icons/Friend_Icon.png',
              label: '친구',
              width: 45,
              height: 32,
              isSelected: currentIndex == 2,
              onTap: () => _handleNavigation(context, 2),
            ),
            _TabItem(
              iconPath: 'assets/icons/Calander_Icon.png',
              label: '기록',
              width: 40,
              height: 32,
              isSelected: currentIndex == 3,
              onTap: () => _handleNavigation(context, 3),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (currentIndex == index) return;
    switch (index) {
      case 0:
        context.go('/morning');
        break;
      case 1:
        context.go('/character');
        break;
      case 2:
        context.go('/social');
        break;
      case 3:
        context.go('/archive');
        break;
    }
  }
}

class _TabItem extends StatefulWidget {
  final String iconPath;
  final String label;
  final double width;
  final double height;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.iconPath,
    required this.label,
    required this.width,
    required this.height,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(top: 8, left: 10, right: 10, bottom: 2),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                widget.iconPath,
                width: widget.width,
                height: widget.height,
                opacity: widget.isSelected
                    ? const AlwaysStoppedAnimation(1.0)
                    : const AlwaysStoppedAnimation(0.5), // Dim unselected
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: widget.isSelected
                      ? const Color(0xFF4E342E) // Dark Brown
                      : const Color(0xFF4E342E).withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

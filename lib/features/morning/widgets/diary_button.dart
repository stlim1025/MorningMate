import 'package:flutter/material.dart';

class DiaryButton extends StatefulWidget {
  final VoidCallback onTap;
  const DiaryButton({super.key, required this.onTap});

  @override
  State<DiaryButton> createState() => _DiaryButtonState();
}

class _DiaryButtonState extends State<DiaryButton>
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/Button_Background2.png',
              width: double.infinity,
              height: 90,
              fit: BoxFit.fill,
              cacheHeight: 200, // Optimize memory for fixed height
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '일기 작성하기',
                style: TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4E342E), // Dark Brown
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AnimatedDiaryButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const AnimatedDiaryButton({
    super.key,
    required this.onTap,
    required this.label,
  });

  @override
  State<AnimatedDiaryButton> createState() => _AnimatedDiaryButtonState();
}

class _AnimatedDiaryButtonState extends State<AnimatedDiaryButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/Button_Background2.png',
                width: double.infinity,
                height: 52,
                fit: BoxFit.fill,
              ),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  color: Color(0xFF4E342E),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

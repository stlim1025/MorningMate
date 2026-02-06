import 'package:flutter/material.dart';

class HeaderImageButton extends StatefulWidget {
  final String imagePath;
  final VoidCallback onTap;
  final double size;

  const HeaderImageButton({
    super.key,
    required this.imagePath,
    required this.onTap,
    this.size = 44.0,
  });

  @override
  State<HeaderImageButton> createState() => _HeaderImageButtonState();
}

class _HeaderImageButtonState extends State<HeaderImageButton>
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
        child: Image.asset(
          widget.imagePath,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          cacheWidth: 150, // Optimize memory usage
        ),
      ),
    );
  }
}

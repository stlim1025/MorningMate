import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DecorationButton extends StatefulWidget {
  const DecorationButton({super.key});

  @override
  State<DecorationButton> createState() => _DecorationButtonState();
}

class _DecorationButtonState extends State<DecorationButton>
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
        context.push('/character/decoration');
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Image.asset(
          'assets/icons/Ggumim_Icon.png',
          width: 53,
          height: 56,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

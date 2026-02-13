import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CharacterDecorationButton extends StatefulWidget {
  const CharacterDecorationButton({super.key});

  @override
  State<CharacterDecorationButton> createState() =>
      _CharacterDecorationButtonState();
}

class _CharacterDecorationButtonState extends State<CharacterDecorationButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        context.push('/character-decoration');
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                // shape: BoxShape.circle, // Optional: if circular
                // borderRadius: BorderRadius.circular(40), // Optional
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/Nofriend_Charactor.png',
                fit: BoxFit.contain,
                cacheWidth: 200,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: const Text(
                '꾸미기',
                style: TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 12,
                  color: Color(0xFF5D4E37),
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

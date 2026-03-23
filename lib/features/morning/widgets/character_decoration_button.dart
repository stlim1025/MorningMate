import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';

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
        duration: Duration(milliseconds: 100),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  // shape: BoxShape.circle, // Optional: if circular
                  // borderRadius: BorderRadius.circular(40), // Optional
                  ),
              child: Image.asset(
                'assets/images/Nofriend_Charactor.png',
                fit: BoxFit.contain,
                cacheWidth: 200,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom:
                    AppLocalizations.of(context)?.locale.languageCode == 'en'
                        ? 18
                        : 17, // 한국어일 때 글자를 조금 더 위로 (기존 12)
              ),
              child: SizedBox(
                width: 76,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppLocalizations.of(context)?.get('decorateCharacter') ??
                        'Decorate Character',
                    style: TextStyle(
                      fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
                      fontSize: AppLocalizations.of(context)?.locale.languageCode == 'ja' ? 10 : 12, // 일본어일 때 폰트 크기 축소
                      color: Color(0xFF5D4E37),
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.white,
                          blurRadius: 4,
                        ),
                      ],
                      height: 1.0,
                    ),
                    maxLines: 1, // 가로 폭을 위해 한 줄로 제한
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

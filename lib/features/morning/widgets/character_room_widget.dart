import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';

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
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.backgroundLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: colorScheme.textHint.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWindow(isAwake, colorScheme),
          const SizedBox(height: 24),
          _buildCharacterArea(isAwake, colorScheme),
          const SizedBox(height: 24),
          _buildFurniture(isAwake, colorScheme),
        ],
      ),
    );
  }

  Widget _buildWindow(bool isAwake, AppColorScheme colorScheme) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isAwake
            ? colorScheme.success.withOpacity(0.2)
            : colorScheme.backgroundDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.textHint.withOpacity(0.3),
          width: 3,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 3,
              height: 100,
              color: colorScheme.textHint.withOpacity(0.2),
            ),
          ),
          Center(
            child: Container(
              width: double.infinity,
              height: 3,
              color: colorScheme.textHint.withOpacity(0.2),
            ),
          ),
          if (!isAwake) ...[
            Positioned(
              top: 20,
              right: 30,
              child: Icon(
                Icons.star,
                color: colorScheme.pointStar.withOpacity(0.8),
                size: 20,
              ),
            ),
            Positioned(
              top: 35,
              right: 50,
              child: Icon(
                Icons.star,
                color: colorScheme.pointStar.withOpacity(0.6),
                size: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCharacterArea(bool isAwake, AppColorScheme colorScheme) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.shadowColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),
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
                      color: isAwake
                          ? colorScheme.pointStar
                          : colorScheme.textHint,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isAwake
                                  ? colorScheme.pointStar
                                  : colorScheme.textHint)
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
        ],
      ),
    );
  }

  Widget _buildFurniture(bool isAwake, AppColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildDesk(isAwake, colorScheme),
        _buildPlant(colorScheme),
      ],
    );
  }

  Widget _buildDesk(bool isAwake, AppColorScheme colorScheme) {
    return SizedBox(
      width: 70,
      height: 50,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            bottom: 0,
            child: Container(width: 5, height: 40, color: Colors.brown),
          ),
          Positioned(
            right: 8,
            bottom: 0,
            child: Container(width: 5, height: 40, color: Colors.brown),
          ),
          Positioned(
            top: 20,
            child: Container(
              width: 70,
              height: 10,
              color: Colors.brown.withOpacity(0.8),
            ),
          ),
          Positioned(
            top: 0,
            right: 15,
            child: Icon(
              Icons.lightbulb,
              size: 20,
              color: isAwake ? colorScheme.pointStar : colorScheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlant(AppColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.spa, color: colorScheme.accent, size: 30),
        Container(
          width: 40,
          height: 15,
          color: Colors.brown.withOpacity(0.7),
        ),
      ],
    );
  }
}

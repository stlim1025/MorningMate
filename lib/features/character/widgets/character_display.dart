import 'package:flutter/material.dart';

class CharacterDisplay extends StatefulWidget {
  final bool isAwake;
  final int characterLevel;
  final double size;
  final bool isTapped;
  final bool enableAnimation;
  final Map<String, dynamic>? equippedItems;

  const CharacterDisplay({
    super.key,
    required this.isAwake,
    required this.characterLevel,
    required this.size,
    this.isTapped = false,
    this.enableAnimation = true,
    this.equippedItems,
  });

  @override
  State<CharacterDisplay> createState() => _CharacterDisplayState();
}

class _CharacterDisplayState extends State<CharacterDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.enableAnimation) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(CharacterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableAnimation != oldWidget.enableAnimation) {
      if (widget.enableAnimation) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Shared dimensions for the character components
    final double charWidth = widget.size;
    final double charHeight = widget.size;

    return Transform.scale(
      scale: widget.isAwake ? 1.0 : 0.8,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Wings (Level 2+) - Static layer
            if (widget.characterLevel >= 2)
              Image.asset(
                widget.characterLevel >= 3
                    ? 'assets/images/Egg_Wing2.png'
                    : 'assets/images/Egg_Wing.png',
                width: widget.characterLevel >= 3
                    ? (widget.isAwake ? charWidth * 2 : charWidth * 2.4)
                    : (widget.isAwake ? charWidth * 1.2 : charWidth * 1.44),
                height: widget.characterLevel >= 3
                    ? (widget.isAwake ? charHeight * 2 : charHeight * 2.4)
                    : (widget.isAwake ? charHeight : charHeight * 1.2),
                fit: BoxFit.contain,
                cacheWidth: 400,
              ),

            // 2. Base Body - Static layer
            Image.asset(
              widget.isAwake
                  ? 'assets/images/Body.png'
                  : 'assets/images/Sleep_Body.png',
              width: charWidth,
              height: charHeight,
              fit: BoxFit.contain,
              cacheWidth: 500,
            ),

            // 2.5 Clothes Slot (Space Clothes, Frog Clothes, etc.)
            if (widget.equippedItems != null &&
                widget.equippedItems!['clothes'] != null)
              Builder(builder: (context) {
                final clothesItem = widget.equippedItems!['clothes'];
                String? assetPath;

                if (clothesItem == 'space_clothes' ||
                    clothesItem == 'prog_clothes') {
                  assetPath = clothesItem == 'space_clothes'
                      ? 'assets/items/Charactor/Charactor_SpaceClothes.png'
                      : 'assets/items/Charactor/Charactor_Progclothes.png';
                  return Image.asset(
                    assetPath,
                    width: charWidth * 1.05,
                    height: charHeight * 1.05,
                    fit: BoxFit.contain,
                    cacheWidth: 500,
                  );
                }

                return const SizedBox.shrink();
              }),

            // 3. Expression Layer - Position face
            Positioned(
              top: widget.isAwake ? charHeight * 0.18 : charHeight * 0.13,
              left: charWidth * 0.075,
              child: SizedBox(
                width: charWidth * 0.85,
                height: charHeight * 0.85,
                child: widget.enableAnimation
                    ? AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.center,
                        crossFadeState: widget.isTapped
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: Image.asset(
                          widget.isAwake
                              ? 'assets/images/Face_Default.png'
                              : 'assets/images/Face_Sleep.png',
                          fit: BoxFit.contain,
                          key: const ValueKey('face_normal'),
                          cacheWidth: 300,
                        ),
                        secondChild: Padding(
                          padding: EdgeInsets.only(
                            top: widget.isAwake ? 10 : 0,
                          ),
                          child: Image.asset(
                            widget.isAwake
                                ? 'assets/images/Face_Wink.png'
                                : 'assets/images/Face_Drool.png',
                            fit: BoxFit.contain,
                            key: const ValueKey('face_tapped'),
                            cacheWidth: 300,
                          ),
                        ),
                      )
                    : Image.asset(
                        widget.isAwake
                            ? 'assets/images/Face_Default.png'
                            : 'assets/images/Face_Sleep.png',
                        fit: BoxFit.contain,
                        cacheWidth: 300,
                      ),
              ),
            ),

            // 4. Accessories Layer (Necktie, Glasses, etc.)
            // Body Slot (Necktie)
            if (widget.equippedItems != null &&
                widget.equippedItems!['body'] == 'necktie')
              Positioned(
                bottom: charHeight * 0.08,
                child: Image.asset(
                  'assets/items/Charactor/Charactor_Necktie.png',
                  width: charWidth * 0.15,
                  fit: BoxFit.contain,
                ),
              ),

            // Expression Layer is already at index 3 (lines 103-151)

            // Face Slot (Glasses)
            if (widget.equippedItems != null &&
                widget.equippedItems!['face'] != null)
              Builder(builder: (context) {
                final faceItem = widget.equippedItems!['face'];
                String? assetPath;
                double itemWidth = charWidth * 0.7;

                if (faceItem == 'heart_glass') {
                  assetPath =
                      'assets/items/Charactor/Charactor_Heart_Glass.png';
                } else if (faceItem == 'wood_glass') {
                  assetPath = 'assets/items/Charactor/Charactor_WoodGlass.png';
                }

                if (assetPath == null) return const SizedBox.shrink();

                return Positioned(
                  top: widget.isAwake ? charHeight * 0.35 : charHeight * 0.17,
                  child: Image.asset(
                    assetPath,
                    width: itemWidth,
                    fit: BoxFit.contain,
                  ),
                );
              }),

            // Head Slot (Sprout, Plogeyes)
            if (widget.equippedItems != null &&
                widget.equippedItems!['head'] != null)
              Builder(builder: (context) {
                final headItem = widget.equippedItems!['head'];
                String? assetPath;
                double itemWidth = charWidth * 0.3;
                double topOffset =
                    widget.isAwake ? -charHeight * 0.02 : -charHeight * 0.05;

                if (headItem == 'sprout') {
                  assetPath = 'assets/items/Charactor/Charactor_Sprout.png';
                } else if (headItem == 'plogeyes') {
                  assetPath = 'assets/items/Charactor/Charactor_Plogeyes.png';
                  itemWidth = charWidth * 0.75;
                  // Position it exactly on top of the head
                  topOffset =
                      widget.isAwake ? -charHeight * 0.12 : -charHeight * 0.15;
                }

                if (assetPath == null) return const SizedBox.shrink();

                return Positioned(
                  top: topOffset,
                  child: Image.asset(
                    assetPath,
                    width: itemWidth,
                    fit: BoxFit.contain,
                  ),
                );
              }),

            // Zzz animation (if sleeping and animation enabled)
            if (!widget.isAwake && widget.enableAnimation)
              Positioned(
                top: -widget.size * 0.05,
                right: widget.size * 0.05,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
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
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

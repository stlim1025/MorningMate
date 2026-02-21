import 'package:flutter/material.dart';

import '../../../core/constants/character_assets.dart';

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
              Builder(builder: (context) {
                // 4레벨(Egg_Wing3)과 5레벨(Egg_Wing4)일 때만 날개를 더 크게 유지(1.3배), 나머지는 원래 크기인 1.1배
                final double wingScale = widget.characterLevel >= 4 ? 1.3 : 1.1;

                return Transform.scale(
                  scale: wingScale,
                  child: Image.asset(
                    widget.characterLevel >= 5
                        ? 'assets/images/Egg_Wing4.png'
                        : widget.characterLevel >= 4
                            ? 'assets/images/Egg_Wing3.png'
                            : widget.characterLevel >= 3
                                ? 'assets/images/Egg_Wing2.png'
                                : 'assets/images/Egg_Wing.png',
                    width: charWidth,
                    height: charHeight,
                    fit: BoxFit.contain,
                    cacheWidth: 400,
                    filterQuality: FilterQuality.medium,
                  ),
                );
              }),

            // 2. Base Body - Static layer
            Image.asset(
              widget.isAwake
                  ? 'assets/images/Body.png'
                  : 'assets/images/Sleep_Body.png',
              width: charWidth,
              height: charHeight,
              fit: BoxFit.contain,
              cacheWidth: 500,
              filterQuality: FilterQuality.medium,
            ),

            // 3. Expression Layer - Position face

            // 4. Clothes Slot
            if (widget.equippedItems != null &&
                widget.equippedItems!['clothes'] != null)
              Builder(builder: (context) {
                final clothesId = widget.equippedItems!['clothes'];
                try {
                  final asset = CharacterAssets.items
                      .firstWhere((e) => e.id == clothesId);

                  if (asset.imagePath == null) return const SizedBox.shrink();

                  // Apply scale based on awake status
                  final double clothesScale = widget.isAwake
                      ? (asset.charScaleAwake ?? 1.0)
                      : (asset.charScaleSleep ?? 1.0);

                  return Transform.scale(
                    scale: clothesScale,
                    child: Image.asset(
                      asset.imagePath!,
                      width: charWidth,
                      height: charHeight,
                      fit: BoxFit.contain,
                      cacheWidth: 500,
                      filterQuality: FilterQuality.medium,
                    ),
                  );
                } catch (e) {
                  return const SizedBox.shrink();
                }
              }),

            // 4. Accessories Layer (Necktie, Glasses, etc.)
            // Body Slot (Necktie)
            if (widget.equippedItems != null &&
                widget.equippedItems!['body'] != null)
              Builder(builder: (context) {
                final bodyId = widget.equippedItems!['body'];
                try {
                  final asset =
                      CharacterAssets.items.firstWhere((e) => e.id == bodyId);

                  if (asset.imagePath == null) return const SizedBox.shrink();

                  // Remove hardcoding: Use asset properties
                  final double bottomPct = asset.charBottomPct ?? 0.08;
                  final double widthPct = asset.charWidthPct ?? 0.15;

                  return Positioned(
                    bottom: charHeight * bottomPct,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        asset.imagePath!,
                        width: charWidth * widthPct,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                } catch (e) {
                  return const SizedBox.shrink();
                }
              }),

            // 3. Expression Layer - Position face (Moved after Clothes/Body Slot)
            Positioned(
              top: widget.isAwake ? charHeight * 0.18 : charHeight * 0.13,
              left: 0,
              right: 0,
              child: Center(
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
            ),

            // Expression Layer is already at index 3 (lines 103-151)

            // Face Slot (Glasses)
            if (widget.equippedItems != null &&
                widget.equippedItems!['face'] != null)
              Builder(builder: (context) {
                final faceId = widget.equippedItems!['face'];
                try {
                  final asset =
                      CharacterAssets.items.firstWhere((e) => e.id == faceId);

                  if (asset.imagePath == null) return const SizedBox.shrink();

                  final double itemWidth =
                      charWidth * (asset.charWidthPct ?? 0.7);
                  final double topPct = widget.isAwake
                      ? (asset.charTopPctAwake ?? 0.35)
                      : (asset.charTopPctSleep ?? 0.17);

                  return Positioned(
                    top: charHeight * topPct,
                    child: Image.asset(
                      asset.imagePath!,
                      width: itemWidth,
                      fit: BoxFit.contain,
                    ),
                  );
                } catch (e) {
                  return const SizedBox.shrink();
                }
              }),

            // Head Slot (Sprout, Plogeyes)
            if (widget.equippedItems != null &&
                widget.equippedItems!['head'] != null)
              Builder(builder: (context) {
                final headId = widget.equippedItems!['head'];
                try {
                  final asset =
                      CharacterAssets.items.firstWhere((e) => e.id == headId);

                  if (asset.imagePath == null) return const SizedBox.shrink();

                  final double itemWidth =
                      charWidth * (asset.charWidthPct ?? 0.3);
                  final double topPct = widget.isAwake
                      ? (asset.charTopPctAwake ?? -0.02)
                      : (asset.charTopPctSleep ?? -0.05);

                  return Positioned(
                    top: charHeight * topPct,
                    child: Image.asset(
                      asset.imagePath!,
                      width: itemWidth,
                      fit: BoxFit.contain,
                    ),
                  );
                } catch (e) {
                  return const SizedBox.shrink();
                }
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

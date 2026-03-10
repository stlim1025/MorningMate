import 'package:flutter/material.dart';

import '../../../core/constants/character_assets.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../core/constants/room_assets.dart';

class CharacterDisplay extends StatefulWidget {
  final bool isAwake;
  final int characterLevel;
  final double size;
  final bool isTapped;
  final bool enableAnimation;
  final Map<String, dynamic>? equippedItems;
  final RoomAsset? previewAsset;

  const CharacterDisplay({
    super.key,
    required this.isAwake,
    required this.characterLevel,
    required this.size,
    this.isTapped = false,
    this.enableAnimation = true,
    this.equippedItems,
    this.previewAsset,
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
                // 4레벨이상일 때만 날개를 더 크게 유지(1.3배), 나머지는 원래 크기인 1.1배
                final double wingScale = widget.characterLevel >= 4 ? 1.3 : 1.1;

                return Transform.scale(
                  scale: wingScale,
                  child: Image.asset(
                    widget.characterLevel >= 6
                        ? 'assets/images/Egg_Wing5.png'
                        : widget.characterLevel >= 5
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
            Positioned(
              top: widget.isAwake ? charHeight * 0.20 : charHeight * 0.15,
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
                              top: widget.isAwake ? charHeight * 0.06 : 0,
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

            // 4. Clothes Slot
            Builder(builder: (context) {
              final clothesId = widget.equippedItems?['clothes'];
              final previewClothes =
                  widget.previewAsset?.category == 'clothes' ||
                          widget.previewAsset?.category == 'character'
                      ? widget.previewAsset
                      : null;

              try {
                final asset = previewClothes ??
                    (clothesId != null
                        ? CharacterAssets.items
                            .firstWhere((e) => e.id == clothesId)
                        : null);

                if (asset == null ||
                    (asset.imagePath == null && asset.imageBytes == null)) {
                  return const SizedBox.shrink();
                }

                // Apply scale based on awake status
                final double clothesScale = widget.isAwake
                    ? (asset.charScaleAwake ?? 1.0)
                    : (asset.charScaleSleep ?? 1.0);

                return Transform.scale(
                  scale: clothesScale,
                  child: Transform.translate(
                    offset: Offset(
                      charWidth * (asset.charLeftPct ?? 0.0),
                      charHeight *
                          ((asset.charTopPctAwake ?? 0.0) -
                              (asset.charBottomPct ?? 0.0)),
                    ),
                    child: NetworkOrAssetImage(
                      imagePath: asset.imagePath,
                      imageBytes: asset.imageBytes,
                      width: charWidth,
                      height: charHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              } catch (e) {
                return const SizedBox.shrink();
              }
            }),

            // 4. Accessories Layer (Necktie, Glasses, etc.)
            // Body Slot (Necktie)
            Builder(builder: (context) {
              final bodyId = widget.equippedItems?['body'];
              final previewBody = widget.previewAsset?.category == 'body'
                  ? widget.previewAsset
                  : null;

              try {
                final asset = previewBody ??
                    (bodyId != null
                        ? CharacterAssets.items
                            .firstWhere((e) => e.id == bodyId)
                        : null);

                if (asset == null ||
                    (asset.imagePath == null && asset.imageBytes == null)) {
                  return const SizedBox.shrink();
                }

                // Legacy defaults based on item name (to support DB items without explicit offsets)
                final isMuffler = (asset.name.contains('목도리') ||
                    (asset.nameEn?.toLowerCase() ?? '').contains('muffler') ||
                    asset.id.contains('mupler') ||
                    asset.id.contains('muffler'));
                final isRibbon = (asset.name.contains('리본') ||
                    (asset.nameEn?.toLowerCase() ?? '').contains('ribbon') ||
                    asset.id.contains('ribbon'));

                final double baseBottom = 0.08;
                final double widthPct = asset.charWidthPct ??
                    (isMuffler ? 0.7 : (isRibbon ? 0.3 : 0.15));

                // If admin values are null, use legacy defaults for muffler/ribbon
                final double offsetBottom = asset.charBottomPct ??
                    (isMuffler ? -0.23 : (isRibbon ? 0.17 : 0.0));
                final double offsetTop = asset.charTopPctAwake ?? 0.0;

                return Positioned(
                  bottom: charHeight * baseBottom,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(
                        charWidth * (asset.charLeftPct ?? 0.0),
                        charHeight * (offsetTop - offsetBottom),
                      ),
                      child: NetworkOrAssetImage(
                        imagePath: asset.imagePath,
                        imageBytes: asset.imageBytes,
                        width: charWidth * widthPct,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              } catch (e) {
                return const SizedBox.shrink();
              }
            }),

            // Face Slot (Glasses)
            Builder(builder: (context) {
              final faceId = widget.equippedItems?['face'];
              final previewFace = widget.previewAsset?.category == 'face'
                  ? widget.previewAsset
                  : null;

              try {
                final asset = previewFace ??
                    (faceId != null
                        ? CharacterAssets.items
                            .firstWhere((e) => e.id == faceId)
                        : null);

                if (asset == null ||
                    (asset.imagePath == null && asset.imageBytes == null)) {
                  return const SizedBox.shrink();
                }

                final double itemWidth =
                    charWidth * (asset.charWidthPct ?? 0.7);
                final double baseTop = widget.isAwake ? 0.38 : 0.20;
                final double offsetTop = widget.isAwake
                    ? (asset.charTopPctAwake ?? 0.0)
                    : (asset.charTopPctSleep ?? 0.0);

                return Positioned(
                  top: charHeight * baseTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(
                        charWidth * (asset.charLeftPct ?? 0.0),
                        charHeight * (offsetTop - (asset.charBottomPct ?? 0.0)),
                      ),
                      child: NetworkOrAssetImage(
                        imagePath: asset.imagePath,
                        imageBytes: asset.imageBytes,
                        width: itemWidth,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              } catch (e) {
                return const SizedBox.shrink();
              }
            }),

            // Head Slot (Sprout, Plogeyes)
            Builder(builder: (context) {
              final headId = widget.equippedItems?['head'];
              final previewHead = widget.previewAsset?.category == 'head'
                  ? widget.previewAsset
                  : null;

              try {
                final asset = previewHead ??
                    (headId != null
                        ? CharacterAssets.items
                            .firstWhere((e) => e.id == headId)
                        : null);

                if (asset == null ||
                    (asset.imagePath == null && asset.imageBytes == null)) {
                  return const SizedBox.shrink();
                }

                final double itemWidth =
                    charWidth * (asset.charWidthPct ?? 0.3);
                final double baseTop = widget.isAwake ? 0.01 : -0.02;
                final double offsetTop = widget.isAwake
                    ? (asset.charTopPctAwake ?? 0.0)
                    : (asset.charTopPctSleep ?? 0.0);

                return Positioned(
                  top: charHeight * baseTop,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(
                        charWidth * (asset.charLeftPct ?? 0.0),
                        charHeight * (offsetTop - (asset.charBottomPct ?? 0.0)),
                      ),
                      child: NetworkOrAssetImage(
                        imagePath: asset.imagePath,
                        imageBytes: asset.imageBytes,
                        width: itemWidth,
                        fit: BoxFit.contain,
                      ),
                    ),
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

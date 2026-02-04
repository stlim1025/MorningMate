import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/constants/room_assets.dart';
import '../../../data/models/room_decoration_model.dart';
import 'room_background_widget.dart';

class EnhancedCharacterRoomWidget extends StatefulWidget {
  final bool isAwake;
  final int characterLevel;
  final int consecutiveDays;
  final RoomDecorationModel? roomDecoration;
  final bool hideProps;
  final bool showBorder;
  final String currentAnimation;
  final Function(RoomPropModel)? onPropTap;
  final bool isDarkMode;
  final AppColorScheme? colorScheme;

  const EnhancedCharacterRoomWidget({
    super.key,
    required this.isAwake,
    this.characterLevel = 1,
    this.consecutiveDays = 0,
    this.roomDecoration,
    this.hideProps = false,
    this.showBorder = false,
    this.currentAnimation = 'idle',
    this.onPropTap,
    this.isDarkMode = false,
    this.colorScheme,
  });

  @override
  State<EnhancedCharacterRoomWidget> createState() =>
      _EnhancedCharacterRoomWidgetState();
}

class _EnhancedCharacterRoomWidgetState
    extends State<EnhancedCharacterRoomWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  bool _isTapped = false;
  Timer? _tapTimer;
  Timer? _wanderTimer;
  Timer? _movementStopTimer;
  double _horizontalPosition = 0.5; // 0.0 to 1.0
  double _verticalPosition = 0.5; // 0.0 to 1.0
  bool _isMoving = false;
  bool _isDragging = false;
  bool _isFalling = false;
  double? _dragBottom;
  double? _dragLeft;

  void _handleTap() {
    if (_isTapped) return;
    setState(() {
      _isTapped = true;
      _isMoving = true;
    });
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isTapped = false;
          _isMoving = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration:
          const Duration(milliseconds: 1500), // Slower, more natural rhythm
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startWandering();

    // 이미지 미리 로드하여 깜빡임 방지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        precacheImage(const AssetImage('assets/images/Face_Wink.png'), context);
        precacheImage(
            const AssetImage('assets/images/Face_Sleep.png'), context);
        precacheImage(
            const AssetImage('assets/images/Face_Drool.png'), context);
        precacheImage(const AssetImage('assets/images/Egg_Wing.png'), context);
        precacheImage(const AssetImage('assets/images/Egg_Wing2.png'), context);
      }
    });
  }

  void _move() {
    if (mounted && widget.isAwake) {
      setState(() {
        _isMoving = true;
        _horizontalPosition = 0.05 + Random().nextDouble() * 0.9;
        _verticalPosition = Random().nextDouble();
      });

      _movementStopTimer?.cancel();
      _movementStopTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) {
          setState(() {
            _isMoving = false;
          });
        }
      });
    }
  }

  void _startWandering() {
    _wanderTimer?.cancel();
    _movementStopTimer?.cancel();
    if (widget.isAwake) {
      // 즉시 첫 번째 이동 시작
      _move();
      // 이후 6초마다 반복 이동
      _wanderTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
        _move();
      });
    }
  }

  @override
  void didUpdateWidget(EnhancedCharacterRoomWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAwake != oldWidget.isAwake) {
      if (widget.isAwake) {
        _startWandering();
      } else {
        _wanderTimer?.cancel();
        _movementStopTimer?.cancel();
        setState(() {
          _horizontalPosition = 0.5; // Reset to center when sleeping
          _verticalPosition = 0.5;
          _isMoving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tapTimer?.cancel();
    _wanderTimer?.cancel();
    _movementStopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        widget.colorScheme ?? Theme.of(context).extension<AppColorScheme>()!;
    final decoration = widget.roomDecoration ?? RoomDecorationModel();

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : (constraints.maxWidth * 1.2);
      final size = width > height ? height : width;

      return Container(
        width: width,
        height: height,
        decoration: widget.showBorder
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isAwake
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white12,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadowColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              )
            : null,
        clipBehavior: widget.showBorder ? Clip.antiAlias : Clip.none,
        child: Stack(
          children: [
            // 3D 방 내부 (바닥, 벽, 창문)
            _build3DRoom(
                widget.isAwake, colorScheme, decoration, width, height),

            // Props
            if (!widget.hideProps)
              ...decoration.props
                  .where((prop) => _isPropValid(prop))
                  .map((prop) => _buildPropFor3D(prop, width, height)),

            // Character
            _buildCharacterContainer3D(
                widget.isAwake, colorScheme, width, height),

            // Level Up Effect
            if (widget.currentAnimation == 'evolve') _buildLevelUpEffect(size),
          ],
        ),
      );
    });
  }

  /// 3D 원근감 방: 천정, 바닥(사다리꼴), 벽, 창문(배경 표시)
  Widget _build3DRoom(bool isAwake, AppColorScheme colorScheme,
      RoomDecorationModel decoration, double width, double height) {
    // 이미지 빨간 선 기준 비율 정의
    final hLineYTop = height * 0.15; // 천장과 뒷벽의 경계 (상단 15%)
    final hLineYBottom = height * 0.42; // 뒷벽과 바닥의 경계 (뒷벽 높이 약 27%)
    final vLineX = width * 0.32; // 좌측벽과 뒷벽의 경계 (좌측 32%)
    final floorLeftY = height * 0.60; // 바닥 왼쪽 끝 지점 (이미지 빨간 선 기준 - 더 위로)

    // 바닥 에셋
    final floorAsset = RoomAssets.floors.firstWhere(
      (f) => f.id == decoration.floorId,
      orElse: () => RoomAssets.floors.first,
    );

    // 벽지
    final wallpaperAsset = RoomAssets.wallpapers.firstWhere(
      (w) => w.id == decoration.wallpaperId,
      orElse: () => RoomAssets.wallpapers.first,
    );
    Color baseColor = wallpaperAsset.color ?? const Color(0xFFF5F5DC);
    Color wallpaperColor = isAwake
        ? baseColor
        : Color.lerp(baseColor, Colors.black, 0.45) ?? baseColor;

    return Stack(
      children: [
        // 0. 기본 배경
        Positioned.fill(
          child: Container(
            color: isAwake ? const Color(0xFFF5F0E8) : const Color(0xFF2A2A2A),
          ),
        ),

        // 1. 천장 (Ceiling)
        Positioned.fill(
          child: ClipPath(
            clipper: _CeilingClipper(
              hLineYTop: hLineYTop,
              vLineX: vLineX,
            ),
            child: Container(
              color: isAwake
                  ? const Color(0xFFF9F9F7) // 우윳빛 하얀색
                  : const Color(0xFF333333),
            ),
          ),
        ),

        // 2. 뒷벽 (Back Wall)
        Positioned(
          left: vLineX,
          top: hLineYTop,
          right: 0,
          height: hLineYBottom - hLineYTop,
          child: _buildWallSurface(wallpaperAsset, wallpaperColor, isAwake,
              width - vLineX, hLineYBottom - hLineYTop),
        ),

        // 3. 좌측 벽 (Left Wall)
        Positioned.fill(
          child: ClipPath(
            clipper: _LeftWallClipper(
              hLineYTop: hLineYTop,
              hLineYBottom: hLineYBottom,
              vLineX: vLineX,
              floorLeftY: floorLeftY,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildWallSurface(
                      wallpaperAsset, wallpaperColor, isAwake, width, height),
                ),
                // 창문 (좌측 벽에 부착)
                Positioned(
                  left: vLineX * 0.2,
                  top: hLineYTop + (hLineYBottom - hLineYTop) * 0.15,
                  width: vLineX * 0.65,
                  height: (hLineYBottom - hLineYTop) * 0.7,
                  child: Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // 원근감
                      ..rotateY(0.45), // 좌측 벽 각도 반영
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF8B7355),
                          width: 5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: RoomBackgroundWidget(
                          decoration: decoration,
                          isAwake: isAwake,
                          isDarkMode: widget.isDarkMode,
                          colorScheme: widget.colorScheme ?? colorScheme,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. 바닥 (Floor)
        Positioned.fill(
          child: ClipPath(
            clipper: _FloorClipper(
              vLineX: vLineX,
              hLineYBottom: hLineYBottom,
              floorLeftY: floorLeftY,
            ),
            child: Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // 원근감 최적화
                ..rotateX(-0.12) // 기울기 완화
                ..scale(1.4, 1.7), // 이미지 배율 축소 (패턴이 더 많이 보임)
              child: Container(
                decoration: BoxDecoration(
                  color: floorAsset.color ??
                      (isAwake
                          ? const Color(0xFFE8DCCF)
                          : Colors.brown.shade800),
                  image: (floorAsset.imagePath != null &&
                          !floorAsset.imagePath!.endsWith('.svg'))
                      ? DecorationImage(
                          image: AssetImage(floorAsset.imagePath!),
                          fit: BoxFit.cover,
                          repeat: ImageRepeat.repeat,
                          alignment: Alignment.topCenter,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (floorAsset.imagePath != null &&
                        floorAsset.imagePath!.endsWith('.svg'))
                      Positioned.fill(
                        child: SvgPicture.asset(
                          floorAsset.imagePath!,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    if (!isAwake)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWallSurface(RoomAsset wallpaperAsset, Color wallpaperColor,
      bool isAwake, double sizeWidth, double sizeHeight) {
    if (wallpaperAsset.imagePath != null) {
      return Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              wallpaperAsset.imagePath!,
              fit: BoxFit.fill,
            ),
          ),
          if (!isAwake)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.45),
              ),
            ),
        ],
      );
    }
    if (wallpaperAsset.id == 'black_stripe') {
      return Container(
        color: wallpaperColor,
        child: Stack(
          children: List.generate(6, (index) {
            return Positioned(
              top: (index + 1) * (sizeHeight / 7),
              left: 0,
              right: 0,
              child: Container(
                height: 1.2,
                color: Colors.white.withOpacity(0.12),
              ),
            );
          }),
        ),
      );
    }
    return Container(color: wallpaperColor);
  }

  Widget _buildLevelUpEffect(double size) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 1.0 + (value * 2.0),
                child: Opacity(
                  opacity: (1.0 - value).clamp(0.0, 1.0),
                  child: Container(
                    width: size * 0.5,
                    height: size * 0.5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 50,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 3D 바닥에 Prop 배치 (사다리꼴 좌표계)
  Widget _buildPropFor3D(RoomPropModel prop, double width, double height) {
    final hLineYBottom = height * 0.42;
    final vLineX = width * 0.32;
    final floorLeftY = height * 0.60;

    final asset = RoomAssets.props.firstWhere(
      (p) => p.id == prop.type,
      orElse: () =>
          const RoomAsset(id: '', name: '', price: 0, icon: Icons.circle),
    );
    final baseSize = (width + height) * 0.08 * asset.sizeMultiplier;
    final propWidth = baseSize * asset.aspectRatio;
    final propHeight = baseSize;

    // prop.y: 0=앞(바닥 하단), 1=뒤(벽 근처)
    final py = prop.y.clamp(0.05, 0.95);
    final px = prop.x.clamp(0.05, 0.95);

    // 좌표 매핑
    final yPos = hLineYBottom + (1 - py) * (height - hLineYBottom);
    // 바닥 왼쪽 경계선 보간: hLineYBottom일 때 vLineX, floorLeftY일 때 0
    double xLeft = 0;
    if (yPos < floorLeftY) {
      xLeft = vLineX * (floorLeftY - yPos) / (floorLeftY - hLineYBottom);
    } else {
      xLeft = 0;
    }

    final xRight = width;
    final xPos = xLeft + px * (xRight - xLeft) - propWidth / 2;

    return Positioned(
      left: xPos.clamp(0.0, width - propWidth),
      top: (yPos - propHeight).clamp(hLineYBottom, height - propHeight),
      child: GestureDetector(
        onTap: () => widget.onPropTap?.call(prop),
        child: _getPropVisual(prop.type, propWidth, propHeight),
      ),
    );
  }

  /// 3D 바닥 위 캐릭터 (드래그/배회 시 좌표 변환)
  Widget _buildCharacterContainer3D(
      bool isAwake, AppColorScheme colorScheme, double width, double height) {
    final hLineYBottom = height * 0.42;
    final vLineX = width * 0.32;
    final floorLeftY = height * 0.60;
    final charSize = (width + height) * 0.12;

    double currentLeft;
    double currentTop;

    if (_isDragging && _dragLeft != null && _dragBottom != null) {
      currentLeft = _dragLeft!.clamp(0.0, width - charSize);
      currentTop = height -
          charSize -
          _dragBottom!.clamp(0.0, height - hLineYBottom - charSize);
    } else {
      final py = _verticalPosition.clamp(0.05, 0.95);
      final px = _horizontalPosition.clamp(0.05, 0.95);

      final yPos = hLineYBottom + (1 - py) * (height - hLineYBottom);
      double xLeft = 0;
      if (yPos < floorLeftY) {
        xLeft = vLineX * (floorLeftY - yPos) / (floorLeftY - hLineYBottom);
      } else {
        xLeft = 0;
      }

      final xRight = width;
      currentLeft = xLeft + px * (xRight - xLeft) - charSize / 2;
      currentTop = yPos - charSize + (isAwake ? 0 : charSize * 0.3);

      currentLeft = currentLeft.clamp(0.0, width - charSize);
      currentTop =
          currentTop.clamp(hLineYBottom - charSize * 0.5, height - charSize);
    }

    return Stack(
      children: [
        AnimatedPositioned(
          duration: _isDragging
              ? Duration.zero
              : (_isFalling
                  ? const Duration(milliseconds: 800)
                  : const Duration(milliseconds: 3500)),
          curve: _isFalling ? Curves.bounceOut : Curves.easeInOutQuart,
          left: currentLeft,
          top: currentTop,
          child: GestureDetector(
            onTap: _handleTap,
            onPanStart: (d) => _handleDragStart3D(d, width, height, charSize),
            onPanUpdate: (d) => _handleDragUpdate3D(d, width, height, charSize),
            onPanEnd: (d) => _handleDragEnd3D(d, width, height, charSize),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _isTapped ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, tapValue, child) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0.15,
                    end: (isAwake && (_isMoving || _isTapped)) ? 1.0 : 0.15,
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  builder: (context, intensity, child) {
                    return AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        final jumpHeight =
                            _bounceAnimation.value * 15 * intensity;
                        final tapLift = tapValue * 4;
                        final verticalOffset = -jumpHeight - tapLift;
                        final maxSquash = 0.08 * intensity;
                        final scaleX = (1.0 + maxSquash) -
                            (_bounceAnimation.value * maxSquash * 2);
                        final scaleY = (1.0 - maxSquash) +
                            (_bounceAnimation.value * maxSquash * 2);
                        return Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..translate(0.0, verticalOffset)
                            ..scale(scaleX, scaleY),
                          child:
                              _buildCharacter(isAwake, colorScheme, charSize),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _handleDragStart3D(
      DragStartDetails d, double width, double height, double charSize) {
    if (!widget.isAwake) return;
    _wanderTimer?.cancel();
    _movementStopTimer?.cancel();
    final hLineYBottom = height * 0.42;
    final vLineX = width * 0.32;
    final floorLeftY = height * 0.60;

    final py = _verticalPosition.clamp(0.05, 0.95);
    final px = _horizontalPosition.clamp(0.05, 0.95);

    final yPos = hLineYBottom + (1 - py) * (height - hLineYBottom);
    double xLeft = 0;
    if (yPos < floorLeftY) {
      xLeft = vLineX * (floorLeftY - yPos) / (floorLeftY - hLineYBottom);
    } else {
      xLeft = 0;
    }

    final xRight = width;
    final baseLeft = xLeft + px * (xRight - xLeft) - charSize / 2;
    final baseTop = yPos - charSize;

    setState(() {
      _isDragging = true;
      _isFalling = false;
      _isMoving = true;
      _dragLeft = baseLeft;
      _dragBottom = height - baseTop - charSize;
    });
  }

  void _handleDragUpdate3D(
      DragUpdateDetails d, double width, double height, double charSize) {
    if (!_isDragging) return;
    final hLineYBottom = height * 0.42;
    setState(() {
      _dragLeft = ((_dragLeft ?? 0) + d.delta.dx).clamp(0.0, width - charSize);
      _dragBottom = ((_dragBottom ?? 0) - d.delta.dy)
          .clamp(0.0, height - hLineYBottom - charSize * 0.5);
    });
  }

  void _handleDragEnd3D(
      DragEndDetails d, double width, double height, double charSize) {
    if (!_isDragging) return;
    final hLineYBottom = height * 0.42;
    final vLineX = width * 0.32;
    setState(() {
      _isDragging = false;
      _isFalling = true;

      final currentY = height - (_dragBottom ?? 0) - charSize;
      final py = (1 - (currentY - hLineYBottom) / (height - hLineYBottom))
          .clamp(0.05, 0.95);

      final floorLeftY = height * 0.60;
      double xLeft = 0;
      if (currentY < floorLeftY) {
        xLeft = vLineX * (floorLeftY - currentY) / (floorLeftY - hLineYBottom);
      } else {
        xLeft = 0;
      }

      final xRight = width;
      final px = (((_dragLeft ?? 0) + charSize / 2 - xLeft) / (xRight - xLeft))
          .clamp(0.05, 0.95);

      _verticalPosition = py;
      _horizontalPosition = px;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isFalling = false;
          _isMoving = false;
        });
        _startWandering();
      }
    });
  }

  Widget _getPropVisual(String type, double width, double height) {
    if (type.isEmpty) return SizedBox(width: width, height: height);
    final asset = RoomAssets.props.firstWhere((p) => p.id == type,
        orElse: () =>
            const RoomAsset(id: '', name: '', price: 0, icon: Icons.circle));
    if (asset.id.isEmpty) return SizedBox(width: width, height: height);

    if (asset.imagePath != null) {
      return Opacity(
        opacity:
            widget.isAwake ? 1.0 : 0.9, // Night mode slightly dimmed but clear
        child: asset.imagePath!.endsWith('.svg')
            ? SvgPicture.asset(
                asset.imagePath!,
                width: width * 0.9,
                height: height * 0.9,
                fit: BoxFit.contain,
              )
            : Image.asset(
                asset.imagePath!,
                width: width * 0.9,
                height: height * 0.9,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image fails to load
                  return Icon(asset.icon,
                      color: Colors.blueGrey,
                      size: (width < height ? width : height) * 0.7);
                },
              ),
      );
    }

    return Icon(asset.icon,
        color: Colors.blueGrey, size: (width < height ? width : height) * 0.7);
  }

  Widget _buildCharacter(
      bool isAwake, AppColorScheme colorScheme, double size) {
    // Shared dimensions for the character components
    final double charWidth = size * 0.80;
    final double charHeight = size * 0.75;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Wings (Level 2+) - Static layer to prevent flickering
          if (widget.characterLevel >= 2)
            Image.asset(
              widget.characterLevel >= 3
                  ? 'assets/images/Egg_Wing2.png'
                  : 'assets/images/Egg_Wing.png',
              width:
                  widget.characterLevel >= 3 ? charWidth * 2 : charWidth * 1.2,
              height: widget.characterLevel >= 3 ? charHeight * 2 : charHeight,
              fit: BoxFit.contain,
            ),

          // 2. Base Body - Static layer to prevent flickering
          Image.asset(
            isAwake ? 'assets/images/Body.png' : 'assets/images/Sleep_Body.png',
            width: charWidth,
            height: charHeight,
            fit: BoxFit.contain,
          ),

          // 3. Expression Layer - Only cross-fade the face
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            crossFadeState: _isTapped
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Image.asset(
              isAwake
                  ? 'assets/images/Face_Default.png'
                  : 'assets/images/Face_Sleep.png',
              width: charWidth,
              height: charHeight,
              fit: BoxFit.contain,
              key: const ValueKey('face_normal'),
            ),
            secondChild: Image.asset(
              isAwake
                  ? 'assets/images/Face_Wink.png'
                  : 'assets/images/Face_Drool.png',
              width: charWidth,
              height: charHeight,
              fit: BoxFit.contain,
              key: const ValueKey('face_tapped'),
            ),
          ),

          // Zzz animation (if sleeping)
          if (!isAwake)
            Positioned(
              top: -size * 0.05,
              right: size * 0.05,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      10 * (1 - _animationController.value),
                      -20 * _animationController.value,
                    ),
                    child: Opacity(
                      opacity: (1 - _animationController.value).clamp(0.0, 1.0),
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
    );
  }

  bool _isPropValid(RoomPropModel prop) {
    if (prop.type != 'sticky_note') return true;
    if (prop.metadata == null || prop.metadata!['createdAt'] == null) {
      return false;
    }

    try {
      final now = DateTime.now();
      final createdAt = DateTime.parse(prop.metadata!['createdAt']);
      // 같은 날짜인지 확인 (년, 월, 일)
      return createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    } catch (e) {
      debugPrint('메모 날짜 파싱 오류: $e');
      return false;
    }
  }
}

/// 천장용 클리퍼
class _CeilingClipper extends CustomClipper<Path> {
  final double hLineYTop;
  final double vLineX;

  _CeilingClipper({required this.hLineYTop, required this.vLineX});

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, hLineYTop)
      ..lineTo(vLineX, hLineYTop)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// 좌측 벽용 클리퍼 (이미지 빨간 선 기준)
class _LeftWallClipper extends CustomClipper<Path> {
  final double hLineYTop;
  final double hLineYBottom;
  final double vLineX;
  final double floorLeftY;

  _LeftWallClipper({
    required this.hLineYTop,
    required this.hLineYBottom,
    required this.vLineX,
    required this.floorLeftY,
  });

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(vLineX, hLineYTop)
      ..lineTo(vLineX, hLineYBottom)
      ..lineTo(0, floorLeftY)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// 3D 원근감 바닥용 클리퍼
class _FloorClipper extends CustomClipper<Path> {
  final double vLineX;
  final double hLineYBottom;
  final double floorLeftY;

  _FloorClipper({
    required this.vLineX,
    required this.hLineYBottom,
    required this.floorLeftY,
  });

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(vLineX, hLineYBottom)
      ..lineTo(size.width, hLineYBottom)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, floorLeftY)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

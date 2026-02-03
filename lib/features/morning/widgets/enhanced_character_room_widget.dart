import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/constants/room_assets.dart';
import '../../../data/models/room_decoration_model.dart';

class EnhancedCharacterRoomWidget extends StatefulWidget {
  final bool isAwake;
  final int characterLevel;
  final int consecutiveDays;
  final RoomDecorationModel? roomDecoration;
  final bool hideProps;
  final bool showBorder;
  final String currentAnimation;
  final Function(RoomPropModel)? onPropTap;

  const EnhancedCharacterRoomWidget({
    super.key,
    required this.isAwake,
    this.characterLevel = 1,
    this.consecutiveDays = 0,
    this.roomDecoration,
    this.hideProps = false,
    this.showBorder = true,
    this.currentAnimation = 'idle',
    this.onPropTap,
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

  void _handleDragStart(
      DragStartDetails details, double size, double charSize) {
    if (!widget.isAwake) return;
    _wanderTimer?.cancel();
    _movementStopTimer?.cancel();
    setState(() {
      _isDragging = true;
      _isFalling = false;
      _isMoving = true;
      // Initialize drag position BASED on current position
      _dragBottom = (size * 0.0) + (size * 0.23 * _verticalPosition);
      _dragLeft = (size - charSize) * _horizontalPosition;
    });
  }

  void _handleDragUpdate(
      DragUpdateDetails details, double size, double charSize) {
    if (!_isDragging) return;
    setState(() {
      // update pixel positions directly
      // In Flutter, delta.dy is positive downwards, so we SUBTRACT from bottom
      _dragBottom = (_dragBottom ?? 0) - details.delta.dy;
      _dragLeft = (_dragLeft ?? 0) + details.delta.dx;

      // Clamp within room bounds (approximate)
      _dragBottom = (_dragBottom ?? 0).clamp(0.0, size - charSize);
      _dragLeft = (_dragLeft ?? 0).clamp(0.0, size - charSize);
    });
  }

  void _handleDragEnd(DragEndDetails details, double size, double charSize) {
    if (!_isDragging) return;

    setState(() {
      _isDragging = false;
      _isFalling = true;

      // When dropped, we want to fall back to the "floor"
      // Floor bottom range is 0.01 to 0.23 of size
      _verticalPosition = Random().nextDouble();
      // Map pixel left back to _horizontalPosition percentage
      _horizontalPosition = (_dragLeft ?? 0) / (size - charSize);
      _horizontalPosition = _horizontalPosition.clamp(0.05, 0.95);
    });

    // Reset falling state after animation finishes
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final decoration = widget.roomDecoration ?? RoomDecorationModel();

    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.maxWidth;

      return Container(
        width: size,
        height: size,
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
            // Wallpaper/Background
            _buildRoomBackground(widget.isAwake, colorScheme, decoration, size),

            // Props
            if (!widget.hideProps)
              ...decoration.props.map((prop) => _buildProp(prop, size)),

            // Character
            _buildCharacterContainer(widget.isAwake, colorScheme, size),

            // Level Up Effect
            if (widget.currentAnimation == 'evolve') _buildLevelUpEffect(size),
          ],
        ),
      );
    });
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

  Widget _buildRoomBackground(bool isAwake, AppColorScheme colorScheme,
      RoomDecorationModel decoration, double size) {
    // 1. Base Wall (Background natural scenery)
    Widget nature;
    switch (decoration.backgroundId) {
      case 'forest':
        nature = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green.shade200, Colors.green.shade400],
            ),
          ),
          child: Opacity(
            opacity: 0.3,
            child: Icon(Icons.park, size: 200, color: Colors.green.shade800),
          ),
        );
        break;
      case 'valley':
        nature = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blueGrey.shade100, Colors.blueGrey.shade300],
            ),
          ),
          child: Opacity(
            opacity: 0.3,
            child:
                Icon(Icons.terrain, size: 200, color: Colors.blueGrey.shade600),
          ),
        );
        break;
      case 'sea':
        nature = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade200, Colors.blue.shade600],
            ),
          ),
          child: Opacity(
            opacity: 0.3,
            child: Icon(Icons.tsunami, size: 200, color: Colors.blue.shade800),
          ),
        );
        break;
      case 'space':
        nature = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF0D0221), const Color(0xFF240B36)],
            ),
          ),
          child: Opacity(
            opacity: 0.3,
            child: Icon(Icons.rocket_launch,
                size: 200, color: Colors.indigo.shade200),
          ),
          // Removed Opacity and Icon
        );
        break;
      default:
        nature = Container(color: Colors.transparent);
    }

    // 2. Wallpaper Color Logic
    Color wallpaperColor;
    final wallpaperAsset = RoomAssets.wallpapers.firstWhere(
      (w) => w.id == decoration.wallpaperId,
      orElse: () => RoomAssets.wallpapers.first,
    );

    // If specific wallpaper color is defined in asset, use it.
    // Otherwise fallback to theme/awake logic.
    // If specific wallpaper color is defined in asset, use it.
    // Otherwise fallback to a default color.
    Color baseColor = wallpaperAsset.color ?? const Color(0xFFF5F5DC);

    // Apply Night filter manually to decouple from UI theme
    if (!isAwake) {
      wallpaperColor = Color.lerp(baseColor, Colors.black, 0.45) ?? baseColor;
    } else {
      wallpaperColor = baseColor;
    }

    // Adjust opacity if background is present to blend or show context?
    // Actually, if we use the 'Sky View' approach, the wall is solid but shorter.

    Widget buildWallSurface() {
      if (wallpaperAsset.imagePath != null) {
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(wallpaperAsset.imagePath!),
                    fit: BoxFit.fill,
                  ),
                ),
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
                top: (index + 1) * (size * 0.7 / 7),
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

    return Stack(
      children: [
        // 1. Outside Nature (Visible through window or open ceiling)
        Positioned.fill(child: nature),

        // 2. Room Interior
        Positioned.fill(
          child: Column(
            children: [
              // Wall
              Expanded(
                flex: 7,
                child: Stack(
                  children: [
                    // Base Wallpaper (Single integrated surface with window hole)
                    Positioned.fill(
                      child: decoration.backgroundId != 'none'
                          ? ClipPath(
                              clipper: WindowHoleClipper(),
                              child: buildWallSurface(),
                            )
                          : buildWallSurface(),
                    ),

                    // Overlay Window UI (If background is not 'none')
                    if (decoration.backgroundId != 'none')
                      Positioned.fill(
                        child: Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.5,
                            heightFactor: 0.5,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white
                                      .withOpacity(isAwake ? 1.0 : 0.8),
                                  width: 6,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Stack(
                                  children: [
                                    // 가로 프레임
                                    Center(
                                      child: Container(
                                        width: double.infinity,
                                        height: 4,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    // 세로 프레임
                                    Center(
                                      child: Container(
                                        width: 4,
                                        height: double.infinity,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Floor
              Expanded(
                flex: 3,
                child: () {
                  final floorAsset = RoomAssets.floors.firstWhere(
                    (f) => f.id == decoration.floorId,
                    orElse: () => RoomAssets.floors.first,
                  );

                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: floorAsset.color ??
                          (isAwake
                              ? Colors.brown.shade100
                              : Colors.brown.shade300),
                      border: Border(
                        top: BorderSide(
                            color: Colors.black.withOpacity(0.1), width: 2),
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (floorAsset.imagePath != null)
                          Positioned.fill(
                            child: floorAsset.imagePath!.endsWith('.svg')
                                ? SvgPicture.asset(
                                    floorAsset.imagePath!,
                                    fit: BoxFit.fill,
                                    // Apply a slight color tint if needed via theme or night mode
                                  )
                                : Image.asset(
                                    floorAsset.imagePath!,
                                    fit: BoxFit.fill,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const SizedBox.shrink();
                                    },
                                  ),
                          ),
                        if (!isAwake)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.35),
                            ),
                          ),
                      ],
                    ),
                  );
                }(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProp(RoomPropModel prop, double size) {
    final asset = RoomAssets.props.firstWhere((p) => p.id == prop.type,
        orElse: () =>
            const RoomAsset(id: '', name: '', price: 0, icon: Icons.circle));

    final baseSize = size * 0.16 * asset.sizeMultiplier;
    final propWidth = baseSize * asset.aspectRatio;
    final propHeight = baseSize;

    return Positioned(
      left: prop.x * (size - propWidth),
      top: prop.y * (size - propHeight),
      child: GestureDetector(
        onTap: () => widget.onPropTap?.call(prop),
        child: _getPropVisual(prop.type, propWidth, propHeight),
      ),
    );
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

  Widget _buildCharacterContainer(
      bool isAwake, AppColorScheme colorScheme, double size) {
    // Decreased size from 0.4 to 0.35
    final charSize = size * 0.35;

    // Determine current position based on state
    double currentBottom;
    double currentLeft;

    if (_isDragging) {
      currentBottom = _dragBottom ?? 0;
      currentLeft = _dragLeft ?? 0;
    } else {
      currentBottom = widget.isAwake
          ? (size * 0.0) + (size * 0.25 * _verticalPosition)
          : size * 0.11;
      currentLeft = (size - charSize) * _horizontalPosition;
    }

    return Stack(
      children: [
        // Character
        AnimatedPositioned(
          duration: _isDragging
              ? Duration.zero
              : (_isFalling
                  ? const Duration(milliseconds: 800)
                  : const Duration(milliseconds: 3500)),
          curve: _isFalling ? Curves.bounceOut : Curves.easeInOutQuart,
          bottom: currentBottom,
          left: currentLeft,
          child: GestureDetector(
            onTap: _handleTap,
            onPanStart: (details) => _handleDragStart(details, size, charSize),
            onPanUpdate: (details) =>
                _handleDragUpdate(details, size, charSize),
            onPanEnd: (details) => _handleDragEnd(details, size, charSize),
            child: TweenAnimationBuilder<double>(
              // Combined intensity (for jelly) and tap lift animation
              tween: Tween<double>(
                begin: 0.0,
                end: _isTapped ? 1.0 : 0.0,
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, tapValue, child) {
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.15,
                    end: (widget.isAwake && (_isMoving || _isTapped))
                        ? 1.0
                        : 0.15,
                  ),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  builder: (context, intensity, child) {
                    return AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        // Jump Height scales with intensity
                        double jumpHeight =
                            _bounceAnimation.value * 15 * intensity;
                        // Smoothly interpolate tap lift (0 to 20px)
                        double tapLift = tapValue * 20;
                        double verticalOffset = -jumpHeight - tapLift;

                        // Jelly Scale Effect scales with intensity
                        // Reduced from 0.15 to 0.08 for subtler movement
                        double maxSquash = 0.08 * intensity;
                        double scaleX = (1.0 + maxSquash) -
                            (_bounceAnimation.value * maxSquash * 2);
                        double scaleY = (1.0 - maxSquash) +
                            (_bounceAnimation.value * maxSquash * 2);

                        return Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..translate(0.0, verticalOffset)
                            ..scale(scaleX, scaleY),
                          child: _buildCharacter(
                              widget.isAwake, colorScheme, charSize),
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

  Widget _buildCharacter(
      bool isAwake, AppColorScheme colorScheme, double size) {
    // Shared dimensions for the character components
    final double charWidth = size * 0.80;
    final double charHeight = size * 0.75;

    // normalEgg construction with Wings
    final Widget normalEgg = Stack(
      alignment: Alignment.center,
      children: [
        // Wings (Level 2+)
        if (widget.characterLevel >= 2)
          Image.asset(
            'assets/images/Egg_Wing.png',
            width: charWidth * 1.2,
            height: charHeight,
            fit: BoxFit.contain,
          ),
        // Base Body
        Image.asset(
          isAwake ? 'assets/images/Body.png' : 'assets/images/Sleep_Body.png',
          width: charWidth,
          height: charHeight,
          fit: BoxFit.contain,
        ),
        // Expression Layer
        Image.asset(
          isAwake
              ? 'assets/images/Face_Default.png'
              : 'assets/images/Face_Sleep.png',
          width: charWidth,
          height: charHeight,
          fit: BoxFit.contain,
        ),
      ],
    );

    // 2. Tapped/Reaction State
    final Widget tappedEgg = Padding(
      padding: EdgeInsets.only(
        left: isAwake ? 0 : size * 0.04, // Shift slightly right when sleeping
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wings (Level 2+)
          if (widget.characterLevel >= 2)
            Image.asset(
              'assets/images/Egg_Wing.png',
              width: charWidth * 1.2,
              height: charHeight,
              fit: BoxFit.contain,
            ),
          // Base Body
          Image.asset(
            isAwake ? 'assets/images/Body.png' : 'assets/images/Sleep_Body.png',
            width: charWidth,
            height: charHeight,
            fit: BoxFit.contain,
          ),
          // Expression Layer (Wink or Drool)
          Image.asset(
            isAwake
                ? 'assets/images/Face_Wink.png'
                : 'assets/images/Face_Drool.png',
            width: isAwake ? charWidth * 1.3 : charWidth,
            height: charHeight,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            firstChild: normalEgg,
            secondChild: tappedEgg,
            crossFadeState: _isTapped
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstCurve: Curves.easeIn,
            secondCurve: Curves.easeOut,
            sizeCurve: Curves.easeInOut,
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
}

class WindowHoleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Window location based on flex 1:2:1
    double windowWidth = size.width * 0.5;
    double windowHeight = size.height * 0.5;
    double left = size.width * 0.25;
    double top = size.height * 0.25;

    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, windowWidth, windowHeight),
        const Radius.circular(12),
      ));

    return Path.combine(PathOperation.difference, path, holePath);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

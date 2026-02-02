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

  const EnhancedCharacterRoomWidget({
    super.key,
    required this.isAwake,
    this.characterLevel = 1,
    this.consecutiveDays = 0,
    this.roomDecoration,
    this.hideProps = false,
    this.showBorder = true,
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
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startWandering();
  }

  void _move() {
    if (mounted && widget.isAwake) {
      setState(() {
        _isMoving = true;
        _horizontalPosition = 0.05 + Random().nextDouble() * 0.7;
        _verticalPosition = Random().nextDouble();
      });

      _movementStopTimer?.cancel();
      _movementStopTimer = Timer(const Duration(milliseconds: 2000), () {
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
      // 이후 4초마다 반복 이동
      _wanderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
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
          ],
        ),
      );
    });
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
                        child: Column(
                          children: [
                            const Spacer(flex: 1), // Top Wall spacing
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  const Spacer(flex: 1), // Left Wall spacing
                                  // Window
                                  Expanded(
                                    flex: 2,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.white.withOpacity(
                                                  isAwake ? 1.0 : 0.8),
                                              width: 6),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: Colors.transparent,
                                        ),
                                        child: Stack(
                                          children: [
                                            Center(
                                              child: Container(
                                                  width: double.infinity,
                                                  height: 4,
                                                  color: Colors.white
                                                      .withOpacity(0.8)),
                                            ),
                                            Center(
                                              child: Container(
                                                  width: 4,
                                                  height: double.infinity,
                                                  color: Colors.white
                                                      .withOpacity(0.8)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(flex: 1), // Right Wall spacing
                                ],
                              ),
                            ),
                            const Spacer(flex: 1), // Bottom Wall spacing
                          ],
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
                            child: SvgPicture.asset(
                              floorAsset.imagePath!,
                              fit: BoxFit.fill,
                              // Apply a slight color tint if needed via theme or night mode
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
      child: _getPropVisual(prop.type, propWidth, propHeight),
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

    return Stack(
      children: [
        // Character
        AnimatedPositioned(
          duration:
              const Duration(milliseconds: 2000), // Updated to move faster
          curve: Curves.easeInOutSine,
          // Moves within floor area (approx 8% to 22% of height)
          bottom: widget.isAwake
              ? (size * 0.08) + (size * 0.14 * _verticalPosition)
              : size * 0.12,
          // Use _horizontalPosition to move left/right naturally
          left: (size - charSize) * _horizontalPosition,
          child: GestureDetector(
            onTap: _handleTap,
            child: AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                // Reduced vertical offset slightly to account for smaller size
                bool shouldAnimate = widget.isAwake && (_isMoving || _isTapped);
                double verticalOffset =
                    shouldAnimate ? -_bounceAnimation.value * 0.5 : 0;
                if (_isTapped) verticalOffset -= 20;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  transform: Matrix4.translationValues(0, verticalOffset, 0),
                  child: _buildCharacter(widget.isAwake, colorScheme, charSize),
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
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Egg Image or Animation
          _isTapped
              ? Padding(
                  padding: EdgeInsets.only(
                      bottom: size * 0.05), // 찡긋 이미지를 살짝 위로 올려서 위치 맞춤
                  child: Image.asset(
                    'assets/images/Click_Egg.png',
                    width: size * 0.95,
                    height: size * 0.90,
                    fit: BoxFit.contain,
                  ),
                )
              : (isAwake && _isMoving)
                  ? Image.asset(
                      'assets/animations/bouncing_egg.gif',
                      width: size,
                      height: size,
                      fit: BoxFit.contain,
                    )
                  : Padding(
                      padding: EdgeInsets.only(
                          bottom: size * 0.05), // 정지 이미지를 살짝 위로 올려서 위치 맞춤
                      child: Image.asset(
                        'assets/images/Egg.png',
                        width: size * 0.80,
                        height: size * 0.75,
                        fit: BoxFit.contain,
                      ),
                    ),

          // Zzz animation (if sleeping)
          if (!isAwake)
            Positioned(
              top: -size * 0.2,
              right: -size * 0.1,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Transform.translate(
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
                      ),
                    ],
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

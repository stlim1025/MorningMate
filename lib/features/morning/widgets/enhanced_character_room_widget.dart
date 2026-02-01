import 'dart:async';
import 'package:flutter/material.dart';
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

  void _handleTap() {
    if (_isTapped) return;
    setState(() {
      _isTapped = true;
    });
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isTapped = false;
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tapTimer?.cancel();
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
                child: Container(
                  width: double.infinity,
                  color:
                      decoration.backgroundId == 'none' ? wallpaperColor : null,
                  child: decoration.backgroundId == 'none'
                      ? null // Solid wall
                      : Column(
                          children: [
                            // Top Wall
                            Expanded(
                              flex: 1,
                              child: Container(color: wallpaperColor),
                            ),
                            // Window Row
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  // Left Wall
                                  Expanded(
                                      flex: 1,
                                      child: Container(color: wallpaperColor)),
                                  // Window
                                  Expanded(
                                    flex: 2,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.white, width: 6),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color:
                                              Colors.transparent, // See-through
                                        ),
                                        child: Stack(
                                          children: [
                                            Center(
                                              child: Container(
                                                  width: double.infinity,
                                                  height: 4,
                                                  color: Colors.white),
                                            ),
                                            Center(
                                              child: Container(
                                                  width: 4,
                                                  height: double.infinity,
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Right Wall
                                  Expanded(
                                      flex: 1,
                                      child: Container(color: wallpaperColor)),
                                ],
                              ),
                            ),
                            // Bottom Wall
                            Expanded(
                              flex: 1,
                              child: Container(color: wallpaperColor),
                            ),
                          ],
                        ),
                ),
              ),

              // Floor
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: (isAwake
                            ? Colors.brown.shade100
                            : Colors.brown.shade300)
                        .withOpacity(0.9),
                    border: Border(
                      top: BorderSide(
                          color: Colors.black.withOpacity(0.1), width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProp(RoomPropModel prop, double size) {
    final propSize = size * 0.16;
    return Positioned(
      left: prop.x * (size - propSize),
      top: prop.y * (size - propSize),
      child: _getPropVisual(prop.type, propSize),
    );
  }

  Widget _getPropVisual(String type, double size) {
    if (type.isEmpty) return SizedBox(width: size, height: size);
    final asset = RoomAssets.props.firstWhere((p) => p.id == type,
        orElse: () =>
            const RoomAsset(id: '', name: '', price: 0, icon: Icons.circle));
    if (asset.id.isEmpty) return SizedBox(width: size, height: size);
    return Icon(asset.icon, color: Colors.blueGrey, size: size * 0.7);
  }

  Widget _buildCharacterContainer(
      bool isAwake, AppColorScheme colorScheme, double size) {
    final charSize = size * 0.4;

    return Stack(
      children: [
        // Character
        AnimatedPositioned(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          bottom: widget.isAwake ? size * 0.25 : size * 0.15,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _handleTap,
              child: AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  double verticalOffset =
                      widget.isAwake ? -_bounceAnimation.value : 0;
                  if (_isTapped) verticalOffset -= 20;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    transform: Matrix4.translationValues(0, verticalOffset, 0),
                    child:
                        _buildCharacter(widget.isAwake, colorScheme, charSize),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCharacter(
      bool isAwake, AppColorScheme colorScheme, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB39DDB)
                .withOpacity(0.2), // Fixed soft purple shadow
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size * 0.75,
            height: size * 0.83,
            decoration: BoxDecoration(
              color: const Color(0xFFD7A86E), // Fixed warm brown body color
              borderRadius: BorderRadius.all(Radius.circular(size * 0.375)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: size * 0.58,
                  height: size * 0.67,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(size * 0.29),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: size * 0.2,
                        left: size * 0.15,
                        child: _isTapped
                            ? Text('>',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: size * 0.13))
                            : isAwake
                                ? Container(
                                    width: size * 0.06,
                                    height: size * 0.06,
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : Container(
                                    width: size * 0.1,
                                    height: size * 0.015,
                                    margin: EdgeInsets.only(top: size * 0.03),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                      ),
                      Positioned(
                        top: size * 0.2,
                        right: size * 0.15,
                        child: _isTapped
                            ? Text('<',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: size * 0.13))
                            : isAwake
                                ? Container(
                                    width: size * 0.06,
                                    height: size * 0.06,
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : Container(
                                    width: size * 0.1,
                                    height: size * 0.015,
                                    margin: EdgeInsets.only(top: size * 0.03),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                      ),
                      Positioned(
                        top: size * 0.28,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _isTapped ? size * 0.13 : size * 0.1,
                            height: isAwake ? size * 0.08 : size * 0.05,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: isAwake
                                  ? const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                      bottomRight: Radius.circular(8),
                                      topLeft: Radius.circular(2),
                                      topRight: Radius.circular(2),
                                    )
                                  : BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isAwake)
            Positioned(
              top: -20,
              right: 0,
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

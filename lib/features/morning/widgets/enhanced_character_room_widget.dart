import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/constants/room_assets.dart';
import '../../../data/models/room_decoration_model.dart';
import '../../character/widgets/character_display.dart';
import 'room_background_widget.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    this.isPropEditable = false,
    this.onPropChanged,
    this.selectedPropIndex,
    this.onPropDelete,
    this.todaysMood,
    this.bottomPadding = 0,
    this.equippedCharacterItems,
    this.visitorCharacterLevel,
    this.visitorEquippedItems,
  });

  final bool isPropEditable;
  final Function(int index, RoomPropModel prop)? onPropChanged;
  final double bottomPadding;
  final int? selectedPropIndex;
  final Function(int index)? onPropDelete;
  final String? todaysMood;
  final Map<String, dynamic>? equippedCharacterItems;
  final int? visitorCharacterLevel;
  final Map<String, dynamic>? visitorEquippedItems;

  @override
  State<EnhancedCharacterRoomWidget> createState() =>
      _EnhancedCharacterRoomWidgetState();
}

class _EnhancedCharacterRoomWidgetState
    extends State<EnhancedCharacterRoomWidget>
    with SingleTickerProviderStateMixin {
  // ... (existing state variables) ...
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  bool _isTapped = false;
  Timer? _tapTimer;
  Timer? _wanderTimer;
  Timer? _movementStopTimer;
  double _horizontalPosition = 0.5;
  double _verticalPosition = 0.5;
  bool _isMoving = false;
  bool _isDragging = false;
  bool _isFalling = false;

  // Visitor state
  double _visitorHorizontalPosition = 0.3; // Start from left
  double _visitorVerticalPosition = 0.6;
  bool _visitorIsMoving = false;
  Timer? _visitorWanderTimer;
  Timer? _visitorMovementStopTimer;
  bool _isVisitorDragging = false;
  bool _isVisitorFalling = false;
  double? _visitorDragX;
  double? _visitorDragY;
  bool _isVisitorTapped = false;
  Timer? _visitorTapTimer;

  // 2D 화면 좌표 (0~1 정규화)
  double? _dragX;
  double? _dragY;

  // Background Caching
  Widget? _cachedBackgroundWidget;
  RoomDecorationModel? _cachedDecorationForBg;
  Size? _cachedSizeForBg;
  bool? _cachedAwakeForBg;

  // Prop Dragging State
  String? _activeDragPropId;
  double _startPropX = 0.0;
  double _startPropY = 0.0;
  double _startTouchX = 0.0;
  double _startTouchY = 0.0;

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

    // ?대?吏 誘몃━ 濡쒕뱶?섏뿬 源쒕묀??諛⑹?
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        precacheImage(
            ResizeImage(const AssetImage('assets/images/Face_Wink.png'),
                width: 300),
            context);
        precacheImage(
            ResizeImage(const AssetImage('assets/images/Face_Sleep.png'),
                width: 300),
            context);
        precacheImage(
            ResizeImage(const AssetImage('assets/images/Face_Drool.png'),
                width: 300),
            context);
        precacheImage(
            ResizeImage(const AssetImage('assets/images/Egg_Wing.png'),
                width: 300),
            context);
        precacheImage(
            ResizeImage(const AssetImage('assets/images/Egg_Wing2.png'),
                width: 300),
            context);
        precacheImage(
            ResizeImage(const AssetImage('assets/images/Egg_Wing3.png'),
                width: 300),
            context);
        precacheImage(
            ResizeImage(const AssetImage('assets/images/Egg_Wing4.png'),
                width: 300),
            context);

        _precacheCurrentDecoration();
      }
    });
  }

  void _precacheCurrentDecoration() {
    final decoration = widget.roomDecoration;
    if (decoration == null) return;

    // Precache Wallpaper
    if (decoration.wallpaperId != 'default') {
      final wallpaper = RoomAssets.wallpapers.firstWhere(
          (w) => w.id == decoration.wallpaperId,
          orElse: () => RoomAssets.wallpapers.first);
      if (wallpaper.imagePath != null) {
        precacheImage(AssetImage(wallpaper.imagePath!), context);
      }
    }

    // Precache Background
    if (decoration.backgroundId != 'default' &&
        decoration.backgroundId != 'none') {
      final background = RoomAssets.backgrounds.firstWhere(
          (b) => b.id == decoration.backgroundId,
          orElse: () => RoomAssets.backgrounds.first);
      if (background.imagePath != null) {
        precacheImage(AssetImage(background.imagePath!), context);
      }
    }

    // Precache Floor
    if (decoration.floorId != 'default') {
      final floor = RoomAssets.floors.firstWhere(
          (f) => f.id == decoration.floorId,
          orElse: () => RoomAssets.floors.first);
      if (floor.imagePath != null) {
        precacheImage(AssetImage(floor.imagePath!), context);
      }
    }

    // Precache Props
    for (var prop in decoration.props) {
      final asset = RoomAssets.props.firstWhere((p) => p.id == prop.type,
          orElse: () => RoomAssets.props.first);
      if (asset.imagePath != null) {
        precacheImage(AssetImage(asset.imagePath!), context);
      }
    }
  }

  void _move() {
    if (mounted && widget.isAwake) {
      setState(() {
        _isMoving = true;
        _horizontalPosition = 0.05 + Random().nextDouble() * 0.9;
        // 바닥 영역에서만 배회 (0.42 ~ 1.0)
        _verticalPosition = 0.42 + Random().nextDouble() * 0.58;
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

  void _moveVisitor() {
    if (mounted && widget.isAwake) {
      setState(() {
        _visitorIsMoving = true;
        _visitorHorizontalPosition = 0.1 + Random().nextDouble() * 0.8;
        _visitorVerticalPosition = 0.45 + Random().nextDouble() * 0.5;
      });

      _visitorMovementStopTimer?.cancel();
      _visitorMovementStopTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) {
          setState(() {
            _visitorIsMoving = false;
          });
        }
      });
    }
  }

  void _startVisitorWandering() {
    _visitorWanderTimer?.cancel();
    _visitorMovementStopTimer?.cancel();
    // Visitor follows their own logic, regardless of room awake status
    _moveVisitor();
    _visitorWanderTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      _moveVisitor();
    });
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

    // 0. Precache decoration if changed
    if (widget.roomDecoration != oldWidget.roomDecoration) {
      _precacheCurrentDecoration();
    }

    // 1. Main Character wandering logic
    if (widget.isAwake != oldWidget.isAwake) {
      if (widget.isAwake) {
        _startWandering();
      } else {
        _wanderTimer?.cancel();
        _movementStopTimer?.cancel();
        setState(() {
          _isMoving = false;
        });
      }
    }

    // 2. Visitor Character wandering logic (independent of isAwake)
    if (widget.visitorCharacterLevel != oldWidget.visitorCharacterLevel) {
      if (widget.visitorCharacterLevel != null) {
        _startVisitorWandering();
      } else {
        _visitorWanderTimer?.cancel();
        _visitorMovementStopTimer?.cancel();
        setState(() {
          _visitorIsMoving = false;
        });
      }
    } else if (widget.visitorCharacterLevel != null &&
        _visitorWanderTimer == null) {
      // Ensure wandering starts if visitor is present but timer isn't running
      _startVisitorWandering();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tapTimer?.cancel();
    _wanderTimer?.cancel();
    _movementStopTimer?.cancel();
    _visitorTapTimer?.cancel();
    _visitorWanderTimer?.cancel();
    _visitorMovementStopTimer?.cancel();
    super.dispose();
  }

  Widget _buildCachedBackground(
    double width,
    double height,
    double renderHeight,
    RoomDecorationModel decoration,
    AppColorScheme colorScheme,
  ) {
    if (_cachedBackgroundWidget != null &&
        _cachedSizeForBg == Size(width, height) &&
        _cachedAwakeForBg == widget.isAwake &&
        _cachedDecorationForBg?.wallpaperId == decoration.wallpaperId &&
        _cachedDecorationForBg?.floorId == decoration.floorId &&
        _cachedDecorationForBg?.backgroundId == decoration.backgroundId) {
      return _cachedBackgroundWidget!;
    }

    _cachedSizeForBg = Size(width, height);
    _cachedAwakeForBg = widget.isAwake;
    _cachedDecorationForBg = decoration;

    _cachedBackgroundWidget = Room3DBackground(
      isAwake: widget.isAwake,
      colorScheme: colorScheme,
      decoration: decoration, // Pass full decoration, but only IDs are used
      width: width,
      height: renderHeight,
      fullHeight: height,
      isDarkMode: widget.isDarkMode,
    );

    return _cachedBackgroundWidget!;
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
      final renderHeight = height - widget.bottomPadding;
      final size = width > renderHeight ? renderHeight : width;

      return Container(
        width: width,
        height: height,
        alignment: Alignment.topCenter,
        // Removed padding to allow floor to extend behind tab bar
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
          clipBehavior: Clip.none,
          children: [
            // 3D 룸 내부 (바닥, 벽, 천장 등)
            RepaintBoundary(
              child: SizedBox(
                width: width,
                height: height,
                child: _buildCachedBackground(
                  width,
                  height,
                  renderHeight,
                  decoration,
                  colorScheme,
                ),
              ),
            ),

            // Props (?쒖꽌?濡??뚮뜑留?- 由ъ뒪???앹씠 理쒖긽???덉씠??
            if (!widget.hideProps) ...[
              ...decoration.props.asMap().entries.map((entry) {
                return _isPropValid(entry.value)
                    ? _buildPropFor3D(
                        entry.value,
                        entry.key,
                        width,
                        renderHeight,
                        key: ValueKey(entry.value.id),
                      )
                    : const SizedBox.shrink();
              }),
            ],

            // Character
            _buildCharacterContainer3D(
                widget.isAwake, colorScheme, width, renderHeight),

            // Visitor Character
            if (widget.visitorCharacterLevel != null)
              _buildVisitorCharacterContainer3D(true, colorScheme, width,
                  renderHeight), // Visitant always awake

            // Night Overlay (Replaces morning_screen.dart backdrop & provides lighting)
            if (!widget.isAwake)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _NightOverlayPainter(
                      props: decoration.props,
                      width: width,
                      height: renderHeight,
                    ),
                  ),
                ),
              ),

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

  /// 3D 바닥에 Prop 배치 (피타고라스 좌표계)
  Widget _buildPropFor3D(
      RoomPropModel prop, int index, double width, double height,
      {Key? key}) {
    // Prop Dimensions with simple depth scaling
    final asset = RoomAssets.props.firstWhere(
      (p) => p.id == prop.type,
      orElse: () =>
          const RoomAsset(id: '', name: '', price: 0, icon: Icons.circle),
    );

    // Simple scale based on Y position for depth cue
    final scale = 0.7 + 0.4 * prop.y.clamp(0.0, 1.0);
    final baseSize = (width + height) * 0.08 * asset.sizeMultiplier * scale;
    final propWidth = baseSize * asset.aspectRatio;
    final propHeight = baseSize;

    // Direct 2D coordinate mapping (0~1 to screen size)
    final xPos = prop.x * width;
    final yPos = prop.y * height;

    // Visual Widget
    Widget propImage = _getPropVisual(prop.type, propWidth, propHeight);

    // Determine if shadow should be shown
    bool showShadow = !asset.isWallMounted &&
        prop.z != 1 &&
        !asset.noShadow; // z=1 implies 'above' or stacked

    Widget shadowLayer = showShadow
        ? Positioned(
            bottom: -propHeight * 0.05, // Closer to the prop
            child: Transform(
              transform: Matrix4.identity()
                ..scale(1.0, 0.3)
                ..setEntry(0, 1, -0.3)
                ..translate(-propWidth * 0.02, -propHeight * 0.15),
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: 0.2, // 그림자 농도 유지
                child: _getPropVisual(prop.type, propWidth, propHeight,
                    isShadow: true),
              ),
            ),
          )
        : const SizedBox.shrink();

    Widget visualChild = Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        shadowLayer,
        propImage,
      ],
    );

    // 1. Selection Visuals (Border + Delete Button)
    final isSelected =
        widget.isPropEditable && widget.selectedPropIndex == index;

    Widget mainContent = visualChild;

    if (isSelected) {
      mainContent = Stack(
        clipBehavior: Clip.none,
        children: [
          // Nice Dashed Selection Box
          CustomPaint(
            painter: _SelectedPropPainter(
              color:
                  (widget.colorScheme?.primaryButton ?? const Color(0xFF8B7355))
                      .withOpacity(0.8),
            ),
            child: Container(
              padding: const EdgeInsets.all(8), // Padding so border is outside
              child: visualChild,
            ),
          ),
          // X Button (Right Top)
          Positioned(
            top: -25, // Make it stick out more
            right: -25,
            child: GestureDetector(
              onTap: () {
                widget.onPropDelete?.call(index);
              },
              behavior:
                  HitTestBehavior.translucent, // Ensure touches are captured
              child: Container(
                padding: const EdgeInsets.all(12), // Increase touch area
                color: Colors.transparent,
                child: Image.asset(
                  'assets/icons/X_Button.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Wrap with GestureDetector
    Widget interactionWrapper;
    if (widget.isPropEditable) {
      interactionWrapper = GestureDetector(
        key: key,
        onTap: () => widget.onPropTap?.call(prop), // Select
        // 드래그 시작 시 초기 상태 저장 (stale closure 방지)
        onPanStart: (details) {
          if (!isSelected) {
            widget.onPropTap?.call(prop);
          }
          _activeDragPropId = prop.id;
          _startPropX = prop.x;
          _startPropY = prop.y;
          _startTouchX = details.globalPosition.dx;
          _startTouchY = details.globalPosition.dy;
        },
        onPanUpdate: (details) {
          if (widget.onPropChanged == null) return;
          // 다른 소품이 드래그 중이면 무시 (혹은 ID 체크)
          if (_activeDragPropId != prop.id) return;

          // 시작점 기준 변화량 계산 (closure state에 의존하지 않음)
          final dx = (details.globalPosition.dx - _startTouchX) / width;
          final dy = (details.globalPosition.dy - _startTouchY) / height;

          final newPx = (_startPropX + dx).clamp(0.0, 1.0);
          final newPy = (_startPropY + dy).clamp(0.0, 1.0);

          widget.onPropChanged!(index, prop.copyWith(x: newPx, y: newPy));
        },
        onPanEnd: (_) {
          _activeDragPropId = null;
        },
        child: mainContent,
      );
    } else {
      interactionWrapper = GestureDetector(
        key: key,
        onTap: () => widget.onPropTap?.call(prop),
        child: mainContent,
      );
    }

    // If selected, we need to allow the X button (which is outside bounds) to be hit-tested.
    // We add internal padding to the overall Positioned child to keep everything inside logical bounds.
    final double padding = isSelected ? 30.0 : 0.0;

    return Positioned(
      key: key,
      left: xPos - (propWidth / 2) - (isSelected ? 8 : 0) - padding,
      top: yPos - (propHeight / 2) - (isSelected ? 8 : 0) - padding,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: interactionWrapper,
      ),
    );
  }

  /// 캐릭터 컨테이너 (2D 화면 좌표 기반)
  Widget _buildCharacterContainer3D(
      bool isAwake, AppColorScheme colorScheme, double width, double height) {
    final charSize = (width + height) * 0.08;

    double currentLeft;
    double currentTop;

    if (_isDragging && _dragX != null && _dragY != null) {
      // 드래그 중: 화면 어디든 자유롭게 이동 (2D 좌표)
      currentLeft =
          (_dragX! * width - charSize / 2).clamp(0.0, width - charSize);
      currentTop = (_dragY! * height - charSize).clamp(0.0, height - charSize);
    } else {
      // 일반 상태: 바닥 영역에 3D 매핑
      final py = _verticalPosition.clamp(0.5, 1.0); // 바닥 영역만 (0.5 이상)
      final px = _horizontalPosition.clamp(0.05, 0.95);

      // 단순 2D 매핑 (바닥 영역)
      currentLeft = (px * width - charSize / 2).clamp(0.0, width - charSize);
      currentTop = (py * height - charSize + (isAwake ? 0 : charSize * 0.3))
          .clamp(height * 0.42 - charSize * 0.5, height - charSize);
    }

    return Stack(
      clipBehavior: Clip.none,
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
            onTap: widget.visitorCharacterLevel == null ? _handleTap : null,
            onPanStart: widget.visitorCharacterLevel == null
                ? (d) => _handleDragStart3D(d, width, height, charSize)
                : null,
            onPanUpdate: widget.visitorCharacterLevel == null
                ? (d) => _handleDragUpdate3D(d, width, height, charSize)
                : null,
            onPanEnd: widget.visitorCharacterLevel == null
                ? (d) => _handleDragEnd3D(d, width, height, charSize)
                : null,
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

                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Character with animation
                            Transform(
                              alignment: Alignment.bottomCenter,
                              transform: Matrix4.identity()
                                ..translate(0.0, verticalOffset)
                                ..scale(scaleX, scaleY),
                              child: CharacterDisplay(
                                isAwake: isAwake,
                                characterLevel: widget.characterLevel,
                                size: charSize,
                                isTapped: _isTapped,
                                enableAnimation: true,
                                equippedItems: widget.equippedCharacterItems,
                              ),
                            ),
                            // Mood Bubble
                            if (isAwake && widget.todaysMood != null)
                              Positioned(
                                top: -charSize * 0.6 + verticalOffset,
                                right: -charSize * 0.4,
                                child: _buildMoodBubble(
                                  widget.todaysMood!,
                                  charSize,
                                ),
                              ),
                          ],
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

  /// Visitor 캐릭터 컨테이너
  Widget _buildVisitorCharacterContainer3D(
      bool isAwake, AppColorScheme colorScheme, double width, double height) {
    final charSize = (width + height) * 0.08;

    double currentLeft;
    double currentTop;

    if (_isVisitorDragging && _visitorDragX != null && _visitorDragY != null) {
      // 드래그 중: 화면 어디든 자유롭게 이동
      currentLeft =
          (_visitorDragX! * width - charSize / 2).clamp(0.0, width - charSize);
      currentTop =
          (_visitorDragY! * height - charSize).clamp(0.0, height - charSize);
    } else {
      // 일반 상태: 바닥 영역에 3D 매핑
      final double py = _visitorVerticalPosition.clamp(0.5, 1.0);
      final px = _visitorHorizontalPosition.clamp(0.05, 0.95);

      currentLeft = (px * width - charSize / 2).clamp(0.0, width - charSize);
      currentTop = (py * height - charSize + (isAwake ? 0 : charSize * 0.3))
          .clamp(height * 0.42 - charSize * 0.5, height - charSize);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedPositioned(
          duration: _isVisitorDragging
              ? Duration.zero
              : (_isVisitorFalling
                  ? const Duration(milliseconds: 800)
                  : const Duration(milliseconds: 3500)),
          curve: _isVisitorFalling ? Curves.bounceOut : Curves.easeInOutQuart,
          left: currentLeft,
          top: currentTop,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // Ensure touches are captured
            onTap: _handleVisitorTap,
            onPanStart: (d) =>
                _handleVisitorDragStart3D(d, width, height, charSize),
            onPanUpdate: (d) =>
                _handleVisitorDragUpdate3D(d, width, height, charSize),
            onPanEnd: (d) =>
                _handleVisitorDragEnd3D(d, width, height, charSize),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _isVisitorTapped ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, tapValue, child) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0.15,
                    end: (isAwake && (_visitorIsMoving || _isVisitorTapped))
                        ? 1.0
                        : 0.15,
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
                          child: CharacterDisplay(
                            isAwake: isAwake,
                            characterLevel: widget.visitorCharacterLevel ?? 1,
                            size: charSize,
                            isTapped: _isVisitorTapped,
                            enableAnimation: true,
                            equippedItems: widget.visitorEquippedItems,
                          ),
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

  void _handleVisitorTap() {
    if (_isVisitorTapped) return;
    setState(() {
      _isVisitorTapped = true;
      _visitorIsMoving = true;
    });
    _visitorTapTimer?.cancel();
    _visitorTapTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isVisitorTapped = false;
          _visitorIsMoving = false;
        });
      }
    });
  }

  void _handleVisitorDragStart3D(
      DragStartDetails d, double width, double height, double charSize) {
    // if (!widget.isAwake) return; // Allow dragging even if room owner is sleeping
    _visitorWanderTimer?.cancel();
    _visitorMovementStopTimer?.cancel();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(d.globalPosition);

    final currentVisualLeft = localPos.dx - d.localPosition.dx;
    final currentVisualTop = localPos.dy - d.localPosition.dy;

    setState(() {
      _isVisitorDragging = true;
      _isVisitorFalling = false;
      _visitorIsMoving = true;

      _visitorDragX =
          ((currentVisualLeft + charSize / 2) / width).clamp(0.0, 1.0);
      _visitorDragY = ((currentVisualTop + charSize) / height).clamp(0.0, 1.0);
    });
  }

  void _handleVisitorDragUpdate3D(
      DragUpdateDetails d, double width, double height, double charSize) {
    if (!_isVisitorDragging) return;
    setState(() {
      _visitorDragX =
          ((_visitorDragX ?? 0.5) + d.delta.dx / width).clamp(0.0, 1.0);
      _visitorDragY =
          ((_visitorDragY ?? 0.5) + d.delta.dy / height).clamp(0.0, 1.0);
    });
  }

  void _handleVisitorDragEnd3D(
      DragEndDetails d, double width, double height, double charSize) {
    if (!_isVisitorDragging) return;

    final dropY = _visitorDragY ?? 0.5;
    final dropX = _visitorDragX ?? 0.5;

    final floorThreshold = 0.5;
    final wasOnFloor = _visitorVerticalPosition >= floorThreshold;
    final isDroppedOnFloor = dropY >= floorThreshold;

    setState(() {
      _isVisitorDragging = false;
      _visitorDragX = null;
      _visitorDragY = null;

      if (wasOnFloor && isDroppedOnFloor) {
        _isVisitorFalling = false;
        _visitorVerticalPosition = dropY.clamp(floorThreshold, 1.0);
        _visitorHorizontalPosition = dropX.clamp(0.05, 0.95);
        _visitorIsMoving = false;

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isVisitorDragging) {
            _startVisitorWandering();
          }
        });
      } else if (dropY < floorThreshold) {
        _isVisitorFalling = true;
        _visitorVerticalPosition = floorThreshold;
        _visitorHorizontalPosition = dropX.clamp(0.1, 0.9);

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _isVisitorFalling = false;
              _visitorIsMoving = false;
            });
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted && !_isVisitorDragging) {
                _startVisitorWandering();
              }
            });
          }
        });
      } else {
        _isVisitorFalling = true;
        _visitorVerticalPosition = dropY.clamp(floorThreshold, 1.0);
        _visitorHorizontalPosition = dropX.clamp(0.05, 0.95);

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _isVisitorFalling = false;
              _visitorIsMoving = false;
            });
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted && !_isVisitorDragging) {
                _startVisitorWandering();
              }
            });
          }
        });
      }
    });
  }

  void _handleDragStart3D(
      DragStartDetails d, double width, double height, double charSize) {
    if (!widget.isAwake) return;
    _wanderTimer?.cancel();
    _movementStopTimer?.cancel();

    // 현재 캐릭터의 실제 화면 위치를 기반으로 계산 (자체 이동 중 클릭 시 순간이동 방지)
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(d.globalPosition);

    // 터치 포인트를 기준으로 캐릭터의 위치를 역산
    // localPos: Container 기준 터치 좌표
    // d.localPosition: 캐릭터 Widget 기준 터치 좌표 (Top-Left 0,0)
    final currentVisualLeft = localPos.dx - d.localPosition.dx;
    final currentVisualTop = localPos.dy - d.localPosition.dy;

    setState(() {
      _isDragging = true;
      _isFalling = false;
      _isMoving = true;

      // 역산된 위치를 정규화 좌표(_dragX, _dragY)로 변환
      _dragX = ((currentVisualLeft + charSize / 2) / width).clamp(0.0, 1.0);
      _dragY = ((currentVisualTop + charSize) / height).clamp(0.0, 1.0);
    });
  }

  void _handleDragUpdate3D(
      DragUpdateDetails d, double width, double height, double charSize) {
    if (!_isDragging) return;
    setState(() {
      // 델타 값만 적용하여 캐릭터 이동
      _dragX = ((_dragX ?? 0.5) + d.delta.dx / width).clamp(0.0, 1.0);
      _dragY = ((_dragY ?? 0.5) + d.delta.dy / height).clamp(0.0, 1.0);
    });
  }

  void _handleDragEnd3D(
      DragEndDetails d, double width, double height, double charSize) {
    if (!_isDragging) return;

    final dropY = _dragY ?? 0.5;
    final dropX = _dragX ?? 0.5;

    // 바닥 영역 기준: 0.5 이상이 바닥
    final floorThreshold = 0.5;
    final wasOnFloor = _verticalPosition >= floorThreshold;
    final isDroppedOnFloor = dropY >= floorThreshold;

    setState(() {
      _isDragging = false;

      // 드래그 좌표 초기화 (다음 드래그를 위해)
      _dragX = null;
      _dragY = null;

      // 바닥에서 바닥으로 이동: 떨어지는 모션 없음
      if (wasOnFloor && isDroppedOnFloor) {
        _isFalling = false;
        _verticalPosition = dropY.clamp(floorThreshold, 1.0);
        _horizontalPosition = dropX.clamp(0.05, 0.95);
        _isMoving = false;

        // 바로 배회 재시작
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isDragging) {
            _startWandering();
          }
        });
      }
      // 벽 영역(0.5 미만)에서 놓으면 바닥으로 떨어짐
      else if (dropY < floorThreshold) {
        _isFalling = true;
        _verticalPosition = floorThreshold; // 바닥 맨 위로 떨어짐

        // 수평 위치는 드래그한 위치 유지 (안전하게 clamp)
        // 왼쪽 벽(x < 0.3)에서 놓으면 왼쪽 바닥으로
        // 오른쪽 벽(x > 0.7)에서 놓으면 오른쪽 바닥으로
        // 중앙 벽에서 놓으면 중앙 바닥으로
        _horizontalPosition = dropX.clamp(0.1, 0.9);

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _isFalling = false;
              _isMoving = false;
            });
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted && !_isDragging) {
                _startWandering();
              }
            });
          }
        });
      }
      // 바닥에서 벽으로 이동: 바닥으로 떨어짐
      else {
        _isFalling = true;
        _verticalPosition = dropY.clamp(floorThreshold, 1.0);
        _horizontalPosition = dropX.clamp(0.05, 0.95);

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _isFalling = false;
              _isMoving = false;
            });
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted && !_isDragging) {
                _startWandering();
              }
            });
          }
        });
      }
    });
  }

  Widget _getPropVisual(String type, double width, double height,
      {bool isShadow = false}) {
    if (type.isEmpty) return SizedBox(width: width, height: height);
    final asset = RoomAssets.props.firstWhere((p) => p.id == type,
        orElse: () =>
            const RoomAsset(id: '', name: '', price: 0, icon: Icons.circle));
    if (asset.id.isEmpty) return SizedBox(width: width, height: height);

    if (asset.imagePath != null) {
      Widget imageWidget = NetworkOrAssetImage(
        imagePath: asset.imagePath!,
        width: width * 0.9,
        height: height * 0.9,
        fit: BoxFit.contain,
        color: isShadow ? Colors.black : null,
        colorBlendMode: isShadow ? BlendMode.srcIn : null,
      );

      // 밤 모드 어두운 효과는 _NightOverlayPainter에서 일괄적으로 구멍을 뚫으면서 조명 처리됨
      if (isShadow) {
        // 호출부에서 Opacity 처리하므로 여기서는 색상만 변경.
      }

      return imageWidget;
    }

    return Icon(asset.icon,
        color: isShadow ? Colors.black : Colors.blueGrey,
        size: (width < height ? width : height) * 0.7);
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

  Widget _buildMoodBubble(String mood, double charSize) {
    Widget moodContent;

    switch (mood) {
      case 'happy':
        moodContent = Image.asset(
          'assets/imoticon/Imoticon_Happy.png',
          width: charSize * 0.4,
          height: charSize * 0.4,
          fit: BoxFit.contain,
        );
        break;
      case 'normal':
      case 'neutral':
        moodContent = Image.asset(
          'assets/imoticon/Imoticon_Normal.png',
          width: charSize * 0.4,
          height: charSize * 0.4,
          fit: BoxFit.contain,
        );
        break;
      case 'sad':
        moodContent = Image.asset(
          'assets/imoticon/Imoticon_Sad.png',
          width: charSize * 0.4,
          height: charSize * 0.4,
          fit: BoxFit.contain,
        );
        break;
      case 'love':
      case 'excited':
        moodContent = Image.asset(
          'assets/imoticon/Imoticon_Love.png',
          width: charSize * 0.4,
          height: charSize * 0.4,
          fit: BoxFit.contain,
        );
        break;
      case 'angry':
        moodContent = Image.asset(
          'assets/imoticon/Imoticon_Angry.png',
          width: charSize * 0.4,
          height: charSize * 0.4,
          fit: BoxFit.contain,
        );
        break;
      case 'awkward':
        moodContent = Image.asset(
          'assets/imoticon/Imoticon_Awkward.png',
          width: charSize * 0.4,
          height: charSize * 0.4,
          fit: BoxFit.contain,
        );
        break;
      case 'move':
        moodContent = Image.asset(
          'assets/imoticon/Imoticon_Move.png',
          width: charSize * 0.4,
          height: charSize * 0.4,
          fit: BoxFit.contain,
        );
        break;
      case 'sleep':
        moodContent = Image.asset(
          'assets/imoticon/Imoticon_Sleep.png',
          width: charSize * 0.4,
          height: charSize * 0.4,
          fit: BoxFit.contain,
        );
        break;
      default:
        String emoji = '📝';
        final emojiRegex = RegExp(
            r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
            unicode: true);
        if (emojiRegex.hasMatch(mood)) emoji = mood;
        moodContent = Text(
          emoji,
          style: TextStyle(
            fontSize: charSize * 0.25,
          ),
        );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: charSize * 0.8,
            height: charSize * 0.8,
            padding: EdgeInsets.only(bottom: charSize * 0.1), // 말풍선 꼬리 여백
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: ResizeImage(
                  AssetImage('assets/icons/Bubble_Icon.png'),
                  width: 150,
                ),
                fit: BoxFit.contain,
              ),
            ),
            child: moodContent,
          ),
        );
      },
    );
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
      ..moveTo(0, floorLeftY)
      ..lineTo(vLineX, hLineYBottom)
      ..lineTo(size.width, hLineYBottom)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class Room3DBackground extends StatelessWidget {
  final bool isAwake;
  final AppColorScheme colorScheme;
  final RoomDecorationModel decoration;
  final double width;
  final double height;
  final double fullHeight; // Added to extend floor
  final bool isDarkMode;

  const Room3DBackground({
    super.key,
    required this.isAwake,
    required this.colorScheme,
    required this.decoration,
    required this.width,
    required this.height,
    required this.fullHeight,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 치수 정의
    final hLineYTop = height * 0.15; // 천장 라인
    final hLineYBottom = height * 0.42; // 바닥 라인
    final vLineX = width * 0.32; // 코너 x좌표
    final floorLeftY = height * 0.60; // 바닥 왼쪽 끝

    // 왼쪽 벽의 실제 렌더링 너비를 화면 전체 너비만큼 확보하여
    // 회전 시 잘리지 않도록 함
    final leftW = vLineX;
    final frontW = width - vLineX;
    final wallH = hLineYBottom - hLineYTop;

    // 2. 자산 준비
    final floorAsset = RoomAssets.floors.firstWhere(
      (f) => f.id == decoration.floorId,
      orElse: () => RoomAssets.floors.first,
    );

    final wallpaperAsset = RoomAssets.wallpapers.firstWhere(
      (w) => w.id == decoration.wallpaperId,
      orElse: () => RoomAssets.wallpapers.first,
    );
    Color baseColor = wallpaperAsset.color ?? const Color(0xFFF5F5DC);
    // 야간에는 아주 살짝만 어둡게
    Color wallpaperColor = isAwake
        ? baseColor
        : Color.lerp(baseColor, Colors.black, 0.05) ?? baseColor;

    // 3. 공용 벽지 레이어 생성 (정면 + 왼쪽 "잇닿" 배치)
    final totalW = leftW + frontW;

    return Stack(
      children: [
        // 0. 기본 배경 (야간에도 너무 어둡지 않게)
        Positioned.fill(
          child: Container(
            color: isAwake ? const Color(0xFFF5F0E8) : const Color(0xFFEDE5DD),
          ),
        ),

        // 1. 천장 (Ceiling) - logical height 기준
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          height: height, // Up to logical height
          child: ClipPath(
            clipper: _CeilingClipper(
              hLineYTop: hLineYTop,
              vLineX: vLineX,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/Ceiling.png',
                    fit: BoxFit.cover,
                    cacheWidth: 540,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. 정면 벽 (Front Wall) - 텍스처의 오른쪽 부분 사용
        Positioned(
          left: vLineX,
          top: hLineYTop,
          width: frontW,
          height: wallH,
          child: Stack(
            children: [
              _buildWallSlice(
                sharedWallpaper: _buildSharedWallpaperLayer(
                  wallpaperAsset: wallpaperAsset,
                  wallpaperColor: wallpaperColor,
                  isAwake: isAwake,
                  totalWidth: totalW,
                  totalHeight: wallH,
                ),
                sliceX: leftW,
                sliceW: frontW,
                sliceH: wallH,
                totalWidth: totalW,
              ),
              // Top Boundary
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 2,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
              // Bottom Boundary
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 2,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
              // Left Boundary (Corner)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: 2,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ],
          ),
        ),

        // 3. 왼쪽 벽 (Left Wall) - 텍스처의 왼쪽 부분 사용 + 3D 회전
        Positioned(
          left: 0,
          top: hLineYTop,
          width: leftW,
          height: wallH,
          child: Transform(
            alignment: Alignment.centerRight, // 오른쪽(코너)를 축으로 회전
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(-1.475) // 더 많이 기울임
              ..scale(5.0, 1.0), // 기울기만큼만 확대
            child: Stack(
              children: [
                // 벽지 슬라이스
                _buildWallSlice(
                  sharedWallpaper: _buildSharedWallpaperLayer(
                    wallpaperAsset: wallpaperAsset,
                    wallpaperColor: wallpaperColor,
                    isAwake: isAwake,
                    totalWidth: totalW,
                    totalHeight: wallH,
                  ),
                  sliceX: 0,
                  sliceW: leftW,
                  sliceH: wallH,
                  totalWidth: totalW,
                ),
                // Top Boundary
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 2,
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
                // Bottom Boundary
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 2,
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
                // 창문 그림자
                Positioned(
                  left: leftW * 0.2 + 6,
                  top: wallH * 0.15 + 6,
                  width: leftW * 0.6,
                  height: wallH * 0.63,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // 창문 (벽면 변환을 그대로 따름)
                Positioned(
                  left: leftW * 0.2, // 벽 너비의 20% 지점
                  top: wallH * 0.15, // 벽 높이의 15% 지점
                  width: leftW * 0.65,
                  height: wallH * 0.7,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. 창 밖 풍경 (Background)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            12, 12, 12, 20), // 하단 패딩을 더 주어 바닥 부분 축소
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: RoomBackgroundWidget(
                            decoration: decoration,
                            isAwake: isAwake,
                            isDarkMode: isDarkMode,
                            colorScheme: colorScheme,
                          ),
                        ),
                      ),
                      // 2. 창문 프레임 + 커튼 이미지 (Overlay)
                      NetworkOrAssetImage(
                        imagePath:
                            'assets/images/backgrounds/WIndow_Curton.png',
                        fit: BoxFit.fill,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. 바닥 (Floor) - Physical full height까지 확장
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: 0, // Fill the full height SizedBox
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
                ..rotateX(-0.6), // 대각선 시야처럼 보이게 기울기 조정
              child: Container(
                decoration: BoxDecoration(
                  color: floorAsset.color ??
                      (isAwake
                          ? const Color(0xFFE8DCCF)
                          : const Color(0xFFDDD1C5)), // 더 밝은 바닥색
                  image: (floorAsset.imagePath != null &&
                          !floorAsset.imagePath!.endsWith('.svg'))
                      ? DecorationImage(
                          image: ResizeImage(
                            floorAsset.imagePath!.startsWith('http')
                                ? CachedNetworkImageProvider(
                                    floorAsset.imagePath!) as ImageProvider
                                : AssetImage(floorAsset.imagePath!)
                                    as ImageProvider,
                            width: 540,
                          ),
                          repeat: ImageRepeat.repeat,
                          alignment: Alignment.topCenter,
                          scale: 5.0,
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
                    // Top Shadow (Back wall shadow)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: height * 0.3, // 원근감 고려하여 그림자 길이 조정
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.5), // 투명도 증가
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Left Shadow (Left wall shadow)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      width: width * 0.3, // 그림자 너비 조정
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.5), // 투명도 증가
                              Colors.transparent,
                            ],
                          ),
                        ),
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

  /// 공용 벽지 레이어 (매끄러운 연결을 위해)
  Widget _buildSharedWallpaperLayer({
    required RoomAsset wallpaperAsset,
    required Color wallpaperColor,
    required bool isAwake,
    required double totalWidth,
    required double totalHeight,
  }) {
    final base = Container(
      child: wallpaperAsset.imagePath != null
          ? NetworkOrAssetImage(
              imagePath: wallpaperAsset.imagePath!,
              width: totalWidth,
              height: totalHeight,
              fit: BoxFit.fill,
            )
          : (wallpaperAsset.id == 'black_stripe'
              ? Stack(
                  children: List.generate(6, (index) {
                    return Positioned(
                      top: (index + 1) * (totalHeight / 7),
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1.2,
                        color: Colors.white.withOpacity(0.12),
                      ),
                    );
                  }),
                )
              : const SizedBox.shrink()),
    );

    return base;
  }

  /// 벽지 슬라이스 (특정 영역만 잘라내기)
  Widget _buildWallSlice({
    required Widget sharedWallpaper,
    required double sliceX, // 전체 벽지에서의 시작 X 위치
    required double sliceW,
    required double sliceH,
    required double totalWidth,
  }) {
    return ClipRect(
      child: Transform.translate(
        offset: Offset(-sliceX, 0), // 왼쪽으로 밀어서 해당 구간만 보이게 함
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: totalWidth,
          maxWidth: totalWidth,
          minHeight: sliceH,
          maxHeight: sliceH,
          child: sharedWallpaper,
        ),
      ),
    );
  }
}

class _SelectedPropPainter extends CustomPainter {
  final Color color;
  _SelectedPropPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 4.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NightOverlayPainter extends CustomPainter {
  final List<RoomPropModel> props;
  final double width;
  final double height;

  _NightOverlayPainter({
    required this.props,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 1. 전체 어두운 오버레이
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withOpacity(0.35),
    );

    // 2. 조명 부분 구멍 뚫기 및 따뜻한 광원 방출
    for (final prop in props) {
      final asset = RoomAssets.props.firstWhere((a) => a.id == prop.type,
          orElse: () =>
              const RoomAsset(id: '', name: '', price: 0, icon: Icons.circle));

      // isLight 속성이 없으면 패스
      if (!asset.isLight) continue;

      final xPos = prop.x * width;
      // prop의 바닥 기준점에서 위로 조금 올려 실제 빛이 나는 위치를 찾음
      final yPos = prop.y * height - (width + height) * 0.04;

      final double glowRadius =
          (width > height ? width : height) * 0.2 * asset.lightIntensity;
      final double brightnessMulti = asset.lightIntensity * 0.7; // 전체 밝기를 조금 낮춤

      // 뚫기 (dstOut) - 어두운 화면에 자연스러운 원형 구멍을 냄
      final punchHolePaint = Paint()
        ..blendMode = BlendMode.dstOut
        ..shader = RadialGradient(
          colors: [
            Colors.black.withOpacity(1.0 * brightnessMulti),
            Colors.black.withOpacity(0.8 * brightnessMulti),
            Colors.black.withOpacity(0.0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(
            Rect.fromCircle(center: Offset(xPos, yPos), radius: glowRadius));

      canvas.drawCircle(Offset(xPos, yPos), glowRadius, punchHolePaint);

      // 따뜻한 조명 색 더하기 (plus) - 밝아진 구멍 위에 한번 더 은은한 불빛 터치
      final glowLightPaint = Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFFACD).withOpacity(0.4 * brightnessMulti),
            const Color(0xFFFFE066).withOpacity(0.2 * brightnessMulti),
            const Color(0xFFFFB347).withOpacity(0.0),
          ],
          stops: const [0.0, 0.3, 1.0],
        ).createShader(Rect.fromCircle(
            center: Offset(xPos, yPos), radius: glowRadius * 1.5));

      canvas.drawCircle(Offset(xPos, yPos), glowRadius * 1.5, glowLightPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NightOverlayPainter oldDelegate) {
    return true; // 드래그 등으로 props 좌표가 변경될 수 있음
  }
}

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
    this.isPropEditable = false,
    this.onPropChanged,
    this.bottomPadding = 110.0,
    this.selectedPropIndex,
    this.onPropDelete,
  });

  final bool isPropEditable;
  final Function(int index, RoomPropModel prop)? onPropChanged;
  final double bottomPadding;
  final int? selectedPropIndex;
  final Function(int index)? onPropDelete;

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
  double? _dragBottom;
  double? _dragLeft;

  // ... (existing methods _handleTap, initState, etc - preserved by not including them in replacement if feasible, but I need to be careful with range)
  // I will skip to the _buildPropFor3D part since I am using MultiReplace or big chunk?
  // The tool is replace_file_content.
  // I need to replace the Constructor part first.
  // Then the _buildPropFor3D part.
  // I will use replace_file_content for constructor first.

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
      final renderHeight = height - widget.bottomPadding;
      final size = width > renderHeight ? renderHeight : width;

      return Container(
        width: width,
        height: height,
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(bottom: widget.bottomPadding),
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
                widget.isAwake, colorScheme, decoration, width, renderHeight),

            // Props
            if (!widget.hideProps)
              ...decoration.props.asMap().entries.map((entry) {
                final index = entry.key;
                final prop = entry.value;
                if (!_isPropValid(prop)) return const SizedBox.shrink();
                return _buildPropFor3D(prop, index, width, renderHeight);
              }),

            // Character
            _buildCharacterContainer3D(
                widget.isAwake, colorScheme, width, renderHeight),

            // Level Up Effect
            if (widget.currentAnimation == 'evolve') _buildLevelUpEffect(size),
          ],
        ),
      );
    });
  }

  Widget _build3DRoom(bool isAwake, AppColorScheme colorScheme,
      RoomDecorationModel decoration, double width, double height) {
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

    // 2. 에셋 준비
    final floorAsset = RoomAssets.floors.firstWhere(
      (f) => f.id == decoration.floorId,
      orElse: () => RoomAssets.floors.first,
    );

    final wallpaperAsset = RoomAssets.wallpapers.firstWhere(
      (w) => w.id == decoration.wallpaperId,
      orElse: () => RoomAssets.wallpapers.first,
    );
    Color baseColor = wallpaperAsset.color ?? const Color(0xFFF5F5DC);
    Color wallpaperColor = isAwake
        ? baseColor
        : Color.lerp(baseColor, Colors.black, 0.45) ?? baseColor;

    // 3. 공용 벽지 레이어 생성 (정면 + 왼쪽 "펼친" 크기)
    final totalW = leftW + frontW;
    final sharedWallpaper = _buildSharedWallpaperLayer(
      wallpaperAsset: wallpaperAsset,
      wallpaperColor: wallpaperColor,
      isAwake: isAwake,
      totalWidth: totalW,
      totalHeight: wallH,
    );

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
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/Ceiling.png',
                    fit: BoxFit.cover,
                  ),
                ),
                if (!isAwake)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.45),
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
                sharedWallpaper: sharedWallpaper,
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

        // 3. 좌측 벽 (Left Wall) - 텍스처의 왼쪽 부분 사용 + 3D 회전
        Positioned(
          left: 0,
          top: hLineYTop,
          width: leftW,
          height: wallH,
          child: Transform(
            alignment: Alignment.centerRight, // 오른쪽(코너)을 축으로 회전
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(-1.475) // 더 많이 기울임
              ..scale(5.0, 1.0), // 기울기만큼 폭 확대
            child: Stack(
              children: [
                // 벽지 슬라이스
                _buildWallSlice(
                  sharedWallpaper: sharedWallpaper,
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
                // Right Boundary (Corner)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: 2,
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
                // 창문 (벽면 변환을 그대로 따름)
                Positioned(
                  left: leftW * 0.2, // 벽 너비의 20% 지점
                  top: wallH * 0.15, // 벽 높이의 15% 지점
                  width: leftW * 0.65,
                  height: wallH * 0.7,
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
                ..rotateX(-0.6), // 대각선 시야처럼 보이게 기울기 조정
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
                      height: height * 0.3, // 원근감 고려하여 그림자 길이 확대
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
                      width: width * 0.3, // 그림자 너비 확대
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

  /// 공용 벽지 레이어 (펼쳐진 상태)
  Widget _buildSharedWallpaperLayer({
    required RoomAsset wallpaperAsset,
    required Color wallpaperColor,
    required bool isAwake,
    required double totalWidth,
    required double totalHeight,
  }) {
    final base = Container(
      color: wallpaperColor,
      child: wallpaperAsset.imagePath != null
          ? Image.asset(
              wallpaperAsset.imagePath!,
              width: totalWidth,
              height: totalHeight,
              fit: BoxFit.fill, // 전체 영역 꽉 채우기
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

    return Stack(
      children: [
        Positioned.fill(child: base),
        if (!isAwake)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),
      ],
    );
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
  Widget _buildPropFor3D(
      RoomPropModel prop, int index, double width, double height) {
    // Geometry Constants
    final hLineYBottom = height * 0.42; // Floor Top (Back Wall)
    final vLineX = width * 0.32;
    final floorLeftY = height * 0.60;

    // Prop Dimensions
    final asset = RoomAssets.props.firstWhere(
      (p) => p.id == prop.type,
      orElse: () =>
          const RoomAsset(id: '', name: '', price: 0, icon: Icons.circle),
    );
    final baseSize = (width + height) * 0.08 * asset.sizeMultiplier;
    final propWidth = baseSize * asset.aspectRatio;
    final propHeight = baseSize;

    // Coordinates (Relaxed Clamp 0.0 ~ 1.0)
    final py = prop.y.clamp(0.0, 1.0);
    final px = prop.x.clamp(0.0, 1.0);

    // Y Position (Depth)
    // 0 = Front (Bottom), 1 = Back (Top)
    final yPos = hLineYBottom + (1 - py) * (height - hLineYBottom);

    // X Boundaries at current Y
    double xLeft = 0;
    if (yPos < floorLeftY) {
      xLeft = vLineX * (floorLeftY - yPos) / (floorLeftY - hLineYBottom);
    } else {
      xLeft = 0;
    }
    final xRight = width;

    // X Position
    final xPos = xLeft + px * (xRight - xLeft) - propWidth / 2;

    // Visual Widget
    Widget child = _getPropVisual(prop.type, propWidth, propHeight);

    // 1. Selection Visuals (Border + Delete Button)
    final isSelected =
        widget.isPropEditable && widget.selectedPropIndex == index;
    if (isSelected) {
      child = Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: widget.colorScheme?.primaryButton ?? Colors.blue,
                  width: 2.0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: child,
          ),
          Positioned(
            top: -12,
            right: -12,
            child: GestureDetector(
              onTap: () => widget.onPropDelete?.call(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
                child:
                    const Icon(Icons.close, size: 14, color: Colors.redAccent),
              ),
            ),
          ),
        ],
      );
    }

    // 2. Interaction Logic
    if (widget.isPropEditable) {
      child = GestureDetector(
        onTap: () => widget.onPropTap?.call(prop), // Select
        // Select on generic touch down to improve responsiveness
        onPanStart: (_) => widget.onPropTap?.call(prop),
        onPanUpdate: (details) {
          if (widget.onPropChanged == null) return;

          // Inverse Logic
          // dy maps to d(py)
          // yPos = hLineYBottom + (1 - py) * (H - hLineYBottom)
          // dy = -d(py) * (H - hLineYBottom)
          // d(py) = -dy / (H - hLineYBottom)
          final dPy = -details.delta.dy / (height - hLineYBottom);
          final newPy = (prop.y + dPy).clamp(0.0, 1.0);

          // newPx calculation involves recalculating xLeft/xRight at newPy
          final newYPos = hLineYBottom + (1 - newPy) * (height - hLineYBottom);
          double newXLeft = 0;
          if (newYPos < floorLeftY) {
            newXLeft =
                vLineX * (floorLeftY - newYPos) / (floorLeftY - hLineYBottom);
          }
          final newXRight = width;
          final roomWidthAtY = newXRight - newXLeft;

          // dx maps to d(px)
          // xPos = xLeft + px * roomWidthAtY - w/2
          // dx = d(px) * roomWidthAtY
          // d(px) = dx / roomWidthAtY
          final dPx = details.delta.dx / (roomWidthAtY > 0 ? roomWidthAtY : 1);
          final newPx = (prop.x + dPx).clamp(0.0, 1.0);

          widget.onPropChanged!(index, prop.copyWith(x: newPx, y: newPy));
        },
        child: child,
      );
    } else {
      child = GestureDetector(
        onTap: () => widget.onPropTap?.call(prop),
        child: child,
      );
    }

    return Positioned(
      left: xPos,
      top: yPos - propHeight,
      child: child,
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

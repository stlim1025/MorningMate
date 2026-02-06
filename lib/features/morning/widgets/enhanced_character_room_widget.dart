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
    this.selectedPropIndex,
    this.onPropDelete,
    this.todaysMood,
    this.bottomPadding = 0,
  });

  final bool isPropEditable;
  final Function(int index, RoomPropModel prop)? onPropChanged;
  final double bottomPadding;
  final int? selectedPropIndex;
  final Function(int index)? onPropDelete;
  final String? todaysMood;

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

  // 2D 화면 좌표 (0~1 정규화)
  double? _dragX;
  double? _dragY;

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

  void _startWandering() {
    _wanderTimer?.cancel();
    _movementStopTimer?.cancel();
    if (widget.isAwake) {
      // 利됱떆 泥?踰덉㎏ ?대룞 ?쒖옉
      _move();
      // ?댄썑 6珥덈쭏??諛섎났 ?대룞
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
            // 3D 諛??대? (諛붾떏, 踰? 李쎈Ц)
            _build3DRoom(
                widget.isAwake, colorScheme, decoration, width, renderHeight),

            // Props (?쒖꽌?濡??뚮뜑留?- 由ъ뒪???앹씠 理쒖긽???덉씠??
            if (!widget.hideProps) ...[
              ...decoration.props.asMap().entries.map((entry) {
                return _isPropValid(entry.value)
                    ? _buildPropFor3D(
                        entry.value, entry.key, width, renderHeight)
                    : const SizedBox.shrink();
              }),
            ],

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
    // 1. 移섏닔 ?뺤쓽
    final hLineYTop = height * 0.15; // 泥쒖옣 ?쇱씤
    final hLineYBottom = height * 0.42; // 諛붾떏 ?쇱씤
    final vLineX = width * 0.32; // 肄붾꼫 x醫뚰몴
    final floorLeftY = height * 0.60; // 諛붾떏 ?쇱そ ??

    // ?쇱そ 踰쎌쓽 ?ㅼ젣 ?뚮뜑留??덈퉬瑜??붾㈃ ?꾩껜 ?덈퉬留뚰겮 ?뺣낫?섏뿬
    // ?뚯쟾 ???섎━吏 ?딅룄濡???
    final leftW = vLineX;
    final frontW = width - vLineX;
    final wallH = hLineYBottom - hLineYTop;

    // 2. ?먯뀑 以鍮?
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
    final sharedWallpaper = _buildSharedWallpaperLayer(
      wallpaperAsset: wallpaperAsset,
      wallpaperColor: wallpaperColor,
      isAwake: isAwake,
      totalWidth: totalW,
      totalHeight: wallH,
    );

    return Stack(
      children: [
        // 0. 기본 배경 (야간에도 너무 어둡지 않게)
        Positioned.fill(
          child: Container(
            color: isAwake ? const Color(0xFFF5F0E8) : const Color(0xFFEDE5DD),
          ),
        ),

        // 1. 泥쒖옣 (Ceiling)
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
                // 야간 모드 천장 오버레이 제거 (색상 조정만 사용)
              ],
            ),
          ),
        ),

        // 2. ?뺣㈃ 踰?(Front Wall) - ?띿뒪泥섏쓽 ?ㅻⅨ履?遺遺??ъ슜
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

        // 3. 醫뚯륫 踰?(Left Wall) - ?띿뒪泥섏쓽 ?쇱そ 遺遺??ъ슜 + 3D ?뚯쟾
        Positioned(
          left: 0,
          top: hLineYTop,
          width: leftW,
          height: wallH,
          child: Transform(
            alignment: Alignment.centerRight, // ?ㅻⅨ履?肄붾꼫)??異뺤쑝濡??뚯쟾
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(-1.475) // ??留롮씠 湲곗슱??
              ..scale(5.0, 1.0), // 湲곗슱湲곕쭔?????뺣?
            child: Stack(
              children: [
                // 踰쎌? ?щ씪?댁뒪
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
                // 李쎈Ц (踰쎈㈃ 蹂?섏쓣 洹몃?濡??곕쫫)
                Positioned(
                  left: leftW * 0.2, // 踰??덈퉬??20% 吏??
                  top: wallH * 0.15, // 踰??믪씠??15% 吏??
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

        // 4. 諛붾떏 (Floor)
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
                ..setEntry(3, 2, 0.001) // ?먭렐媛?理쒖쟻??
                ..rotateX(-0.6), // ?媛곸꽑 ?쒖빞泥섎읆 蹂댁씠寃?湲곗슱湲?議곗젙
              child: Container(
                decoration: BoxDecoration(
                  color: floorAsset.color ??
                      (isAwake
                          ? const Color(0xFFE8DCCF)
                          : const Color(0xFFDDD1C5)), // 더 밝은 바닥색
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
                      height: height * 0.3, // ?먭렐媛?怨좊젮?섏뿬 洹몃┝??湲몄씠 ?뺣?
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.5), // ?щ챸??利앷?
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
                      width: width * 0.3, // 洹몃┝???덈퉬 ?뺣?
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.5), // ?щ챸??利앷?
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 야간 모드 바닥 오버레이 제거 (색상 조정만 사용)
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 怨듭슜 踰쎌? ?덉씠??(?쇱퀜吏??곹깭)
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
              fit: BoxFit.fill, // ?꾩껜 ?곸뿭 苑?梨꾩슦湲?
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

    // 야간 모드 오버레이 제거 (색상 조정만 사용)
    return base;
  }

  /// 踰쎌? ?щ씪?댁뒪 (?뱀젙 ?곸뿭留??섎씪?닿린)
  Widget _buildWallSlice({
    required Widget sharedWallpaper,
    required double sliceX, // ?꾩껜 踰쎌??먯꽌???쒖옉 X ?꾩튂
    required double sliceW,
    required double sliceH,
    required double totalWidth,
  }) {
    return ClipRect(
      child: Transform.translate(
        offset: Offset(-sliceX, 0), // ?쇱そ?쇰줈 諛?댁꽌 ?대떦 援ш컙留?蹂댁씠寃???
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

  /// 3D 諛붾떏??Prop 諛곗튂 (?щ떎由ш섦 醫뚰몴怨?
  Widget _buildPropFor3D(
      RoomPropModel prop, int index, double width, double height) {
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

          // Simple 2D drag: convert screen delta to normalized coordinates
          final dPx = details.delta.dx / width;
          final dPy = details.delta.dy / height;

          final newPx = (prop.x + dPx).clamp(0.0, 1.0);
          final newPy = (prop.y + dPy).clamp(0.0, 1.0);

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
      left: xPos - propWidth / 2,
      top: yPos - propHeight / 2,
      child: child,
    );
  }

  /// 캐릭터 컨테이너 (2D 화면 좌표 기반)
  Widget _buildCharacterContainer3D(
      bool isAwake, AppColorScheme colorScheme, double width, double height) {
    final hLineYBottom = height * 0.42;
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
          .clamp(hLineYBottom - charSize * 0.5, height - charSize);
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
                              child: _buildCharacter(
                                  isAwake, colorScheme, charSize),
                            ),
                            // Mood Bubble (따라 움직이도록 verticalOffset 적용)
                            if (widget.todaysMood != null && isAwake)
                              Positioned(
                                top: -charSize * 0.6 +
                                    verticalOffset, // 애니메이션 적용
                                right: -charSize * 0.4,
                                child: _buildMoodBubble(
                                    widget.todaysMood!, charSize),
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

  void _handleDragStart3D(
      DragStartDetails d, double width, double height, double charSize) {
    if (!widget.isAwake) return;
    _wanderTimer?.cancel();
    _movementStopTimer?.cancel();

    // 현재 캐릭터의 실제 화면 위치를 역산
    // _buildCharacterContainer3D의 렌더링 로직과 동일하게 계산
    final hLineYBottom = height * 0.42;
    final py = _verticalPosition.clamp(0.5, 1.0);
    final px = _horizontalPosition.clamp(0.05, 0.95);

    // 화면상 캐릭터 중심 위치 계산 (렌더링 로직 역산)
    final currentLeft =
        (px * width - charSize / 2).clamp(0.0, width - charSize);
    final currentTop = (py * height - charSize)
        .clamp(hLineYBottom - charSize * 0.5, height - charSize);

    // 화면 위치를 정규화 좌표로 변환 (캐릭터 중심 기준)
    final screenCenterX = currentLeft + charSize / 2;
    final screenCenterY = currentTop + charSize;

    setState(() {
      _isDragging = true;
      _isFalling = false;
      _isMoving = true;
      // 실제 화면 위치를 정규화하여 드래그 시작점으로 사용
      _dragX = (screenCenterX / width).clamp(0.0, 1.0);
      _dragY = (screenCenterY / height).clamp(0.0, 1.0);
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

  Widget _getPropVisual(String type, double width, double height) {
    if (type.isEmpty) return SizedBox(width: width, height: height);
    final asset = RoomAssets.props.firstWhere((p) => p.id == type,
        orElse: () =>
            const RoomAsset(id: '', name: '', price: 0, icon: Icons.circle));
    if (asset.id.isEmpty) return SizedBox(width: width, height: height);

    if (asset.imagePath != null) {
      Widget imageWidget = asset.imagePath!.endsWith('.svg')
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
            );

      // 잠들어있을 때 아주 살짝만 어둡게 처리
      if (!widget.isAwake) {
        imageWidget = ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.08),
            BlendMode.darken,
          ),
          child: Opacity(
            opacity: 0.95,
            child: imageWidget,
          ),
        );
      }

      return imageWidget;
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

  Widget _buildMoodBubble(String mood, double charSize) {
    // 이모티콘 맵핑 (ArchiveScreen과 일치)
    String getMoodEmoji(String mood) {
      if (mood.isEmpty) return '📝';
      final emojiRegex = RegExp(
          r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
          unicode: true);
      if (emojiRegex.hasMatch(mood)) return mood;
      switch (mood) {
        case 'happy':
          return '😊';
        case 'neutral':
          return '😐';
        case 'sad':
          return '😢';
        case 'excited':
          return '🤩';
        default:
          return '📝';
      }
    }

    final emoji = getMoodEmoji(mood);

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
                image: AssetImage('assets/icons/Bubble_Icon.png'),
                fit: BoxFit.contain,
              ),
            ),
            child: Text(
              emoji,
              style: TextStyle(
                fontSize: charSize * 0.25,
              ),
            ),
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

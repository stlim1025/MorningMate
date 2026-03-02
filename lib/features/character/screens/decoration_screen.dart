import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/constants/room_assets.dart';
import '../controllers/character_controller.dart';
import '../../morning/controllers/morning_controller.dart';
import '../../morning/widgets/enhanced_character_room_widget.dart';

import '../../../data/models/room_decoration_model.dart';
import '../../../core/services/asset_precache_service.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../services/asset_service.dart';

class DecorationScreen extends StatefulWidget {
  const DecorationScreen({super.key});

  @override
  State<DecorationScreen> createState() => _DecorationScreenState();
}

class _DecorationScreenState extends State<DecorationScreen>
    with SingleTickerProviderStateMixin {
  late ValueNotifier<RoomDecorationModel> _decorationNotifier;
  String _selectedCategory = 'props'; // 초기 탭을 소품으로 변경
  int? _selectedPropIndex; // Track selected prop for editing

  bool _isPanelExpanded = false; // Track panel state
  bool _isOwnedOnly = false; // 구매한 상품만 보기 필터
  bool? _previewIsAwake;
  late List<String> _selectedEmoticonIds;

  final List<String> _categories = [
    'props',
    'wallpaper',
    'floor',
    'background',
    'window',
    'emoticon'
  ];
  int _currentIndex = 0;
  late PageController _pageController;

  late AnimationController _removeAllButtonController;
  late Animation<double> _removeAllScaleAnimation;

  Future<String?> _showStickyNoteInput(BuildContext context) async {
    final controller = TextEditingController();

    try {
      return await AppDialog.show<String>(
        context: context,
        key: AppDialogKey.writeMemo,
        content: PopupTextField(
          autofocus: true,
          controller: controller,
          fontFamily: 'KyoboHandwriting2024psw',
          hintText: AppLocalizations.of(context)?.get('stickyNoteHint') ??
              'Leave a short message',
          maxLength: 50,
          maxLines: 3,
        ),
        actions: [
          AppDialogAction(
            label: AppLocalizations.of(context)?.get('cancel') ?? 'Cancel',
            onPressed: (context) => Navigator.pop(context),
          ),
          AppDialogAction(
            label: '5',
            labelWidget: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/branch.png',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 6),
                const Text(
                  '5',
                  style: TextStyle(
                    fontFamily: 'BMJUA',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            isPrimary: true,
            isEnabled: ValueNotifier<bool>(
                (context.read<CharacterController>().currentUser?.points ??
                        0) >=
                    5),
            onPressed: (context) => Navigator.pop(context, controller.text),
          ),
        ],
      );
    } finally {
      // 팝업 닫힘 애니메이션(약 200ms)이 끝난 뒤 해제하여 'disposed controller' 에러 방지
      Future.delayed(const Duration(milliseconds: 300), () {
        controller.dispose();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final controller = context.read<CharacterController>();

    _removeAllButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    // 방꾸미기 화면 진입 시 최신 에셋 로드 (원격 이미지 등)
    AssetService().fetchDynamicAssets().then((_) {
      if (mounted) setState(() {});
    });

    _removeAllScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
          parent: _removeAllButtonController, curve: Curves.easeInOut),
    );

    var initialDecoration =
        controller.currentUser?.roomDecoration ?? RoomDecorationModel();
    // Validate Props
    final validProps = initialDecoration.props
        .where((p) => RoomAssets.props.any((asset) => asset.id == p.type))
        .toList();
    if (validProps.length != initialDecoration.props.length) {
      initialDecoration = initialDecoration.copyWith(props: validProps);
    }
    _selectedEmoticonIds =
        List<String>.from(controller.currentUser?.activeEmoticonIds ?? []);
    _decorationNotifier = ValueNotifier<RoomDecorationModel>(initialDecoration);
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AssetPrecacheService().precacheCategory(context, _selectedCategory);
    });
  }

  @override
  void dispose() {
    _removeAllButtonController.dispose();
    _pageController.dispose();
    _decorationNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    // 저장 시 리빌드로 인한 pop 오류 방지를 위해 watch -> read로 변경
    // 이 화면에서는 실시간 유저 정보 변경 반영보다 안정적인 저장이 더 중요함
    final characterController = context.read<CharacterController>();
    final morningController = context.watch<MorningController>();
    final user = characterController.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Initialize preview state
    _previewIsAwake ??= morningController.hasDiaryToday;
    final isAwakePreview = _previewIsAwake!;

    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    // Panel Configuration
    final double panelHeight =
        screenSize.height * 0.35; // Take up about 1/3 of screen height
    final double visibleHeaderHeight =
        EnhancedCharacterRoomWidget.roomStandardBottomPadding;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Image.asset(
            'assets/icons/X_Button.png',
            width: 40,
            height: 40,
          ),
        ),
        title: Text(
          AppLocalizations.of(context)?.get('decorateRoom') ?? 'Decorate Room',
          style: const TextStyle(
            color: Color(0xFF4E342E),
            fontWeight: FontWeight.bold,
            fontFamily: 'BMJUA',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: _handleSave,
              child: Container(
                width: 70,
                height: 35,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Confirm_Button.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  AppLocalizations.of(context)?.get('save') ?? 'Save',
                  style: const TextStyle(
                    color: Color(0xFF5D4E37),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'BMJUA',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Full Screen Room Preview
          Positioned.fill(
            child: ValueListenableBuilder<RoomDecorationModel>(
              valueListenable: _decorationNotifier,
              builder: (context, decoration, child) {
                return EnhancedCharacterRoomWidget(
                  isAwake: isAwakePreview,
                  characterLevel:
                      characterController.currentUser?.characterLevel ?? 1,
                  consecutiveDays:
                      characterController.currentUser?.displayConsecutiveDays ??
                          0,
                  roomDecoration: decoration,
                  hideProps: false,
                  showBorder: false,
                  bottomPadding:
                      EnhancedCharacterRoomWidget.roomStandardBottomPadding,
                  equippedCharacterItems:
                      characterController.currentUser?.equippedCharacterItems,
                  currentAnimation: characterController.currentAnimation,
                  isPropEditable: true,
                  selectedPropIndex: _selectedPropIndex,
                  onPropChanged: (index, newProp) {
                    final currentProps = _decorationNotifier.value.props;
                    final actualIndex =
                        currentProps.indexWhere((p) => p.id == newProp.id);
                    if (actualIndex != -1) {
                      final newProps = List<RoomPropModel>.from(currentProps);
                      newProps[actualIndex] = newProp;
                      _decorationNotifier.value =
                          _decorationNotifier.value.copyWith(props: newProps);
                    }
                  },
                  onPropTap: (prop) {
                    final currentProps = _decorationNotifier.value.props;
                    final index =
                        currentProps.indexWhere((p) => p.id == prop.id);
                    if (index != -1) {
                      final newProps = List<RoomPropModel>.from(currentProps);

                      if (index == currentProps.length - 1 &&
                          _selectedPropIndex == index) {
                        // Already selected and on top -> Deselect
                        final selectedProp = newProps.removeAt(index);
                        newProps.insert(
                            0, selectedProp); // Move to back? Or just keep it.
                        // Usually 'move to back' logic was here.
                        // Let's keep the existing logic:
                        _decorationNotifier.value =
                            _decorationNotifier.value.copyWith(props: newProps);
                        setState(() {
                          _selectedPropIndex = null;
                        });
                      } else {
                        // Select and bring to front
                        final selectedProp = newProps.removeAt(index);
                        newProps.add(selectedProp);
                        _decorationNotifier.value =
                            _decorationNotifier.value.copyWith(props: newProps);
                        setState(() {
                          _selectedPropIndex = newProps.length - 1;
                        });
                      }
                    }
                  },
                  onPropDelete: (index) async {
                    final prop = decoration.props[index];
                    if (prop.type == 'sticky_note') {
                      final confirm = await AppDialog.show<bool>(
                        context: context,
                        key: AppDialogKey.deleteStickyNote,
                      );
                      if (confirm != true) return;
                    }

                    final newProps = List<RoomPropModel>.from(decoration.props);
                    newProps.removeAt(index);
                    _decorationNotifier.value =
                        decoration.copyWith(props: newProps);
                    setState(() {
                      _selectedPropIndex = null;
                    });
                  },
                );
              },
            ),
          ),

          // 1.5. Night Mode Overlay (Darken room when sleeping)
          // 이제 EnhancedCharacterRoomWidget 내부에서 광원 효과와 함께 처리됩니다.

          // 2. Draggable Decoration Panel (Sliding Up/Down)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: _isPanelExpanded ? 0 : -(panelHeight - visibleHeaderHeight),
            height: panelHeight + bottomInset,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -5) {
                  setState(() => _isPanelExpanded = true);
                } else if (details.primaryDelta! > 5) {
                  setState(() => _isPanelExpanded = false);
                }
              },
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: ResizeImage(
                        AssetImage(
                            'assets/images/DecorationList_Background.png'),
                        width: 1080),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _isPanelExpanded = !_isPanelExpanded);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 0),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorScheme.shadowColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    _buildCategoryTabs(colorScheme),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              (Theme.of(context).platform == TargetPlatform.iOS
                                      ? 5.0
                                      : 15.0) +
                                  bottomInset,
                        ),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _categories.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                              _selectedCategory = _categories[index];
                            });
                            AssetPrecacheService()
                                .precacheCategory(context, _categories[index]);
                          },
                          itemBuilder: (context, index) {
                            return _buildCategoryContentByIndex(
                                index, user, colorScheme);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Day/Night Preview Toggle Button (Fixed Position)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _previewIsAwake = !isAwakePreview;
                });
              },
              child: Image.asset(
                isAwakePreview
                    ? 'assets/icons/Day_Toggle.png'
                    : 'assets/icons/Night_Toggle.png',
                width: 60,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 4a. Show Owned Only Checkbox (between Remove All and Memo)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: (_isPanelExpanded ? panelHeight : visibleHeaderHeight) +
                bottomInset +
                15,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isOwnedOnly = !_isOwnedOnly;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: _isOwnedOnly
                          ? Image.asset(
                              'assets/images/Check_Icon.png',
                              width: 22,
                              height: 22,
                              fit: BoxFit.contain,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                border: Border.all(
                                  color: isAwakePreview
                                      ? const Color(0xFF5D4037)
                                      : Colors.white70,
                                  width: 1.5,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)?.get('showOwnedOnly') ??
                          'Show Owned Only',
                      style: TextStyle(
                        fontFamily: 'BMJUA',
                        fontSize: 12,
                        color: isAwakePreview
                            ? const Color(0xFF5D4037)
                            : Colors.white,
                        shadows: isAwakePreview
                            ? [
                                const Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.white,
                                ),
                              ]
                            : [
                                Shadow(
                                  offset: const Offset(1, 1),
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Remove All Props Button (follows panel animation)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: (_isPanelExpanded ? panelHeight : visibleHeaderHeight) +
                bottomInset +
                10,
            left: 20,
            child: GestureDetector(
              onTapDown: (_) => _removeAllButtonController.forward(),
              onTapUp: (_) {
                _removeAllButtonController.reverse();
                final currentDecoration = _decorationNotifier.value;
                if (currentDecoration.props.isNotEmpty) {
                  _decorationNotifier.value =
                      currentDecoration.copyWith(props: []);
                  setState(() {
                    _selectedPropIndex = null;
                  });
                }
              },
              onTapCancel: () => _removeAllButtonController.reverse(),
              behavior: HitTestBehavior.opaque,
              child: ScaleTransition(
                scale: _removeAllScaleAnimation,
                child: Container(
                  width: 80,
                  height: 35,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/Message_Button.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.get('removeAllProps') ??
                        'Remove All',
                    style: const TextStyle(
                      fontFamily: 'BMJUA',
                      fontSize: 14,
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 5. Sticky Note Button (Fixed Position)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: (_isPanelExpanded ? panelHeight : visibleHeaderHeight) +
                bottomInset +
                10,
            right: 20,
            child: GestureDetector(
              onTap: _handleStickyNoteButton,
              child: Container(
                width: 80,
                height: 35,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Message_Button.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/items/StickyNote.png',
                      width: 18,
                      height: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)?.get('memo') ?? 'Memo',
                      style: const TextStyle(
                        fontFamily: 'BMJUA',
                        fontSize: 14,
                        color: Color(0xFF5D4037),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    final characterController = context.read<CharacterController>();
    // 최신 유저 정보를 가져오기 위해 갱신된 currentUser를 사용
    var user = characterController.currentUser;
    if (user == null) return;

    final decoration = _decorationNotifier.value;

    // 1. 미구매 상품 수집 (저장 전 체크)
    final List<RoomAsset> unownedItems = [];

    // 배경
    if (decoration.backgroundId != 'default' &&
        !user.purchasedBackgroundIds.contains(decoration.backgroundId)) {
      final item = RoomAssets.backgrounds
          .where((b) => b.id == decoration.backgroundId)
          .firstOrNull;
      if (item != null) unownedItems.add(item);
    }

    // 벽지
    if (decoration.wallpaperId != 'default' &&
        !user.purchasedThemeIds.contains(decoration.wallpaperId)) {
      final item = RoomAssets.wallpapers
          .where((w) => w.id == decoration.wallpaperId)
          .firstOrNull;
      if (item != null) unownedItems.add(item);
    }

    // 바닥
    if (!user.purchasedFloorIds.contains(decoration.floorId)) {
      final item = RoomAssets.floors
          .where((f) => f.id == decoration.floorId)
          .firstOrNull;
      if (item != null) unownedItems.add(item);
    }

    // 창문
    if (decoration.windowId != 'default' &&
        !user.purchasedWindowIds.contains(decoration.windowId)) {
      final item = RoomAssets.windows
              .where((w) => w.id == decoration.windowId)
              .firstOrNull ??
          RoomAssets.props
              .where(
                  (p) => p.id == decoration.windowId && p.category == 'window')
              .firstOrNull;
      if (item != null) unownedItems.add(item);
    }

    // 소품
    for (final prop in decoration.props) {
      if (prop.type == 'sticky_note') continue;
      if (!user.purchasedPropIds.contains(prop.type)) {
        final item =
            RoomAssets.props.where((p) => p.id == prop.type).firstOrNull;
        if (item != null && !unownedItems.any((u) => u.id == item.id)) {
          unownedItems.add(item);
        }
      }
    }

    // 이모티콘
    for (final emoticonId in _selectedEmoticonIds) {
      if (!user.purchasedEmoticonIds.contains(emoticonId)) {
        final item =
            RoomAssets.emoticons.where((e) => e.id == emoticonId).firstOrNull;
        if (item != null && !unownedItems.any((u) => u.id == item.id)) {
          unownedItems.add(item);
        }
      }
    }

    // 2. 미구매 상품이 없으면 바로 저장
    if (unownedItems.isEmpty) {
      try {
        await characterController.updateActiveEmoticons(
            user.uid, _selectedEmoticonIds);
        await characterController.updateRoomDecoration(user.uid, decoration);
        if (mounted) {
          MemoNotification.show(
              context,
              AppLocalizations.of(context)?.get('decorationSaved') ??
                  'Settings saved! ✨');
          // 내비게이션 안정성을 위해 미세한 지연 후 pop
          await Future.delayed(Duration.zero);
          if (mounted && Navigator.of(context).canPop()) {
            context.pop();
          }
        }
      } catch (e) {
        if (mounted) {
          MemoNotification.show(
            context,
            AppLocalizations.of(context)?.getFormat('saveFailed',
                    {'error': e.toString().replaceFirst('Exception: ', '')}) ??
                'Save failed: ${e.toString().replaceFirst('Exception: ', '')}',
          );
        }
      }
      return;
    }

    // 3. 미보유 아이템 제외 저장 확인 팝업
    if (!mounted) return;

    final shouldSave = await AppDialog.show<bool>(
      context: context,
      key: AppDialogKey.purchase,
      content: Text(
        AppLocalizations.of(context)?.get('unownedItemsWarning') ??
            '배치된 항목 중 아직 보유하지 않은 아이템이 있어요!\n미보유 아이템은 상점에서 획득할 수 있습니다.\n뺀 상태로 저장할까요?',
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'BMJUA', fontSize: 14),
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? 'Cancel',
          onPressed: (context) => Navigator.pop(context, false),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('confirm') ?? 'Confirm',
          isPrimary: true,
          onPressed: (context) => Navigator.pop(context, true),
        ),
      ],
    );

    if (shouldSave == true) {
      try {
        // 다시 최신 상태 확인 (팝업 떠있는 동안 변화 가능성)
        user = characterController.currentUser ?? user;
        final unownedIds = unownedItems.map((e) => e.id).toSet();

        var finalDecoration = _decorationNotifier.value;

        // 배경: 미보유 시 기본으로
        if (unownedIds.contains(finalDecoration.backgroundId)) {
          finalDecoration = finalDecoration.copyWith(backgroundId: 'default');
        }
        // 벽지
        if (unownedIds.contains(finalDecoration.wallpaperId)) {
          finalDecoration = finalDecoration.copyWith(wallpaperId: 'default');
        }
        // 바닥
        if (unownedIds.contains(finalDecoration.floorId)) {
          finalDecoration = finalDecoration.copyWith(floorId: 'wood');
        }
        // 창문
        if (unownedIds.contains(finalDecoration.windowId)) {
          finalDecoration = finalDecoration.copyWith(windowId: 'default');
        }
        // 소품
        final cleanedProps = finalDecoration.props
            .where((p) => !unownedIds.contains(p.type))
            .toList();
        finalDecoration = finalDecoration.copyWith(props: cleanedProps);

        // 이모티콘
        final cleanedEmoticons = _selectedEmoticonIds
            .where((id) => !unownedIds.contains(id))
            .toList();

        await characterController.updateActiveEmoticons(
            user.uid, cleanedEmoticons);
        await characterController.updateRoomDecoration(
            user.uid, finalDecoration);

        if (mounted) {
          MemoNotification.show(
              context,
              AppLocalizations.of(context)?.get('decorationSaved') ??
                  'Settings saved! ✨');
          await Future.delayed(Duration.zero);
          if (mounted && Navigator.of(context).canPop()) {
            context.pop();
          }
        }
      } catch (e) {
        if (mounted) {
          MemoNotification.show(context,
              '${AppLocalizations.of(context)?.get('error') ?? 'Error'}: $e');
        }
      }
    }
  }

  Future<void> _handleStickyNoteButton() async {
    final characterController = context.read<CharacterController>();
    final user = characterController.currentUser;
    if (user == null) return;

    // 1. 오늘 이미 작성했는지 체크
    final now = DateTime.now();
    final isUsedToday = user.lastStickyNoteDate != null &&
        user.lastStickyNoteDate!.year == now.year &&
        user.lastStickyNoteDate!.month == now.month &&
        user.lastStickyNoteDate!.day == now.day;

    if (isUsedToday) {
      MemoNotification.show(
          context,
          AppLocalizations.of(context)?.get('stickyNoteLimit') ??
              'You can only write a note once a day. ✍️');
      return;
    }

    // 2. 포인트 체크 (5가지)
    if (user.points < 5) {
      MemoNotification.show(
        context,
        AppLocalizations.of(context)?.get('notEnoughPoints') ??
            'Not enough branches! (5 required)',
      );
      return;
    }

    // 3. 입력창 띄우기
    final text = await _showStickyNoteInput(context);
    if (text == null || text.trim().isEmpty) return;

    // 4. 포인트 차감 및 작성 처리
    try {
      await characterController.useStickyNote(user.uid);

      // 5. 소품 배치
      final newProp = RoomPropModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'sticky_note',
        x: 0.5,
        y: 0.6,
        metadata: {
          'content': text,
          'heartCount': 0,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      _decorationNotifier.value = _decorationNotifier.value.copyWith(
        props: [..._decorationNotifier.value.props, newProp],
      );

      if (mounted) {
        MemoNotification.show(
            context,
            AppLocalizations.of(context)?.get('stickyNoteAdded') ??
                'Memo added! (5 points deducted) 📝');
      }
    } catch (e) {
      if (mounted) {
        MemoNotification.show(context, e.toString());
      }
    }
  }

  Widget _buildCategoryTabs(AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
            top: 5, bottom: 10), // Reduced top padding to move tabs up
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            _buildTabItem(
                'props',
                AppLocalizations.of(context)?.get('prop') ?? 'Prop',
                Icons.chair,
                colorScheme),
            const SizedBox(width: 8),
            _buildTabItem(
                'wallpaper',
                AppLocalizations.of(context)?.get('wallpaper') ?? 'Wallpaper',
                Icons.wallpaper,
                colorScheme),
            const SizedBox(width: 8),
            _buildTabItem(
                'floor',
                AppLocalizations.of(context)?.get('floor') ?? 'Floor',
                Icons.grid_on_outlined,
                colorScheme),
            const SizedBox(width: 8),
            _buildTabItem(
                'background',
                AppLocalizations.of(context)?.get('background') ?? 'Background',
                Icons.landscape_outlined,
                colorScheme),
            const SizedBox(width: 8),
            _buildTabItem(
                'window',
                AppLocalizations.of(context)?.get('window') ?? 'Window',
                Icons.window,
                colorScheme),
            const SizedBox(width: 8),
            _buildTabItem(
                'emoticon',
                AppLocalizations.of(context)?.get('emoticon') ?? 'Emoticon',
                Icons.emoji_emotions,
                colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(
      String id, String label, IconData icon, AppColorScheme colorScheme) {
    final isSelected = _selectedCategory == id;
    return GestureDetector(
      onTap: () {
        final newIndex = _categories.indexOf(id);
        if (newIndex == _currentIndex) return;

        setState(() {
          _currentIndex = newIndex;
          _selectedCategory = id;
          _isPanelExpanded = true; // Automatically expand when a tab is clicked
        });
        AssetPrecacheService().precacheCategory(context, id);

        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(isSelected
                ? 'assets/images/Confirm_Button.png'
                : 'assets/images/Cancel_Button.png'),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? const Color(0xFF8B7355)
                  : const Color(0xFF5D4E37),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'BMJUA',
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContentByIndex(
      int index, user, AppColorScheme colorScheme) {
    switch (_categories[index]) {
      case 'background':
        return _buildBackgroundList(user, colorScheme);
      case 'wallpaper':
        return _buildWallpaperList(user, colorScheme);
      case 'props':
        return _buildPropList(user, colorScheme);
      case 'floor':
        return _buildFloorList(user, colorScheme);
      case 'window':
        return _buildWindowList(user, colorScheme);
      case 'emoticon':
        return _buildEmoticonList(user, colorScheme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildBackgroundList(user, AppColorScheme colorScheme) {
    final allItems = RoomAssets.backgrounds;
    final filtered = _isOwnedOnly
        ? allItems
            .where((b) =>
                b.id == 'default' || user.purchasedBackgroundIds.contains(b.id))
            .toList()
        : allItems;

    return ValueListenableBuilder<RoomDecorationModel>(
      valueListenable: _decorationNotifier,
      builder: (context, decoration, _) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final b = filtered[index];
            final isOwned =
                b.id == 'default' || user.purchasedBackgroundIds.contains(b.id);
            final isSelected = decoration.backgroundId == b.id;
            return _buildSelectionCard(
              label: b.getLocalizedName(context),
              icon: b.icon,
              imagePath: b.imagePath,
              color: b.color ??
                  (isSelected ? colorScheme.success : Colors.blueGrey),
              isSelected: isSelected,
              isOwned: isOwned,
              price: b.price,
              onTap: () {
                _decorationNotifier.value =
                    decoration.copyWith(backgroundId: b.id);
              },
              colorScheme: colorScheme,
            );
          },
        );
      },
    );
  }

  Widget _buildWallpaperList(user, AppColorScheme colorScheme) {
    final allItems = RoomAssets.wallpapers;
    final filtered = _isOwnedOnly
        ? allItems
            .where((w) =>
                w.id == 'default' || user.purchasedThemeIds.contains(w.id))
            .toList()
        : allItems;

    return ValueListenableBuilder<RoomDecorationModel>(
      valueListenable: _decorationNotifier,
      builder: (context, decoration, _) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final w = filtered[index];
            final isOwned =
                w.id == 'default' || user.purchasedThemeIds.contains(w.id);
            final isSelected = decoration.wallpaperId == w.id;
            return _buildSelectionCard(
              label: w.getLocalizedName(context),
              color: w.color ?? colorScheme.backgroundLight,
              imagePath: w.imagePath,
              isSelected: isSelected,
              isOwned: isOwned,
              price: w.price,
              onTap: () {
                _decorationNotifier.value =
                    decoration.copyWith(wallpaperId: w.id);
              },
              colorScheme: colorScheme,
            );
          },
        );
      },
    );
  }

  Widget _buildFloorList(user, AppColorScheme colorScheme) {
    final allItems = RoomAssets.floors;
    final filtered = _isOwnedOnly
        ? allItems.where((f) => user.purchasedFloorIds.contains(f.id)).toList()
        : allItems;

    return ValueListenableBuilder<RoomDecorationModel>(
      valueListenable: _decorationNotifier,
      builder: (context, decoration, _) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final f = filtered[index];
            final isOwned = user.purchasedFloorIds.contains(f.id);
            final isSelected = decoration.floorId == f.id;

            return _buildSelectionCard(
              label: f.getLocalizedName(context),
              color: f.color ?? colorScheme.backgroundLight,
              imagePath: f.imagePath,
              icon: f.icon,
              isSelected: isSelected,
              isOwned: isOwned,
              price: f.price,
              onTap: () {
                _decorationNotifier.value = decoration.copyWith(floorId: f.id);
              },
              colorScheme: colorScheme,
              fontSize: 13,
              stampSize: 110,
            );
          },
        );
      },
    );
  }

  Widget _buildPropList(user, AppColorScheme colorScheme) {
    return ValueListenableBuilder<RoomDecorationModel>(
      valueListenable: _decorationNotifier,
      builder: (context, decoration, _) {
        // 스티커 메모 제외, 전체 또는 구매한 상품만 표시
        final allProps = RoomAssets.props
            .where((p) => p.id != 'sticky_note' && p.category != 'window')
            .toList();
        final availableProps = _isOwnedOnly
            ? allProps
                .where((p) =>
                    user.purchasedPropIds.contains(p.id) ||
                    decoration.props.any((prop) => prop.type == p.id))
                .toList()
            : allProps;

        if (availableProps.isEmpty) {
          return Center(
              child: Text(AppLocalizations.of(context)?.get('noProps') ??
                  'You don\'t have any props. Buy some in the shop!'));
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: availableProps.length,
          itemBuilder: (context, index) {
            final p = availableProps[index];
            final isOwned = user.purchasedPropIds.contains(p.id);
            final exists = decoration.props.any((prop) => prop.type == p.id);

            return _buildSelectionCard(
              label: p.getLocalizedName(context),
              imagePath: p.imagePath,
              icon: p.icon,
              isSelected: exists,
              isOwned: isOwned,
              price: p.price,
              onTap: () {
                if (exists) {
                  // 이미 배치된 경우: 제거
                  final newProps = decoration.props
                      .where((prop) => prop.type != p.id)
                      .toList();
                  _decorationNotifier.value =
                      decoration.copyWith(props: newProps);
                  return;
                }

                // 일반 소품 배치
                final newProp = RoomPropModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: p.id,
                  x: 0.5,
                  y: 0.6,
                );

                Future.microtask(() {
                  if (context.mounted) {
                    _decorationNotifier.value = decoration.copyWith(
                      props: [...decoration.props, newProp],
                    );
                  }
                });
              },
              colorScheme: colorScheme,
            );
          },
        );
      },
    );
  }

  Widget _buildEmoticonList(user, AppColorScheme colorScheme) {
    final allItems = RoomAssets.emoticons;
    final availableEmoticons = _isOwnedOnly
        ? allItems
            .where((e) => user.purchasedEmoticonIds.contains(e.id))
            .toList()
        : allItems;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: availableEmoticons.length,
      itemBuilder: (context, index) {
        final emoticon = availableEmoticons[index];
        final isOwned = user.purchasedEmoticonIds.contains(emoticon.id);
        final selIndex = _selectedEmoticonIds.indexOf(emoticon.id);
        final isSelected = selIndex != -1;

        return _buildSelectionCard(
          label: emoticon.getLocalizedName(context),
          imagePath: emoticon.imagePath,
          icon: emoticon.icon,
          isSelected: isSelected,
          isOwned: isOwned,
          price: emoticon.price,
          badgeText: isSelected ? (selIndex + 1).toString() : null,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedEmoticonIds.remove(emoticon.id);
              } else {
                _selectedEmoticonIds.add(emoticon.id);
              }
            });
          },
          colorScheme: colorScheme,
          showStamp: false,
          showDashedBorder: true,
        );
      },
    );
  }

  Widget _buildSelectionCard({
    required String label,
    Color? color,
    IconData? icon,
    String? imagePath,
    required bool isSelected,
    String? badgeText,
    required VoidCallback onTap,
    required AppColorScheme colorScheme,
    double fontSize = 10,
    double bottom = 15,
    double stampSize = 80,
    bool showStamp = true,
    bool showDashedBorder = false,
    bool isOwned = true,
    int price = 0,
    EdgeInsets? imagePadding,
  }) {
    final effectiveBottom = isOwned ? bottom : bottom + 20;
    final effectiveImagePadding = imagePadding ??
        EdgeInsets.only(
            left: 18.0, right: 18.0, top: 26.0, bottom: isOwned ? 26.0 : 44.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/icons/Friend_Card${(label.hashCode.abs() % 6) + 1}.png',
            ),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isSelected && showDashedBorder)
                Positioned.fill(
                  child: CustomPaint(
                    painter: DashedBorderPainter(
                      color: const Color(0xFF8D6E63),
                      strokeWidth: 2,
                      gap: 4,
                      radius: 12,
                    ),
                  ),
                ),
              if (imagePath != null)
                Positioned.fill(
                  child: Padding(
                    padding: effectiveImagePadding,
                    child: NetworkOrAssetImage(
                      imagePath: imagePath,
                      fit: BoxFit.contain,
                      width: 200,
                    ),
                  ),
                ),
              if (icon != null && imagePath == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Icon(icon,
                      size: 32,
                      color: isSelected ? Colors.white : Colors.blueGrey),
                ),
              if (isSelected && badgeText != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'BMJUA',
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: effectiveBottom,
                left: 4,
                right: 4,
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'BMJUA',
                    fontSize: fontSize,
                    height: 1.1, // 줄 간격 좁게
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: colorScheme.textPrimary,
                  ),
                ),
              ),
              // Lock icon for unowned items
              if (!isOwned)
                Positioned(
                  bottom: 11,
                  left: 8,
                  right: 8,
                  child: Center(
                    child: Image.asset(
                      'assets/icons/Lock_Icon.png',
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              if (isSelected && showStamp)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/Purchase_Image.png',
                      width: stampSize,
                      height: stampSize,
                      fit: BoxFit.contain,
                    ),
                    Positioned(
                      top: 15,
                      child: Text(
                        AppLocalizations.of(context)?.get('stampEquipped') ??
                            'Equipped',
                        style: const TextStyle(
                          color: Color(0xFFE57373),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'BMJUA',
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindowList(user, AppColorScheme colorScheme) {
    // RoomAssets.windows + RoomAssets.props 중 category가 'window'인 항목들
    final defaultWindows = RoomAssets.windows;
    final propWindows =
        RoomAssets.props.where((p) => p.category == 'window').toList();
    final allWindows = [...defaultWindows, ...propWindows];

    final filtered = _isOwnedOnly
        ? allWindows
            .where((w) =>
                w.id == 'default' ||
                w.id == 'none' ||
                user.purchasedWindowIds.contains(w.id))
            .toList()
        : allWindows;

    return ValueListenableBuilder<RoomDecorationModel>(
      valueListenable: _decorationNotifier,
      builder: (context, decoration, _) {
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final w = filtered[index];
            final isOwned = w.id == 'default' ||
                w.id == 'none' ||
                user.purchasedWindowIds.contains(w.id);
            final isSelected = decoration.windowId == w.id;

            return _buildSelectionCard(
              label: w.getLocalizedName(context),
              color: w.color ?? colorScheme.backgroundLight,
              imagePath: w.imagePath,
              icon: w.icon,
              isSelected: isSelected,
              isOwned: isOwned,
              price: w.price,
              imagePadding: EdgeInsets.only(
                left: 28,
                right: 28,
                top: 32,
                bottom: isOwned ? 32 : 48,
              ),
              onTap: () {
                _decorationNotifier.value = decoration.copyWith(windowId: w.id);
              },
              colorScheme: colorScheme,
            );
          },
        );
      },
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.gap = 5.0,
    this.radius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
            size.width - strokeWidth, size.height - strokeWidth),
        Radius.circular(radius),
      ));

    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? gap : gap;
        if (draw) {
          dashedPath.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

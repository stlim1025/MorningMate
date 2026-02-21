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

class DecorationScreen extends StatefulWidget {
  const DecorationScreen({super.key});

  @override
  State<DecorationScreen> createState() => _DecorationScreenState();
}

class _DecorationScreenState extends State<DecorationScreen>
    with SingleTickerProviderStateMixin {
  late ValueNotifier<RoomDecorationModel> _decorationNotifier;
  String _selectedCategory = 'background'; // 'background', 'wallpaper', 'props'
  int? _selectedPropIndex; // Track selected prop for editing

  bool _isPanelExpanded = false; // Track panel state
  bool? _previewIsAwake;
  late List<String> _selectedEmoticonIds;

  final List<String> _categories = [
    'background',
    'wallpaper',
    'props',
    'floor',
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
            label: AppLocalizations.of(context)?.get('confirm') ?? 'Confirm',
            isPrimary: true,
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
    final paddingBottom = MediaQuery.of(context).padding.bottom;

    // Panel Configuration
    final double panelHeight =
        screenSize.height * 0.35; // Take up about 1/3 of screen height
    final double visibleHeaderHeight =
        80.0 + paddingBottom; // Reduced from 90 to match tighter header layout

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
              onTap: () async {
                try {
                  await characterController.updateActiveEmoticons(
                      user.uid, _selectedEmoticonIds);
                  await characterController.updateRoomDecoration(
                      user.uid, _decorationNotifier.value);
                  if (context.mounted) {
                    MemoNotification.show(
                        context,
                        AppLocalizations.of(context)?.get('decorationSaved') ??
                            'Settings saved! ✨');
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    MemoNotification.show(
                      context,
                      AppLocalizations.of(context)?.getFormat('saveFailed', {
                            'error':
                                e.toString().replaceFirst('Exception: ', '')
                          }) ??
                          'Save failed: ${e.toString().replaceFirst('Exception: ', '')}',
                    );
                  }
                }
              },
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
                // Determine bottom padding for the room based on panel state
                // When collapsed, the visible header matches the main screen bottom bar area.
                final roomBottomPadding = visibleHeaderHeight;

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
                  bottomPadding: roomBottomPadding,
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
            height: panelHeight,
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
                        padding: EdgeInsets.only(bottom: 15.0 + paddingBottom),
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

          // 4. Remove All Props Button (follows panel animation)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: (_isPanelExpanded ? panelHeight : visibleHeaderHeight) + 10,
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
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
            top: 2, bottom: 10), // Reduced top padding to move tabs up
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            _buildTabItem(
                'background',
                AppLocalizations.of(context)?.get('background') ?? 'Background',
                Icons.landscape_outlined,
                colorScheme),
            const SizedBox(width: 8),
            _buildTabItem(
                'wallpaper',
                AppLocalizations.of(context)?.get('wallpaper') ?? 'Wallpaper',
                Icons.wallpaper,
                colorScheme),
            const SizedBox(width: 8),
            _buildTabItem(
                'props',
                AppLocalizations.of(context)?.get('prop') ?? 'Prop',
                Icons.auto_awesome_motion,
                colorScheme),
            const SizedBox(width: 8),
            _buildTabItem(
                'floor',
                AppLocalizations.of(context)?.get('floor') ?? 'Floor',
                Icons.grid_on_outlined,
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
              style: TextStyle(
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
      case 'emoticon':
        return _buildEmoticonList(user, colorScheme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildBackgroundList(user, AppColorScheme colorScheme) {
    final purchased = RoomAssets.backgrounds
        .where((b) =>
            b.id == 'default' || user.purchasedBackgroundIds.contains(b.id))
        .toList();

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
          itemCount: purchased.length,
          itemBuilder: (context, index) {
            final b = purchased[index];
            final isSelected = decoration.backgroundId == b.id;
            return _buildSelectionCard(
              label: AppLocalizations.of(context)?.get('item_name_${b.id}') ??
                  b.name,
              icon: b.icon,
              imagePath: b.imagePath,
              color: b.color ??
                  (isSelected ? colorScheme.success : Colors.blueGrey),
              isSelected: isSelected,
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
    final purchased = RoomAssets.wallpapers
        .where(
            (w) => w.id == 'default' || user.purchasedThemeIds.contains(w.id))
        .toList();

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
          itemCount: purchased.length,
          itemBuilder: (context, index) {
            final w = purchased[index];
            final isSelected = decoration.wallpaperId == w.id;
            return _buildSelectionCard(
              label: AppLocalizations.of(context)?.get('item_name_${w.id}') ??
                  w.name,
              color: w.color ?? colorScheme.backgroundLight,
              imagePath: w.imagePath,
              isSelected: isSelected,
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
    final purchased = RoomAssets.floors
        .where((f) => user.purchasedFloorIds.contains(f.id))
        .toList();

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
          itemCount: purchased.length,
          itemBuilder: (context, index) {
            final f = purchased[index];
            final isSelected = decoration.floorId == f.id;

            return _buildSelectionCard(
              label: AppLocalizations.of(context)?.get('item_name_${f.id}') ??
                  f.name,
              color: f.color ?? colorScheme.backgroundLight,
              imagePath: f.imagePath,
              icon: f.icon,
              isSelected: isSelected,
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
        // 이미 배치된 소품이거나 소유 중인 소품을 목록에 표시
        final availableProps = RoomAssets.props
            .where((p) =>
                user.purchasedPropIds.contains(p.id) ||
                decoration.props.any((prop) => prop.type == p.id))
            .toList();

        if (availableProps.isEmpty) {
          return Center(
              child: Text(AppLocalizations.of(context)?.get('noProps') ??
                  'You don\'t have any props. Buy some in the shop!'));
        }

        final now = DateTime.now();
        final isUsedToday = user.lastStickyNoteDate != null &&
            user.lastStickyNoteDate!.year == now.year &&
            user.lastStickyNoteDate!.month == now.month &&
            user.lastStickyNoteDate!.day == now.day;

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
            final exists = decoration.props.any((prop) => prop.type == p.id);

            return _buildSelectionCard(
              label: AppLocalizations.of(context)?.get('item_name_${p.id}') ??
                  p.name,
              imagePath: p.imagePath,
              icon: p.icon,
              isSelected: exists,
              onTap: () async {
                if (exists) {
                  // 이미 배치된 경우: 제거
                  if (p.id == 'sticky_note') {
                    final confirm = await AppDialog.show<bool>(
                      context: context,
                      key: AppDialogKey.deleteStickyNote,
                      content: Text(AppLocalizations.of(context)
                              ?.get('deleteStickyNote') ??
                          'Do you want to delete this memo? 🗑️'),
                    );
                    if (confirm != true) return;
                  }

                  final newProps = decoration.props
                      .where((prop) => prop.type != p.id)
                      .toList();
                  _decorationNotifier.value =
                      decoration.copyWith(props: newProps);
                  return;
                }

                // 새로 배치하는 경우
                if (p.id == 'sticky_note') {
                  // 오늘 이미 작성했는지 체크
                  if (isUsedToday) {
                    MemoNotification.show(
                        context,
                        AppLocalizations.of(context)?.get('stickyNoteLimit') ??
                            'You can only write a note once a day. ✍️');
                    return;
                  }

                  // 인벤토리에 있는지 체크 (이미 배치된 걸 제거했다가 다시 넣는 경우 대비)
                  if (!user.purchasedPropIds.contains('sticky_note')) {
                    MemoNotification.show(
                        context,
                        AppLocalizations.of(context)?.get('noStickyNote') ??
                            'You don\'t have a sticky note. Please buy one from the shop. 📦');
                    return;
                  }

                  final text = await _showStickyNoteInput(context);
                  if (text == null || text.trim().isEmpty) return;

                  final newProp = RoomPropModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: p.id,
                    x: 0.5,
                    y: 0.6, // Place lower to avoid overlapping with character
                    metadata: {
                      'content': text,
                      'heartCount': 0,
                      'createdAt': DateTime.now().toIso8601String(),
                    },
                  );
                  _decorationNotifier.value = decoration.copyWith(
                    props: [...decoration.props, newProp],
                  );
                } else {
                  // 일반 소품 배치
                  final newProp = RoomPropModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: p.id,
                    x: 0.5,
                    y: 0.6, // Place lower to avoid overlapping with character
                  );

                  // 상태 업데이트를 다음 마이크로태스크로 지연하여
                  // 빌드/네비게이션 충돌(!_debugLocked) 방지
                  Future.microtask(() {
                    if (context.mounted) {
                      _decorationNotifier.value = decoration.copyWith(
                        props: [...decoration.props, newProp],
                      );
                    }
                  });
                }
              },
              colorScheme: colorScheme,
            );
          },
        );
      },
    );
  }

  Widget _buildEmoticonList(user, AppColorScheme colorScheme) {
    final availableEmoticons = RoomAssets.emoticons
        .where((e) => user.purchasedEmoticonIds.contains(e.id))
        .toList();

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
        final selIndex = _selectedEmoticonIds.indexOf(emoticon.id);
        final isSelected = selIndex != -1;

        return _buildSelectionCard(
          label:
              AppLocalizations.of(context)?.get('item_name_${emoticon.id}') ??
                  emoticon.name,
          imagePath: emoticon.imagePath,
          icon: emoticon.icon,
          isSelected: isSelected,
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
    double bottom = 12,
    double stampSize = 80,
    bool showStamp = true,
    bool showDashedBorder = false,
  }) {
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 26.0),
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
                bottom: bottom,
                left: 4,
                right: 4,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'BMJUA',
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: colorScheme.textPrimary,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/constants/room_assets.dart';
import '../controllers/character_controller.dart';
import '../../morning/controllers/morning_controller.dart';
import '../../morning/widgets/enhanced_character_room_widget.dart';

import '../../../data/models/room_decoration_model.dart';
import '../../../core/widgets/app_dialog.dart';

class DecorationScreen extends StatefulWidget {
  const DecorationScreen({super.key});

  @override
  State<DecorationScreen> createState() => _DecorationScreenState();
}

class _DecorationScreenState extends State<DecorationScreen> {
  late ValueNotifier<RoomDecorationModel> _decorationNotifier;
  String _selectedCategory = 'background'; // 'background', 'wallpaper', 'props'
  int? _selectedPropIndex; // Track selected prop for editing
  bool? _previewIsAwake;
  late List<String> _selectedEmoticonIds;

  Future<String?> _showStickyNoteInput(BuildContext context) async {
    final controller = TextEditingController();

    try {
      return await AppDialog.show<String>(
        context: context,
        key: AppDialogKey.writeMemo,
        content: PopupTextField(
          autofocus: true,
          controller: controller,
          hintText: '짧은 메시지를 남겨보세요',
          maxLength: 50,
          maxLines: 3,
        ),
        actions: [
          AppDialogAction(
            label: '취소',
            onPressed: (context) => Navigator.pop(context),
          ),
          AppDialogAction(
            label: '확인',
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
  }

  @override
  void dispose() {
    _decorationNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final characterController = context.read<CharacterController>();
    final user = characterController.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset(
            'assets/icons/X_Button.png',
            width: 40,
            height: 40,
          ),
        ),
        title: const Text(
          '방 꾸미기',
          style: TextStyle(
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
                  // 활성 이모티콘 저장
                  await characterController.updateActiveEmoticons(
                      user.uid, _selectedEmoticonIds);

                  // 방 꾸미기 설정 저장
                  await characterController.updateRoomDecoration(
                      user.uid, _decorationNotifier.value);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('설정이 저장되었습니다!'),
                        backgroundColor: colorScheme.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '저장 실패: ${e.toString().replaceFirst('Exception: ', '')}'),
                        backgroundColor: colorScheme.error,
                      ),
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
                child: const Text(
                  '저장',
                  style: TextStyle(
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
      body: Column(
        children: [
          // 1. Interactive Preview Area
          Expanded(
            flex: 14,
            child: ValueListenableBuilder<RoomDecorationModel>(
              valueListenable: _decorationNotifier,
              builder: (context, decoration, child) {
                final controller = context.read<CharacterController>();
                final morningController = context.watch<MorningController>();

                // Use preview state or actual state if preview state is not yet set
                _previewIsAwake ??= morningController.hasDiaryToday;
                final isAwakePreview = _previewIsAwake!;

                return Stack(
                  children: [
                    // 1. Room Interior (Full Screen)
                    Positioned.fill(
                      child: EnhancedCharacterRoomWidget(
                        isAwake: isAwakePreview,
                        characterLevel:
                            controller.currentUser?.characterLevel ?? 1,
                        consecutiveDays:
                            controller.currentUser?.consecutiveDays ?? 0,
                        roomDecoration: decoration,
                        hideProps: false,
                        showBorder: false,
                        bottomPadding: 0,
                        currentAnimation: controller.currentAnimation,
                        isPropEditable: true, // 항상 소품 편집 가능
                        selectedPropIndex: _selectedPropIndex, // 항상 선택 표시
                        onPropChanged: (index, newProp) {
                          final newProps =
                              List<RoomPropModel>.from(decoration.props);
                          newProps[index] = newProp;
                          _decorationNotifier.value =
                              decoration.copyWith(props: newProps);
                        },
                        onPropTap: (prop) {
                          final index = decoration.props.indexOf(prop);
                          if (index != -1) {
                            // Bring selected prop to front (end of list = top layer)
                            final newProps =
                                List<RoomPropModel>.from(decoration.props);
                            final selectedProp = newProps.removeAt(index);
                            newProps.add(selectedProp);

                            _decorationNotifier.value =
                                decoration.copyWith(props: newProps);

                            setState(() {
                              _selectedPropIndex = newProps.length - 1;
                            });
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

                          final newProps =
                              List<RoomPropModel>.from(decoration.props);
                          newProps.removeAt(index);
                          _decorationNotifier.value =
                              decoration.copyWith(props: newProps);
                          setState(() {
                            _selectedPropIndex = null;
                          });
                        },
                      ),
                    ),

                    // 2. Day/Night Preview Toggle Button
                    Positioned(
                      top: 100, // Below App Bar
                      left: 20,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _previewIsAwake = !isAwakePreview;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isAwakePreview
                                    ? Icons.wb_sunny_rounded
                                    : Icons.nightlight_round,
                                color: isAwakePreview
                                    ? Colors.orangeAccent
                                    : Colors.yellowAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isAwakePreview ? '미리보기: 낮' : '미리보기: 밤',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // 2. Bottom Control Area
          Expanded(
            flex: 10,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: ResizeImage(
                      AssetImage('assets/images/DecorationList_Background.png'),
                      width: 1080),
                  fit: BoxFit.fill,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, bottom: 2),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.shadowColor.withOpacity(0.1),
                    ),
                  ),
                  _buildCategoryTabs(colorScheme),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30.0),
                      child: _buildCategoryContent(user, colorScheme),
                    ),
                  ),
                ],
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            _buildTabItem(
                'background', '배경', Icons.landscape_outlined, colorScheme),
            const SizedBox(width: 8),
            _buildTabItem('wallpaper', '벽지', Icons.wallpaper, colorScheme),
            const SizedBox(width: 8),
            _buildTabItem(
                'props', '소품', Icons.auto_awesome_motion, colorScheme),
            const SizedBox(width: 8),
            _buildTabItem('floor', '바닥', Icons.grid_on_outlined, colorScheme),
            const SizedBox(width: 8),
            _buildTabItem(
                'emoticon', '이모티콘', Icons.emoji_emotions, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(
      String id, String label, IconData icon, AppColorScheme colorScheme) {
    final isSelected = _selectedCategory == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = id),
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

  Widget _buildCategoryContent(user, AppColorScheme colorScheme) {
    switch (_selectedCategory) {
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
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 150),
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
              label: b.name,
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
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 150),
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
              label: w.name,
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
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 150),
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
              label: f.name,
              color: f.color ?? colorScheme.backgroundLight,
              imagePath: f.imagePath,
              icon: f.icon,
              isSelected: isSelected,
              onTap: () {
                _decorationNotifier.value = decoration.copyWith(floorId: f.id);
              },
              colorScheme: colorScheme,
              fontSize: 13,
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
          return const Center(child: Text('구매한 소품이 없습니다. 상점에서 구매해 보세요!'));
        }

        final now = DateTime.now();
        final isUsedToday = user.lastStickyNoteDate != null &&
            user.lastStickyNoteDate!.year == now.year &&
            user.lastStickyNoteDate!.month == now.month &&
            user.lastStickyNoteDate!.day == now.day;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 150),
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

            return GestureDetector(
              onTap: () async {
                if (exists) {
                  // 이미 배치된 경우: 제거
                  if (p.id == 'sticky_note') {
                    final confirm = await AppDialog.show<bool>(
                      context: context,
                      key: AppDialogKey.deleteStickyNote,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('메모는 하루에 한 번만 작성할 수 있습니다.'),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                    return;
                  }

                  // 인벤토리에 있는지 체크 (이미 배치된 걸 제거했다가 다시 넣는 경우 대비)
                  if (!user.purchasedPropIds.contains('sticky_note')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('보관 중인 메모 노트가 없습니다. 상점에서 구매해 주세요.'),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                    return;
                  }

                  final text = await _showStickyNoteInput(context);
                  if (text == null || text.trim().isEmpty) return;

                  final newProp = RoomPropModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: p.id,
                    x: 0.5,
                    y: 0.5,
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
                    y: 0.5,
                  );
                  _decorationNotifier.value = decoration.copyWith(
                    props: [...decoration.props, newProp],
                  );
                }
              },
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/icons/Friend_Card${(p.name.hashCode.abs() % 6) + 1}.png',
                      ),
                      fit: BoxFit.fill,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (p.imagePath != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 26),
                          child: p.imagePath!.endsWith('.svg')
                              ? SvgPicture.asset(
                                  p.imagePath!,
                                  fit: BoxFit.contain,
                                )
                              : Image.asset(
                                  p.imagePath!,
                                  cacheWidth: 150,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(p.icon,
                                        color: exists
                                            ? colorScheme.success
                                            : Colors.blueGrey,
                                        size: 24);
                                  },
                                ),
                        )
                      else
                        Icon(p.icon,
                            color:
                                exists ? colorScheme.success : Colors.blueGrey,
                            size: 24),
                      if (exists)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Image.asset(
                            'assets/images/Red_Pin.png',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      Positioned(
                        bottom: 8,
                        left: 4,
                        right: 4,
                        child: Text(
                          p.name,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'BMJUA',
                            fontSize: 10,
                            fontWeight:
                                exists ? FontWeight.bold : FontWeight.normal,
                            color: exists
                                ? colorScheme.success
                                : colorScheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 150),
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
          label: emoticon.name,
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
              if (imagePath != null)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 26.0),
                    child: imagePath.endsWith('.svg')
                        ? SvgPicture.asset(
                            imagePath,
                            fit: BoxFit.contain,
                          )
                        : Image.asset(
                            imagePath,
                            width: 200,
                            fit: BoxFit.contain,
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
              if (isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Image.asset(
                    'assets/images/Red_Pin.png',
                    width: 28,
                    height: 28,
                  ),
                ),
              if (isSelected && badgeText != null)
                Container(
                  color: Colors.black26,
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
                    color: isSelected
                        ? colorScheme.success
                        : colorScheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

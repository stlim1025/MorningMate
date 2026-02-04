import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/constants/room_assets.dart';
import '../controllers/character_controller.dart';
import '../../morning/controllers/morning_controller.dart';
import '../../morning/widgets/enhanced_character_room_widget.dart';

import '../../../data/models/room_decoration_model.dart';
import '../../../core/theme/app_theme_type.dart';
import '../../../core/widgets/app_dialog.dart';

class DecorationScreen extends StatefulWidget {
  const DecorationScreen({super.key});

  @override
  State<DecorationScreen> createState() => _DecorationScreenState();
}

class _DecorationScreenState extends State<DecorationScreen> {
  late ValueNotifier<RoomDecorationModel> _decorationNotifier;
  String _selectedCategory =
      'background'; // 'theme', 'background', 'wallpaper', 'props'
  int? _selectedPropIndex; // Track selected prop for editing
  String? _currentUserThemeId;
  late AppThemeType _originalThemeType;
  bool? _previewIsAwake;

  Future<String?> _showStickyNoteInput(BuildContext context) async {
    String text = '';
    return showDialog<String>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
        return AlertDialog(
          backgroundColor: colorScheme.backgroundLight,
          title:
              Text('메모 작성', style: TextStyle(color: colorScheme.textPrimary)),
          content: TextField(
            autofocus: true,
            maxLength: 50,
            decoration: InputDecoration(
              hintText: '짧은 메시지를 남겨보세요',
              hintStyle: TextStyle(color: colorScheme.textHint),
              counterStyle: TextStyle(color: colorScheme.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: colorScheme.textPrimary),
            onChanged: (value) => text = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소',
                  style: TextStyle(color: colorScheme.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, text),
              child: Text('확인',
                  style: TextStyle(color: colorScheme.primaryButton)),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final controller = context.read<CharacterController>();
    final themeController = context.read<ThemeController>();

    var initialDecoration =
        controller.currentUser?.roomDecoration ?? RoomDecorationModel();
    // Validate Props
    final validProps = initialDecoration.props
        .where((p) => RoomAssets.props.any((asset) => asset.id == p.type))
        .toList();
    if (validProps.length != initialDecoration.props.length) {
      initialDecoration = initialDecoration.copyWith(props: validProps);
    }
    _currentUserThemeId = controller.currentUser?.currentThemeId;
    _originalThemeType = themeController.themeType;
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
    final characterController = context.watch<CharacterController>();
    final themeController = context.read<ThemeController>();
    final user = characterController.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: IconThemeData(color: colorScheme.primaryButton),
        title: Text(
          '방 꾸미기',
          style: TextStyle(
            color: colorScheme.primaryButton,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () async {
                try {
                  // 테마 저장 (변경된 경우에만)
                  if (_currentUserThemeId != null &&
                      _currentUserThemeId != user.currentThemeId) {
                    await characterController.setTheme(
                        user.uid, _currentUserThemeId!);
                  }

                  // 방 꾸미기 설정 저장
                  await characterController.updateRoomDecoration(
                      user.uid, _decorationNotifier.value);

                  // 저장 성공 시 originalThemeType을 현재 선택된 테마로 업데이트하여
                  // PopScope에서 복구되지 않도록 함
                  if (context.mounted) {
                    final newThemeType =
                        context.read<ThemeController>().themeType;
                    _originalThemeType = newThemeType;
                  }

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
                          backgroundColor: colorScheme.error),
                    );
                  }
                }
              },
              child: Text(
                '저장',
                style: TextStyle(
                  color: colorScheme.primaryButton,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            // 저장하지 않고 나가는 경우 테마 복구
            if (_originalThemeType != themeController.themeType) {
              await themeController.setTheme(_originalThemeType);
            }
          }
        },
        child: Column(
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
                              border:
                                  Border.all(color: Colors.white24, width: 1),
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
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 25,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.shadowColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    _buildCategoryTabs(colorScheme),
                    const Divider(height: 1, thickness: 0.5),
                    Expanded(
                      child: _buildCategoryContent(
                          user, themeController, colorScheme),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(AppColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTabItem(
              'background', '배경', Icons.landscape_outlined, colorScheme),
          const SizedBox(width: 8),
          _buildTabItem('wallpaper', '벽지', Icons.wallpaper, colorScheme),
          const SizedBox(width: 8),
          _buildTabItem('props', '소품', Icons.auto_awesome_motion, colorScheme),
          const SizedBox(width: 8),
          _buildTabItem('floor', '바닥', Icons.grid_on_outlined, colorScheme),
          const SizedBox(width: 8),
          _buildTabItem('theme', '테마', Icons.palette_outlined, colorScheme),
        ],
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryButton
              : colorScheme.shadowColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : colorScheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContent(
      user, themeController, AppColorScheme colorScheme) {
    switch (_selectedCategory) {
      case 'theme':
        return _buildThemeList(user, themeController, colorScheme);
      case 'background':
        return _buildBackgroundList(user, colorScheme);
      case 'wallpaper':
        return _buildWallpaperList(user, colorScheme);
      case 'props':
        return _buildPropList(user, colorScheme);
      case 'floor':
        return _buildFloorList(user, colorScheme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildThemeList(user, themeController, AppColorScheme colorScheme) {
    final purchased = RoomAssets.themes
        .where((t) => user.purchasedThemeIds.contains(t.id))
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: purchased.length,
      itemBuilder: (context, index) {
        final t = purchased[index];
        final isSelected = _currentUserThemeId == t.id;
        return _buildSelectionCard(
          label: t.name,
          icon: t.icon,
          imagePath: t.imagePath,
          color: t.color ??
              (isSelected ? colorScheme.success : colorScheme.backgroundLight),
          isSelected: isSelected,
          onTap: () async {
            setState(() => _currentUserThemeId = t.id);
            // 미리보기용으로 테마 적용 (Firestore 저장 안함)
            if (t.themeType != null) {
              await themeController.setTheme(t.themeType!);
            }
          },
          colorScheme: colorScheme,
        );
      },
    );
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
          padding: const EdgeInsets.all(16),
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
          padding: const EdgeInsets.all(16),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: exists
                            ? colorScheme.success.withOpacity(0.08)
                            : colorScheme.shadowColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: exists
                              ? colorScheme.success
                              : colorScheme.shadowColor.withOpacity(0.1),
                          width: exists ? 3.5 : 1.5,
                        ),
                        boxShadow: [
                          if (exists)
                            BoxShadow(
                              color: colorScheme.success.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (p.imagePath != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: p.imagePath!.endsWith('.svg')
                                  ? SvgPicture.asset(
                                      p.imagePath!,
                                      fit: BoxFit.contain,
                                    )
                                  : Image.asset(
                                      p.imagePath!,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(p.icon,
                                            color: exists
                                                ? colorScheme.success
                                                : Colors.blueGrey,
                                            size: 28);
                                      },
                                    ),
                            )
                          else
                            Icon(p.icon,
                                color: exists
                                    ? colorScheme.success
                                    : Colors.blueGrey,
                                size: 28),
                          if (exists)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Icon(Icons.check_circle,
                                  color: colorScheme.success, size: 16),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      p.name,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
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
            );
          },
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
    required VoidCallback onTap,
    required AppColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: color ?? colorScheme.shadowColor.withOpacity(0.05),
                image: (imagePath != null && !imagePath.endsWith('.svg'))
                    ? DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.cover,
                      )
                    : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.success
                      : colorScheme.shadowColor.withOpacity(0.1),
                  width: isSelected ? 3.5 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.success.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (imagePath != null && imagePath.endsWith('.svg'))
                      Positioned.fill(
                        child: SvgPicture.asset(
                          imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (icon != null && imagePath == null)
                      Icon(icon,
                          size: 38,
                          color: isSelected ? Colors.white : Colors.blueGrey),
                    if (isSelected)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(Icons.check_circle,
                              color: Colors.white, size: 32),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? colorScheme.success : colorScheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/constants/room_assets.dart';
import '../../../core/constants/character_assets.dart';
import '../controllers/character_controller.dart';
import '../widgets/character_display.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/network_or_asset_image.dart';

class CharacterDecorationScreen extends StatefulWidget {
  const CharacterDecorationScreen({super.key});

  @override
  State<CharacterDecorationScreen> createState() =>
      _CharacterDecorationScreenState();
}

class _CharacterDecorationScreenState extends State<CharacterDecorationScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'all';
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isOwnedOnly = false;
  Map<String, String> _previewEquippedItems = {};

  late AnimationController _buttonController;
  late Animation<double> _scaleAnimation;

  final List<String> _categories = ['all', 'head', 'face', 'clothes', 'body'];

  String _getCategoryLabel(BuildContext context, String category) {
    if (category == 'all')
      return AppLocalizations.of(context)?.get('all') ?? 'All';
    if (category == 'head')
      return AppLocalizations.of(context)?.get('head') ?? 'Head';
    if (category == 'face')
      return AppLocalizations.of(context)?.get('face') ?? 'Face';
    if (category == 'clothes')
      return AppLocalizations.of(context)?.get('clothes') ?? 'Clothes';
    if (category == 'body')
      return AppLocalizations.of(context)?.get('accessory') ?? 'Accessory';
    return category;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<CharacterController>().currentUser;
      if (user != null) {
        setState(() {
          _previewEquippedItems = Map.from(user.equippedCharacterItems);
        });
      }
    });
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _getCategory(String itemId) {
    try {
      final item = CharacterAssets.items.firstWhere((e) => e.id == itemId);
      return item.category ?? 'face';
    } catch (e) {
      return 'face';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final characterController = context.watch<CharacterController>();
    final user = characterController.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final paddingBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Image.asset(
            'assets/icons/X_Button.png',
            width: 40,
            height: 40,
          ),
        ),
        title: Text(
          AppLocalizations.of(context)?.get('decorateCharacter') ??
              'Decorate Character',
          style: const TextStyle(
            color: Color(0xFF4E342E),
            fontWeight: FontWeight.bold,
            fontFamily: 'BMJUA',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
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
      body: Column(
        children: [
          // 1. Character Preview Area (Top)
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Popup_Background.png'),
                  fit: BoxFit.cover,
                  opacity: 0.5,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: CharacterDisplay(
                      isAwake: true,
                      characterLevel: user.characterLevel,
                      size: 250,
                      enableAnimation: true,
                      equippedItems: _previewEquippedItems, // Use preview items
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 20,
                    child: GestureDetector(
                      onTapDown: (_) => _buttonController.forward(),
                      onTapUp: (_) {
                        _buttonController.reverse();
                        setState(() {
                          _previewEquippedItems.clear();
                        });
                      },
                      onTapCancel: () => _buttonController.reverse(),
                      behavior: HitTestBehavior.opaque,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 80,
                          height: 35,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                  'assets/images/Message_Button.png'),
                              fit: BoxFit.fill,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.get('unequipAll') ??
                                'Unequip All',
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
                  Positioned(
                    bottom: 10,
                    right: 20,
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
                          // 커스텀 체크박스 (이미지만 표시)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: _isOwnedOnly
                                ? Image.asset(
                                    'assets/images/Check_Icon.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.transparent,
                                      border: Border.all(
                                        color: const Color(0xFF5D4037),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)
                                    ?.get('showOwnedOnly') ??
                                'Show Owned Only',
                            style: const TextStyle(
                              fontFamily: 'BMJUA',
                              fontSize: 14,
                              color: Color(0xFF5D4037),
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Decoration Items List (Bottom)
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: ResizeImage(
                    AssetImage('assets/images/DecorationList_Background.png'),
                    width: 1080,
                  ),
                  fit: BoxFit.fill,
                ),
              ),
              child: Column(
                children: [
                  // Tab Bar
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 20, right: 20, top: 20, bottom: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _buildTabItem(
                                _getCategoryLabel(context, category),
                                _selectedCategory == category, () {
                              final newIndex = _categories.indexOf(category);
                              setState(() {
                                _currentIndex = newIndex;
                                _selectedCategory = category;
                              });
                              _pageController.animateToPage(
                                newIndex,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Items PageView
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom:
                              (Theme.of(context).platform == TargetPlatform.iOS
                                      ? 5.0
                                      : 15.0) +
                                  paddingBottom),
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                            _selectedCategory = _categories[index];
                          });
                        },
                        itemCount: _categories.length,
                        itemBuilder: (context, pageIndex) {
                          final category = _categories[pageIndex];
                          final filteredItems =
                              CharacterAssets.items.where((item) {
                            // Category Filter
                            if (category != 'all' &&
                                _getCategory(item.id) != category) {
                              return false;
                            }
                            // Owned Filter
                            if (_isOwnedOnly) {
                              return user.purchasedCharacterItemIds
                                  .contains(item.id);
                            }
                            return true;
                          }).toList();

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 4, 24, 60),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                              childAspectRatio:
                                  0.75, // Adjusted for taller card
                            ),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final isOwned = user.purchasedCharacterItemIds
                                  .contains(item.id);
                              final isEquipped =
                                  _previewEquippedItems.containsValue(item.id);

                              return _buildSelectionCard(
                                item: item,
                                isOwned: isOwned,
                                isSelected: isEquipped,
                                onTap: () {
                                  // Determine slot
                                  String slot = _getCategory(item.id);
                                  _toggleItem(item.id, slot);
                                },
                                colorScheme: colorScheme,
                              );
                            },
                          );
                        },
                      ),
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

  void _toggleItem(String itemId, String slot) {
    setState(() {
      if (_previewEquippedItems[slot] == itemId) {
        // Un-equip if already equipped
        _previewEquippedItems.remove(slot);
      } else {
        // Equip new item
        _previewEquippedItems[slot] = itemId;
      }
    });
  }

  Future<void> _handleSave() async {
    final characterController = context.read<CharacterController>();
    var user = characterController.currentUser;
    if (user == null) return;

    // 1. Identify unowned items in current preview (using latest user state)
    final unownedItemIds = _previewEquippedItems.values
        .where((id) => !user!.purchasedCharacterItemIds.contains(id))
        .toSet();

    if (unownedItemIds.isEmpty) {
      try {
        // All owned -> Just save
        await characterController.updateEquippedCharacterItems(
            user.uid, _previewEquippedItems);
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
          MemoNotification.show(context, '저장 실패: $e');
        }
      }
      return;
    }

    // 2. 미보유 상품 팝업 보여주기
    if (!mounted) return;

    final shouldSaveWithoutUnowned = await AppDialog.show<bool>(
      context: context,
      key: AppDialogKey.purchase,
      content: Text(
        AppLocalizations.of(context)?.get('unownedItemsWarning') ??
            '배치된 항목 중 아직 보유하지 않은 아이템이 있어요!\n미보유 아이템은 상점에서 획득할 수 있습니다.\n뺀 상태로 저장할까요?',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'BMJUA',
          fontSize: 16,
          height: 1.5,
        ),
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

    if (shouldSaveWithoutUnowned == true && mounted) {
      try {
        // 다시 최신 상태 확인
        user = characterController.currentUser ?? user;
        final latestUnownedItemIds = _previewEquippedItems.values
            .where((id) => !user!.purchasedCharacterItemIds.contains(id))
            .toSet();

        // 미보유 상품 제외하고 저장
        final finalEquippedItems =
            Map<String, String>.from(_previewEquippedItems)
              ..removeWhere((slot, id) => latestUnownedItemIds.contains(id));

        setState(() {
          _previewEquippedItems = Map.from(finalEquippedItems);
        });

        await characterController.updateEquippedCharacterItems(
            user.uid, finalEquippedItems);

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
          MemoNotification.show(context, '저장 실패: $e');
        }
      }
    }
  }

  Widget _buildTabItem(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(isSelected
                ? 'assets/images/Confirm_Button.png'
                : 'assets/images/Cancel_Button.png'),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'BMJUA',
            fontSize: 14,
            color: Color(0xFF5D4E37),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required RoomAsset item,
    required bool isSelected,
    required bool isOwned,
    required VoidCallback onTap,
    required AppColorScheme colorScheme,
  }) {
    final cardIndex = (item.name.hashCode.abs() % 6) + 1;
    final cardBgImage = 'assets/icons/Friend_Card$cardIndex.png';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(cardBgImage),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Item Image
            Positioned(
              top: 0,
              bottom: isOwned ? 20 : 36, // Adjust space based on text position
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 16.0),
                child: item.imagePath != null
                    ? (item.imagePath!.endsWith('.svg')
                        ? SvgPicture.asset(item.imagePath!, fit: BoxFit.contain)
                        : NetworkOrAssetImage(
                            imagePath: item.imagePath!,
                            fit: BoxFit.contain,
                          ))
                    : Icon(item.icon,
                        color: item.color ?? colorScheme.primaryButton,
                        size: 24),
              ),
            ),

            // Item Name
            Positioned(
              bottom: isOwned ? 12 : 32, // Lower if owned, above button if not
              left: 4,
              right: 4,
              child: Text(
                item.getLocalizedName(context),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BMJUA',
                  color: Color(0xFF5D4037),
                  overflow: TextOverflow.ellipsis,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),

            // Lock icon for unowned items
            if (!isOwned)
              Positioned(
                bottom: 8,
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

            // Selected Stamp
            if (isSelected)
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/Purchase_Image.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                  Positioned(
                    top: 20,
                    child: Text(
                      AppLocalizations.of(context)?.get('stampEquipped') ??
                          'Equipped',
                      style: TextStyle(
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
    );
  }
}

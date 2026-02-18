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
                      padding: EdgeInsets.only(bottom: paddingBottom + 15),
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
                                onPriceClick: () {
                                  _showSinglePurchaseDialog(item, user);
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
    final user = characterController.currentUser;
    if (user == null) return;

    // 1. Identify unowned items in current preview
    final unownedItemIds = _previewEquippedItems.values
        .where((id) => !user.purchasedCharacterItemIds.contains(id))
        .toSet();

    if (unownedItemIds.isEmpty) {
      // All owned -> Just save
      await characterController.updateEquippedCharacterItems(
          user.uid, _previewEquippedItems);
      if (mounted) {
        MemoNotification.show(
            context,
            AppLocalizations.of(context)?.get('decorationSaved') ??
                'Settings saved! ✨');
        context.pop();
      }
      return;
    }

    // 2. Prepare items for bulk purchase
    final unownedItems = CharacterAssets.items
        .where((item) => unownedItemIds.contains(item.id))
        .toList();

    final selectedIds = unownedItems.map((e) => e.id).toSet();
    final isEnabledNotifier = ValueNotifier<bool>(true);

    // 3. Show Bulk Purchase Dialog
    if (!mounted) return;

    final shouldPurchase = await AppDialog.show<bool>(
      context: context,
      key: AppDialogKey.purchase,
      content: _BulkPurchaseContent(
        items: unownedItems,
        onSelectionChanged: (ids) {
          selectedIds.clear();
          selectedIds.addAll(ids);
          isEnabledNotifier.value = ids.isNotEmpty;
        },
      ),
      actions: [
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('cancel') ?? 'Cancel',
          onPressed: (context) => Navigator.pop(context, false),
        ),
        AppDialogAction(
          label: AppLocalizations.of(context)?.get('bulkPurchase') ??
              'Bulk Purchase',
          isPrimary: true,
          isEnabled: isEnabledNotifier,
          onPressed: (context) => Navigator.pop(context, true),
        ),
      ],
    );

    if (shouldPurchase == true) {
      final itemsToBuy =
          unownedItems.where((i) => selectedIds.contains(i.id)).toList();
      int finalPrice = itemsToBuy.fold(0, (sum, i) => sum + i.price);

      if (user.points < finalPrice) {
        if (mounted) {
          MemoNotification.show(
              context,
              AppLocalizations.of(context)?.get('notEnoughBranch') ??
                  'Not enough branches.');
        }
        return;
      }

      try {
        // Bulk purchase
        for (var item in itemsToBuy) {
          await characterController.purchaseCharacterItem(
              user.uid, item.id, item.price);
        }

        // Save (Only if all unowned items in preview were purchased, or we just save what we have)
        // If the user deselected something, they won't own it, so it shouldn't be equipped?
        // Actually, if they deselect it, they don't buy it, so they don't own it.
        // We should probably only save the items they own (including the newly purchased ones).

        // Remove unpurchased items from preview before saving
        final newPreviewEquipped =
            Map<String, String>.from(_previewEquippedItems);
        final unpurchasedIds =
            unownedItemIds.where((id) => !selectedIds.contains(id));

        newPreviewEquipped
            .removeWhere((key, value) => unpurchasedIds.contains(value));

        // Also update local state to reflect removal
        setState(() {
          _previewEquippedItems = newPreviewEquipped;
        });

        await characterController.updateEquippedCharacterItems(
            user.uid, newPreviewEquipped);

        if (mounted) {
          MemoNotification.show(
              context,
              AppLocalizations.of(context)?.get('purchaseAndSaveSuccess') ??
                  'Purchase and Save Complete! ✨');
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          MemoNotification.show(context,
              '${AppLocalizations.of(context)?.get('error') ?? 'Error'}: $e');
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
    VoidCallback? onPriceClick,
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
                        : Image.asset(item.imagePath!,
                            cacheWidth: 150, fit: BoxFit.contain))
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
                AppLocalizations.of(context)?.get('item_name_${item.id}') ??
                    item.name,
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

            // Price Button (Only if not owned)
            if (!isOwned)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onPriceClick, // Trigger purchase dialog
                  child: SizedBox(
                    height: 24,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/WakeUp_Button.png',
                          width: double.infinity,
                          height: 24,
                          fit: BoxFit.fill,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/branch.png',
                              width: 12,
                              height: 12,
                              cacheWidth: 48,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.price}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5D4037),
                                fontFamily: 'BMJUA',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

  Future<void> _showSinglePurchaseDialog(RoomAsset item, dynamic user) async {
    final characterController = context.read<CharacterController>();
    final canAfford = user.points >= item.price;
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    final shouldPurchase = await AppDialog.show<bool>(
      context: context,
      key: AppDialogKey.purchase,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: item.imagePath != null
                ? SizedBox(
                    width: 100,
                    height: 100,
                    child: item.imagePath!.endsWith('.svg')
                        ? SvgPicture.asset(
                            item.imagePath!,
                            fit: BoxFit.contain,
                          )
                        : Image.asset(
                            item.imagePath!,
                            fit: BoxFit.contain,
                          ),
                  )
                : Icon(
                    item.icon,
                    size: 60,
                    color: item.color ?? colorScheme.primaryButton,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)
                    ?.getFormat('purchaseConfirm', {'item': item.name}) ??
                'Do you want to purchase ${item.name}?',
            style: const TextStyle(fontFamily: 'BMJUA'),
          ),
          const SizedBox(height: 12),
          if (!canAfford) ...[
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)?.get('notEnoughBranch') ??
                  'Not enough branches.',
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'BMJUA',
              ),
            ),
          ],
        ],
      ),
      actions: [
        AppDialogAction(
          label: '${item.price}',
          labelWidget: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/branch.png',
                width: 18,
                height: 18,
                cacheWidth: 72,
              ),
              const SizedBox(width: 6),
              Text(
                '${item.price}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  fontFamily: 'BMJUA',
                ),
              ),
            ],
          ),
          isPrimary: true,
          isFullWidth: true,
          isEnabled: AlwaysStoppedAnimation<bool>(canAfford),
          onPressed: (context) => Navigator.pop(context, true),
        ),
      ],
    );

    if (shouldPurchase == true) {
      try {
        await characterController.purchaseCharacterItem(
            user.uid, item.id, item.price);

        if (!mounted) return;

        // Show success
        await AppDialog.show<String>(
          context: context,
          key: AppDialogKey.purchaseComplete,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Center(
                child: item.imagePath != null
                    ? SizedBox(
                        width: 120,
                        height: 120,
                        child: item.imagePath!.endsWith('.svg')
                            ? SvgPicture.asset(
                                item.imagePath!,
                                fit: BoxFit.contain,
                              )
                            : Image.asset(
                                item.imagePath!,
                                fit: BoxFit.contain,
                              ),
                      )
                    : Icon(
                        item.icon,
                        size: 100,
                        color: item.color ?? colorScheme.primaryButton,
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                '${item.name}을(를) 구매했습니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontFamily: 'BMJUA'),
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            AppDialogAction(
              label: '확인',
              isPrimary: true,
              onPressed: (context) => Navigator.pop(context),
            ),
          ],
        );
      } catch (e) {
        if (!mounted) return;
        MemoNotification.show(
            context, e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }
}

class _BulkPurchaseContent extends StatefulWidget {
  final List<RoomAsset> items;
  final ValueChanged<Set<String>> onSelectionChanged;

  const _BulkPurchaseContent({
    required this.items,
    required this.onSelectionChanged,
  });

  @override
  State<_BulkPurchaseContent> createState() => _BulkPurchaseContentState();
}

class _BulkPurchaseContentState extends State<_BulkPurchaseContent> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.items.map((e) => e.id).toSet();
  }

  int get _totalPrice => widget.items
      .where((item) => _selectedIds.contains(item.id))
      .fold(0, (sum, item) => sum + item.price);

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      widget.onSelectionChanged(_selectedIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '구매하지 않은 상품이 있습니다.\n일괄 구매하시겠습니까?',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'BMJUA', fontSize: 16),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: widget.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final isSelected = _selectedIds.contains(item.id);

              return GestureDetector(
                onTap: () => _toggleSelection(item.id),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: isSelected
                          ? Image.asset('assets/images/Check_Icon.png')
                          : Center(
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFD7CCC8), width: 2),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      child: item.imagePath != null
                          ? (item.imagePath!.endsWith('.svg')
                              ? SvgPicture.asset(item.imagePath!)
                              : Image.asset(item.imagePath!))
                          : Icon(item.icon),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontFamily: 'BMJUA',
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Image.asset('assets/images/branch.png',
                            width: 14, height: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${item.price}',
                          style: const TextStyle(
                            fontFamily: 'BMJUA',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '총 합계: ',
              style: TextStyle(fontFamily: 'BMJUA', fontSize: 16),
            ),
            Image.asset('assets/images/branch.png', width: 20, height: 20),
            const SizedBox(width: 4),
            Text(
              '$_totalPrice',
              style: const TextStyle(
                fontFamily: 'BMJUA',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/constants/room_assets.dart';
import '../../../core/constants/character_assets.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../../core/localization/app_localizations.dart';
import '../controllers/character_controller.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'wallpaper';
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isUnownedOnly = false;

  final Map<String, String> _categoryNames = {
    'wallpaper': '벽지',
    'background': '배경',
    'prop': '소품',
    'floor': '바닥',
    'character': '캐릭터',
    'emoticon': '이모티콘',
  };

  late final List<String> _categories = _categoryNames.keys.toList();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CharacterController>().loadRewardedAd();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final characterController = context.watch<CharacterController>();
    final user = characterController.currentUser;

    if (user == null) {
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFDF7E2),
          image: DecorationImage(
            image: ResizeImage(AssetImage('assets/images/Store_Background.png'),
                width: 1080),
            fit: BoxFit.cover,
          ),
        ),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFDF7E2),
        image: DecorationImage(
          image: ResizeImage(AssetImage('assets/images/Store_Background.png'),
              width: 1080),
          fit: BoxFit.cover,
        ),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'BMJUA',
          color: Colors.black87,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)?.get('shop') ?? 'Shop',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'BMJUA',
                color: Color(0xFF4E342E),
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(left: 16),
                color: Colors.transparent,
                child: Image.asset(
                  'assets/icons/X_Button.png',
                  width: 55,
                  height: 55,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            leadingWidth: 72,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16, top: 6, bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Item_Background.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/branch.png',
                      width: 20,
                      height: 20,
                      cacheWidth: 80,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user.points}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'BMJUA',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)?.get('branch') ?? 'Branch',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'BMJUA',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // 광고 보기 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: _buildAdButton(
                    user, colorScheme, context.read<CharacterController>()),
              ),

              // 카테고리 탭
              Container(
                width: double.infinity,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Tab_Background.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _categoryNames.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildTabItem(
                          context,
                          AppLocalizations.of(context)?.get(entry.key) ??
                              entry.value,
                          _selectedCategory == entry.key,
                          () {
                            final index = _categories.indexOf(entry.key);
                            setState(() {
                              _currentIndex = index;
                              _selectedCategory = entry.key;
                            });
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 아이템 리스트 (Stack으로 필터 버튼 오버레이)
              Expanded(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                          _selectedCategory = _categories[index];
                        });
                      },
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        switch (category) {
                          case 'emoticon':
                            return _buildEmoticonGrid(
                                user, characterController, colorScheme);
                          case 'wallpaper':
                            return _buildWallpaperGrid(
                                user, characterController, colorScheme);
                          case 'background':
                            return _buildBackgroundGrid(
                                user, characterController, colorScheme);
                          case 'prop':
                            return _buildPropGrid(
                                user, characterController, colorScheme);
                          case 'floor':
                            return _buildFloorGrid(
                                user, characterController, colorScheme);
                          case 'character':
                            return _buildCharacterGrid(
                                user, characterController, colorScheme);
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),

                    // 미보유 필터 버튼 (Floating)
                    Positioned(
                      top: 0,
                      left: 20,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isUnownedOnly = !_isUnownedOnly;
                          });
                        },
                        child: Container(
                          width: 105, // 너비 축소 (기존 120)
                          height: 40,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                  'assets/images/Message_Button.png'),
                              fit: BoxFit.fill,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 커스텀 체크박스
                              Container(
                                width: 20,
                                height: 20,
                                decoration: _isUnownedOnly
                                    ? null
                                    : BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.transparent,
                                        border: Border.all(
                                          color: const Color(0xFF5D4037),
                                          width: 1.5,
                                        ),
                                      ),
                                child: _isUnownedOnly
                                    ? Image.asset(
                                        'assets/images/Check_Icon.png',
                                        fit: BoxFit.contain,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)?.get('unowned') ??
                                    'Unowned',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(
      BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(isSelected
                ? 'assets/images/ShopTab_ButtonClick.png'
                : 'assets/images/ShopTab_Button.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'BMJUA',
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF5D4E37),
          ),
        ),
      ),
    );
  }

  Widget _buildAdButton(
      user, AppColorScheme colorScheme, CharacterController controller) {
    // 오늘 광고 시청 횟수 제한 체크 (로컬)
    int currentCount = user.adRewardCount;
    final now = DateTime.now();
    final lastDate = user.lastAdRewardDate;

    if (lastDate != null &&
        (lastDate.year != now.year ||
            lastDate.month != now.month ||
            lastDate.day != now.day)) {
      currentCount = 0;
    }

    final bool isLimitReached = currentCount >= 10;

    return Container(
      width: double.infinity,
      // 메모 이미지의 비율과 패딩 고려 (배경 이미지에 내용이 잘 들어가도록)
      padding: const EdgeInsets.symmetric(
          horizontal: 32, vertical: 16), // 세로 패딩 24 -> 16 축소
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Memo.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        children: [
          // 아이콘 혹은 이미지
          Image.asset(
            'assets/icons/Megaphone_Icon.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)?.get('watchAdGetBranch') ??
                      'Watch Ad Get 10 Branches',
                  style: const TextStyle(
                    color: Color(0xFF5D4037), // 갈색 계열 (메모지에 어울리는)
                    fontSize: 14, // 16 -> 14 축소 (영어 텍스트 길어질 수 있음)
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BMJUA',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Image.asset('assets/images/branch.png',
                        width: 14, height: 14, cacheWidth: 56), // 16 -> 14 축소
                    const SizedBox(width: 4),
                    Text(
                      '+10 ${AppLocalizations.of(context)?.get('branch') ?? 'Branches'}',
                      style: const TextStyle(
                        color: Color(0xFF8D6E63),
                        fontSize: 14, // 16 -> 14 축소
                        fontWeight: FontWeight.bold,
                        fontFamily: 'BMJUA',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($currentCount/10)',
                      style: const TextStyle(
                        color: Color(0xFF8D6E63),
                        fontSize: 12, // 14 -> 12 축소
                        fontFamily: 'BMJUA',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 보기 버튼 (Confirm_Button.png)
          GestureDetector(
            onTap: isLimitReached || controller.isAdLoading
                ? null
                : () => controller.showRewardedAd(context),
            child: Opacity(
              opacity: isLimitReached || controller.isAdLoading ? 0.5 : 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/Confirm_Button.png',
                    width: 70, // 적절한 크기 조절
                    height: 40,
                    fit: BoxFit.fill,
                  ),
                  Text(
                    isLimitReached
                        ? (AppLocalizations.of(context)?.get('completed') ??
                            'Completed')
                        : (AppLocalizations.of(context)?.get('watch') ??
                            'Watch'),
                    style: const TextStyle(
                      color: Color(0xFF5D4037), // 갈색으로 변경
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'BMJUA',
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

  Widget _buildCharacterGrid(user, characterController, colorScheme) {
    var purchasableItems =
        CharacterAssets.items.where((i) => i.price > 0).toList();

    if (_isUnownedOnly) {
      purchasableItems = purchasableItems
          .where((i) => !user.purchasedCharacterItemIds.contains(i.id))
          .toList();
    }

    return _buildGrid(purchasableItems, (item) {
      final isPurchased = user.purchasedCharacterItemIds.contains(item.id);
      return _buildShopItem(
        item: item,
        isPurchased: isPurchased,
        onPurchase: (price) =>
            characterController.purchaseCharacterItem(user.uid, item.id, price),
        colorScheme: colorScheme,
      );
    });
  }

  Widget _buildEmoticonGrid(user, characterController, colorScheme) {
    var purchasableEmoticons =
        RoomAssets.emoticons.where((e) => e.price > 0).toList();

    if (_isUnownedOnly) {
      purchasableEmoticons = purchasableEmoticons
          .where((e) => !user.purchasedEmoticonIds.contains(e.id))
          .toList();
    }

    return _buildGrid(purchasableEmoticons, (item) {
      final isPurchased = user.purchasedEmoticonIds.contains(item.id);
      return _buildShopItem(
        item: item,
        isPurchased: isPurchased,
        onPurchase: (price) =>
            characterController.purchaseEmoticon(user.uid, item.id, price),
        colorScheme: colorScheme,
      );
    });
  }

  Widget _buildWallpaperGrid(user, characterController, colorScheme) {
    var purchasableWallpapers =
        RoomAssets.wallpapers.where((w) => w.price > 0).toList();

    if (_isUnownedOnly) {
      purchasableWallpapers = purchasableWallpapers
          .where((w) => !user.purchasedThemeIds.contains(w.id))
          .toList();
    }

    return _buildGrid(purchasableWallpapers, (item) {
      final isPurchased = user.purchasedThemeIds.contains(item.id);
      return _buildShopItem(
        item: item,
        isPurchased: isPurchased,
        onPurchase: (price) =>
            characterController.purchaseWallpaper(user.uid, item.id, price),
        colorScheme: colorScheme,
      );
    });
  }

  Widget _buildBackgroundGrid(user, characterController, colorScheme) {
    var purchasableBackgrounds =
        RoomAssets.backgrounds.where((b) => b.price > 0).toList();

    if (_isUnownedOnly) {
      purchasableBackgrounds = purchasableBackgrounds
          .where((b) => !user.purchasedBackgroundIds.contains(b.id))
          .toList();
    }

    return _buildGrid(purchasableBackgrounds, (item) {
      final isPurchased = user.purchasedBackgroundIds.contains(item.id);
      return _buildShopItem(
        item: item,
        isPurchased: isPurchased,
        onPurchase: (price) =>
            characterController.purchaseBackground(user.uid, item.id, price),
        colorScheme: colorScheme,
      );
    });
  }

  Widget _buildPropGrid(user, characterController, colorScheme) {
    var purchasableProps = RoomAssets.props.where((p) => p.price > 0).toList();

    if (_isUnownedOnly) {
      purchasableProps = purchasableProps
          .where((p) => !user.purchasedPropIds.contains(p.id))
          .toList();
    }

    return _buildGrid(purchasableProps, (item) {
      final isPurchased = user.purchasedPropIds.contains(item.id);
      return _buildShopItem(
        item: item,
        isPurchased: isPurchased,
        onPurchase: (price) =>
            characterController.purchaseProp(user.uid, item.id, price),
        colorScheme: colorScheme,
      );
    });
  }

  Widget _buildFloorGrid(user, characterController, colorScheme) {
    var purchasableFloors =
        RoomAssets.floors.where((f) => f.price > 0).toList();

    if (_isUnownedOnly) {
      purchasableFloors = purchasableFloors
          .where((f) => !user.purchasedFloorIds.contains(f.id))
          .toList();
    }

    return _buildGrid(purchasableFloors, (item) {
      final isPurchased = user.purchasedFloorIds.contains(item.id);
      return _buildShopItem(
        item: item,
        isPurchased: isPurchased,
        onPurchase: (price) =>
            characterController.purchaseFloor(user.uid, item.id, price),
        colorScheme: colorScheme,
      );
    });
  }

  Widget _buildGrid(
      List<RoomAsset> items, Widget Function(RoomAsset) itemBuilder) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(items[index]),
    );
  }

  Widget _buildShopItem({
    required RoomAsset item,
    required bool isPurchased,
    required Future<void> Function(int price) onPurchase,
    required AppColorScheme colorScheme,
  }) {
    // 상품마다 고정된 랜덤 배경 이미지를 사용하기 위해 hashCode를 활용
    final cardIndex = (item.hashCode % 6) + 1;
    final cardBgImage = 'assets/icons/Friend_Card$cardIndex.png';

    return Builder(builder: (itemContext) {
      final controller = itemContext.read<CharacterController>();
      final discountedPrice =
          controller.getDiscountedPrice(item.id, item.price);
      final isDiscounted = discountedPrice < item.price;
      final canAfford = controller.currentUser!.points >= discountedPrice;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            // 배경 이미지 비율에 맞춰 내용을 배치
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // 아이템 이미지
                Container(
                  width: 40, // 56 -> 40 축소
                  height: 40, // 56 -> 40 축소
                  alignment: Alignment.center,
                  child: item.imagePath != null
                      ? (item.imagePath!.endsWith('.svg')
                          ? SvgPicture.asset(item.imagePath!,
                              fit: BoxFit.contain)
                          : Image.asset(item.imagePath!,
                              cacheWidth: 150, fit: BoxFit.contain))
                      : Icon(item.icon,
                          color: item.color ?? colorScheme.primaryButton,
                          size: 24), // 32 -> 24 축소
                ),
                const SizedBox(height: 8),
                // 아이템 이름
                Text(
                  AppLocalizations.of(context)?.get('item_name_${item.id}') ??
                      item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BMJUA',
                    color: Color(0xFF5D4037),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),

                // 구매 버튼 (WakeUp_Button.png 배경)
                GestureDetector(
                  onTap: isPurchased
                      ? null
                      : () async {
                          final l10n = AppLocalizations.of(itemContext);
                          final localizedName =
                              l10n?.get('item_name_${item.id}') ?? item.name;

                          final shouldPurchase = await AppDialog.show<bool>(
                            context: itemContext,
                            key: AppDialogKey.purchase,
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: item.imagePath != null
                                      ? SizedBox(
                                          width: 100,
                                          height: 100,
                                          child:
                                              item.imagePath!.endsWith('.svg')
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
                                          color: item.color ??
                                              colorScheme.primaryButton,
                                        ),
                                ),
                                const SizedBox(height: 16),
                                const SizedBox(height: 16),
                                Text(
                                  l10n?.getFormat('purchaseConfirm',
                                          {'item': localizedName}) ??
                                      'Do you want to purchase $localizedName?',
                                  style: const TextStyle(fontFamily: 'BMJUA'),
                                ),
                                const SizedBox(height: 12),
                                if (isDiscounted)
                                  Text(
                                    l10n?.getFormat('salePrice', {
                                          'original': item.price.toString(),
                                          'discounted':
                                              discountedPrice.toString()
                                        }) ??
                                        'SALE! ${item.price} -> $discountedPrice 가지',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'BMJUA',
                                    ),
                                  ),
                                if (!canAfford) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n?.get('notEnoughBranch') ??
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
                                label: '$discountedPrice',
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
                                      '$discountedPrice',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        height: 1.1,
                                        fontFamily: 'BMJUA',
                                        color: isDiscounted ? Colors.red : null,
                                      ),
                                    ),
                                  ],
                                ),
                                isPrimary: true,
                                isFullWidth: true,
                                isEnabled:
                                    AlwaysStoppedAnimation<bool>(canAfford),
                                onPressed: (context) =>
                                    Navigator.pop(context, true),
                              ),
                            ],
                          );

                          if (shouldPurchase == true) {
                            try {
                              await onPurchase(discountedPrice);
                              if (mounted) {
                                final result = await AppDialog.show<String>(
                                  context: context,
                                  key: AppDialogKey.purchaseComplete,
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 16),
                                      Center(
                                        child: item.imagePath != null
                                            ? SizedBox(
                                                width: 120,
                                                height: 120,
                                                child: item.imagePath!
                                                        .endsWith('.svg')
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
                                                color: item.color ??
                                                    colorScheme.primaryButton,
                                              ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        l10n?.getFormat('purchaseSuccess',
                                                {'item': localizedName}) ??
                                            '$localizedName을(를) 구매했습니다.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 16, fontFamily: 'BMJUA'),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                  actions: [
                                    AppDialogAction(
                                      label:
                                          l10n?.get('decorate') ?? 'Decorate',
                                      onPressed: (context) {
                                        Navigator.pop(context, 'decorate');
                                      },
                                    ),
                                    AppDialogAction(
                                      label: l10n?.get('confirm') ?? 'Confirm',
                                      isPrimary: true,
                                      onPressed: (context) =>
                                          Navigator.pop(context),
                                    ),
                                  ],
                                );

                                if (mounted && result == 'decorate') {
                                  // 캐릭터 아이템이면 캐릭터 꾸미기 화면으로, 아니면 방 꾸미기 화면으로
                                  final isCharacterItem = CharacterAssets.items
                                      .any((i) => i.id == item.id);
                                  if (isCharacterItem) {
                                    context.push('/character-decoration');
                                  } else {
                                    context.push('/decoration');
                                  }
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                MemoNotification.show(
                                    context,
                                    e
                                        .toString()
                                        .replaceFirst('Exception: ', ''));
                              }
                            }
                          }
                        },
                  child: Opacity(
                    opacity: isPurchased ? 0.7 : 1.0,
                    child: SizedBox(
                      width: double
                          .infinity, // 너비를 약간 제한하여 너무 뚱뚱해지지 않게 함 (필요 시 조절)
                      height: 20, // 높이를 36 -> 30으로 줄임
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/WakeUp_Button.png',
                            width: double.infinity,
                            height: 30,
                            fit: BoxFit.fill,
                            filterQuality:
                                FilterQuality.none, // 픽셀 깨짐 방지 (선명하게)
                          ),
                          Center(
                            child: isPurchased
                                ? Text(
                                    AppLocalizations.of(itemContext)
                                            ?.get('owned') ??
                                        'Owned',
                                    style: const TextStyle(
                                      fontSize: 11, // 폰트 사이즈 살짝 축소
                                      color: Color(0xFF5D4037), // 갈색으로 변경
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'BMJUA',
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/branch.png',
                                        width: 12, // 아이콘 사이즈 살짝 축소
                                        height: 12,
                                        cacheWidth: 48,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$discountedPrice',
                                        style: TextStyle(
                                          fontSize: 12, // 폰트 사이즈 살짝 축소
                                          fontWeight: FontWeight.bold,
                                          color: isDiscounted
                                              ? Colors.red
                                              : const Color(0xFF5D4037),
                                          fontFamily: 'BMJUA',
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isDiscounted && !isPurchased)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  AppLocalizations.of(itemContext)?.get('sale') ?? 'SALE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          if (isPurchased)
            Center(
              child: Opacity(
                opacity: 0.9,
                child: Image.asset(
                  AppLocalizations.of(context)?.locale.languageCode == 'en'
                      ? 'assets/icons/Purchase_IconEng.png'
                      : 'assets/icons/purchase_Icon.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      );
    });
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/constants/room_assets.dart';
import '../../../core/constants/character_assets.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../controllers/character_controller.dart';
import '../../../services/asset_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // 오늘의 상점 카운트다운 타이머
  Timer? _countdownTimer;
  Duration _timeUntilReset = Duration.zero;

  List<RoomAsset>? _todayShopItems;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CharacterController>().loadRewardedAd();
      _loadTodayShopItems();
    });
    AssetService().fetchDynamicAssets().then((_) {
      if (mounted) {
        setState(() {});
        _loadTodayShopItems();
      }
    });

    _startCountdownTimer();
  }

  Future<void> _loadTodayShopItems() async {
    final user = context.read<CharacterController>().currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final dateKey = '${user.uid}_${now.year}_${now.month}_${now.day}';
    final savedKey = 'todayShopItems_$dateKey';

    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(savedKey);

    if (savedIds != null && savedIds.isNotEmpty) {
      final allAssets = [
        ...RoomAssets.wallpapers,
        ...RoomAssets.backgrounds,
        ...RoomAssets.floors,
        ...RoomAssets.props,
        ...CharacterAssets.items,
        ...RoomAssets.emoticons,
      ];
      final Map<String, RoomAsset> assetMap = {
        for (var e in allAssets) e.id: e
      };

      if (mounted) {
        setState(() {
          _todayShopItems = savedIds
              .map((id) => assetMap[id])
              .whereType<RoomAsset>()
              .toList();
        });
      }
      return;
    }

    // fallback: generate deterministically from unowned items
    final generated = _generateTodayShopItemsFallback(user);
    await prefs.setStringList(savedKey, generated.map((e) => e.id).toList());

    if (mounted) {
      setState(() {
        _todayShopItems = generated;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _updateTimeUntilReset();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeUntilReset();
    });
  }

  void _updateTimeUntilReset() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    setState(() {
      _timeUntilReset = midnight.difference(now);
    });
  }

  String _formatCountdown(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// 오늘의 상점 아이템 생성 (최초 실행 또는 리셋 시)
  List<RoomAsset> _generateTodayShopItemsFallback(dynamic user) {
    final now = DateTime.now();
    final daySeed = now.year * 10000 + now.month * 100 + now.day;
    final userSeed = user.uid.hashCode;
    final random = Random(daySeed ^ userSeed);

    // 각 카테고리별 미보유 상품 목록
    final unownedWallpapers = RoomAssets.wallpapers
        .where((w) => w.price > 0 && !user.purchasedThemeIds.contains(w.id))
        .toList();
    final unownedBackgrounds = RoomAssets.backgrounds
        .where(
            (b) => b.price > 0 && !user.purchasedBackgroundIds.contains(b.id))
        .toList();
    final unownedFloors = RoomAssets.floors
        .where((f) => f.price > 0 && !user.purchasedFloorIds.contains(f.id))
        .toList();
    final unownedProps = RoomAssets.props
        .where((p) =>
            p.price > 0 &&
            p.id != 'sticky_note' &&
            !user.purchasedPropIds.contains(p.id))
        .toList();
    final unownedCharacterItems = CharacterAssets.items
        .where((i) =>
            i.price > 0 && !user.purchasedCharacterItemIds.contains(i.id))
        .toList();
    final unownedEmoticons = RoomAssets.emoticons
        .where((e) => e.price > 0 && !user.purchasedEmoticonIds.contains(e.id))
        .toList();
    final unownedWindows = RoomAssets.windows
        .where((w) =>
            w.id != 'default' &&
            w.price > 0 &&
            !user.purchasedWindowIds.contains(w.id))
        .toList();

    // 기본 비율: 벽지1, 배경1, 바닥1, 소품2, 캐릭터1 = 6개
    // 유동성 적용: 각 카테고리 +-1 범위로 랜덤하게 조절
    int wallpaperCount = _randomAdjust(1, random, unownedWallpapers.length);
    int backgroundCount = _randomAdjust(1, random, unownedBackgrounds.length);
    int floorCount = _randomAdjust(1, random, unownedFloors.length);
    int characterCount = _randomAdjust(1, random, unownedCharacterItems.length);
    int emoticonCount = _randomAdjust(0, random, unownedEmoticons.length);
    int windowCount = _randomAdjust(0, random, unownedWindows.length);

    // 나머지는 소품으로 채움 (총 6개)
    int propCount = 6 -
        wallpaperCount -
        backgroundCount -
        floorCount -
        characterCount -
        emoticonCount -
        windowCount;
    propCount = propCount.clamp(0, unownedProps.length);

    // 총합이 6보다 적을 경우 소품에서 보충
    int total = wallpaperCount +
        backgroundCount +
        floorCount +
        propCount +
        characterCount +
        emoticonCount +
        windowCount;
    if (total < 6) {
      final extra = min(6 - total, unownedProps.length - propCount);
      propCount += extra;
    }

    final List<RoomAsset> result = [];

    final seedForSorting = daySeed ^ userSeed;

    // 각 카테고리에서 랜덤(하지만 하루 종일 고정된 순서로) 선택
    _addDeterministicItems(
        result, unownedWallpapers, wallpaperCount, seedForSorting);
    _addDeterministicItems(
        result, unownedBackgrounds, backgroundCount, seedForSorting);
    _addDeterministicItems(result, unownedFloors, floorCount, seedForSorting);
    _addDeterministicItems(result, unownedProps, propCount, seedForSorting);
    _addDeterministicItems(
        result, unownedCharacterItems, characterCount, seedForSorting);
    _addDeterministicItems(
        result, unownedEmoticons, emoticonCount, seedForSorting);
    _addDeterministicItems(result, unownedWindows, windowCount, seedForSorting);

    // 결과도 아이디와 시드 기반으로 섞어줍니다 (순서 고정)
    result.sort((a, b) {
      final rA = Random(a.id.hashCode ^ seedForSorting).nextInt(100000);
      final rB = Random(b.id.hashCode ^ seedForSorting).nextInt(100000);
      return rA.compareTo(rB);
    });
    if (result.length > 6) {
      return result.take(6).toList();
    }
    return result;
  }

  int _randomAdjust(int base, Random random, int maxAvailable) {
    final delta = random.nextInt(3) - 1; // -1, 0, +1
    final adjusted = (base + delta).clamp(0, maxAvailable);
    return adjusted;
  }

  void _addDeterministicItems(
      List<RoomAsset> result, List<RoomAsset> source, int count, int seed) {
    if (source.isEmpty || count <= 0) return;
    final sorted = List<RoomAsset>.from(source)
      ..sort((a, b) {
        final rA = Random(a.id.hashCode ^ seed).nextInt(1000000);
        final rB = Random(b.id.hashCode ^ seed).nextInt(1000000);
        return rA.compareTo(rB);
      });
    result.addAll(sorted.take(count));
  }

  /// 세일 중인 상품 목록
  List<RoomAsset> _getSaleItems(CharacterController controller) {
    final discounts = controller.shopDiscounts;
    if (discounts.isEmpty) return [];

    final List<RoomAsset> saleItems = [];
    for (final entry in discounts.entries) {
      final itemId = entry.key;
      RoomAsset? item;
      item = RoomAssets.wallpapers.where((w) => w.id == itemId).firstOrNull;
      item ??= RoomAssets.backgrounds.where((b) => b.id == itemId).firstOrNull;
      item ??= RoomAssets.floors.where((f) => f.id == itemId).firstOrNull;
      item ??= RoomAssets.props.where((p) => p.id == itemId).firstOrNull;
      item ??= RoomAssets.emoticons.where((e) => e.id == itemId).firstOrNull;
      item ??= RoomAssets.windows.where((w) => w.id == itemId).firstOrNull;
      item ??= CharacterAssets.items.where((i) => i.id == itemId).firstOrNull;
      if (item != null) saleItems.add(item);
    }
    return saleItems;
  }

  /// 최근 2주 이내 출시된 상품 목록
  List<RoomAsset> _getRecentItems() {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    final List<RoomAsset> recentItems = [];

    void addRecent(List<RoomAsset> items) {
      for (final item in items) {
        if (item.releasedAt != null && item.releasedAt!.isAfter(twoWeeksAgo)) {
          recentItems.add(item);
        }
      }
    }

    addRecent(RoomAssets.wallpapers);
    addRecent(RoomAssets.backgrounds);
    addRecent(RoomAssets.floors);
    addRecent(RoomAssets.props);
    addRecent(RoomAssets.windows);
    addRecent(RoomAssets.emoticons);
    addRecent(CharacterAssets.items);

    // 최신순 정렬
    recentItems.sort((a, b) => (b.releasedAt ?? DateTime(2000))
        .compareTo(a.releasedAt ?? DateTime(2000)));

    return recentItems;
  }

  /// 카테고리별 구매 함수 결정
  Future<void> Function(int price) _getPurchaseFunction(
      RoomAsset item, CharacterController controller, String uid) {
    if (RoomAssets.wallpapers.any((w) => w.id == item.id)) {
      return (price) => controller.purchaseWallpaper(uid, item.id, price);
    } else if (RoomAssets.backgrounds.any((b) => b.id == item.id)) {
      return (price) => controller.purchaseBackground(uid, item.id, price);
    } else if (RoomAssets.floors.any((f) => f.id == item.id)) {
      return (price) => controller.purchaseFloor(uid, item.id, price);
    } else if (RoomAssets.props.any((p) => p.id == item.id)) {
      if (item.category == 'window') {
        return (price) => controller.purchaseWindow(uid, item.id, price);
      }
      return (price) => controller.purchaseProp(uid, item.id, price);
    } else if (RoomAssets.windows.any((w) => w.id == item.id)) {
      return (price) => controller.purchaseWindow(uid, item.id, price);
    } else if (RoomAssets.emoticons.any((e) => e.id == item.id)) {
      return (price) => controller.purchaseEmoticon(uid, item.id, price);
    } else {
      return (price) => controller.purchaseCharacterItem(uid, item.id, price);
    }
  }

  /// 아이템이 구매되었는지 확인
  bool _isItemPurchased(RoomAsset item, dynamic user) {
    if (RoomAssets.wallpapers.any((w) => w.id == item.id)) {
      return user.purchasedThemeIds.contains(item.id);
    } else if (RoomAssets.backgrounds.any((b) => b.id == item.id)) {
      return item.id == 'default' ||
          item.id == 'none' ||
          user.purchasedBackgroundIds.contains(item.id);
    } else if (RoomAssets.floors.any((f) => f.id == item.id)) {
      return user.purchasedFloorIds.contains(item.id);
    } else if (RoomAssets.props.any((p) => p.id == item.id)) {
      if (item.category == 'window') {
        return item.id == 'default' ||
            user.purchasedWindowIds.contains(item.id);
      }
      return user.purchasedPropIds.contains(item.id);
    } else if (RoomAssets.windows.any((w) => w.id == item.id)) {
      return item.id == 'default' || user.purchasedWindowIds.contains(item.id);
    } else if (RoomAssets.emoticons.any((e) => e.id == item.id)) {
      return user.purchasedEmoticonIds.contains(item.id);
    } else {
      return user.purchasedCharacterItemIds.contains(item.id);
    }
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

    final saleItems = _getSaleItems(characterController);
    final todayItems = _todayShopItems ?? [];
    final recentItems = _getRecentItems();

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
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                }
              },
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
                      style: const TextStyle(
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
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewPadding.bottom + 30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 광고 보기 버튼
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: _buildAdButton(
                      user, colorScheme, context.read<CharacterController>()),
                ),

                // 오늘의 상점 섹션
                if (todayItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildSectionHeader(
                    titleWidget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          AppLocalizations.of(context)?.locale.languageCode ==
                                  'ko'
                              ? 'assets/images/TodayShop_Kor.png'
                              : 'assets/images/TodayShop_Eng.png',
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time,
                                size: 14, color: Color(0xFF8D6E63)),
                            const SizedBox(width: 4),
                            Text(
                              _formatCountdown(_timeUntilReset),
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'BMJUA',
                                color: Color(0xFF8D6E63),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildItemGrid(
                    items: todayItems,
                    user: user,
                    characterController: characterController,
                    colorScheme: colorScheme,
                  ),
                ],

                // 세일 중인 상품 섹션
                if (saleItems.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    title:
                        '🔥 ${AppLocalizations.of(context)?.get('sale') ?? 'SALE'}',
                  ),
                  const SizedBox(height: 8),
                  _buildItemGrid(
                    items: saleItems,
                    user: user,
                    characterController: characterController,
                    colorScheme: colorScheme,
                  ),
                ],

                // 최근 출시 상품 섹션
                if (recentItems.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    titleWidget: Image.asset(
                      AppLocalizations.of(context)?.locale.languageCode == 'ko'
                          ? 'assets/images/NewItem_Kor.png'
                          : 'assets/images/NewItem_Eng.png',
                      height: 52,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildItemGrid(
                    items: recentItems,
                    user: user,
                    characterController: characterController,
                    colorScheme: colorScheme,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 섹션 헤더 위젯
  Widget _buildSectionHeader(
      {String? title, Widget? titleWidget, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (titleWidget != null)
              titleWidget
            else if (title != null)
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'BMJUA',
                  color: Color(0xFF4E342E),
                ),
              ),
            if (trailing != null)
              Positioned(
                right: 0,
                child: trailing,
              ),
          ],
        ),
      ),
    );
  }

  /// 아이템 3열 그리드 (shrinkWrap)
  Widget _buildItemGrid({
    required List<RoomAsset> items,
    required dynamic user,
    required CharacterController characterController,
    required AppColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isPurchased = _isItemPurchased(item, user);
          return _buildShopItem(
            item: item,
            isPurchased: isPurchased,
            onPurchase:
                _getPurchaseFunction(item, characterController, user.uid),
            colorScheme: colorScheme,
          );
        },
      ),
    );
  }

  Widget _buildAdButton(
      user, AppColorScheme colorScheme, CharacterController controller) {
    int currentCount = user.adRewardCount;
    final now = DateTime.now();
    final lastDate = user.lastAdRewardDate;

    if (lastDate != null &&
        (lastDate.year != now.year ||
            lastDate.month != now.month ||
            lastDate.day != now.day)) {
      currentCount = 0;
    }

    final bool isLimitReached = currentCount >= 5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Memo.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        children: [
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
                      'Watch Ad Get 20 Branches',
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'BMJUA',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Image.asset('assets/images/branch.png',
                        width: 14, height: 14, cacheWidth: 56),
                    const SizedBox(width: 4),
                    Text(
                      '+20 ${AppLocalizations.of(context)?.get('branch') ?? 'Branches'}',
                      style: const TextStyle(
                        color: Color(0xFF8D6E63),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'BMJUA',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($currentCount/5)',
                      style: const TextStyle(
                        color: Color(0xFF8D6E63),
                        fontSize: 12,
                        fontFamily: 'BMJUA',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                    width: 70,
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
                      color: Color(0xFF5D4037),
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

  String _getItemCategoryLabel(RoomAsset item, BuildContext context) {
    final isKo = AppLocalizations.of(context)?.locale.languageCode == 'ko';
    if (RoomAssets.backgrounds.any((e) => e.id == item.id))
      return isKo ? '배경' : 'Background';
    if (RoomAssets.floors.any((e) => e.id == item.id))
      return isKo ? '바닥' : 'Floor';
    if (RoomAssets.wallpapers.any((e) => e.id == item.id))
      return isKo ? '벽지' : 'Wallpaper';
    if (RoomAssets.emoticons.any((e) => e.id == item.id))
      return isKo ? '이모티콘' : 'Emoticon';
    if (RoomAssets.props.any((e) => e.id == item.id)) {
      if (item.category == 'window') return isKo ? '창문' : 'Window';
      return isKo ? '소품' : 'Prop';
    }
    if (RoomAssets.windows.any((e) => e.id == item.id))
      return isKo ? '창문' : 'Window';
    return isKo ? '캐릭터' : 'Character';
  }

  Widget _buildShopItem({
    required RoomAsset item,
    required bool isPurchased,
    required Future<void> Function(int price) onPurchase,
    required AppColorScheme colorScheme,
  }) {
    final cardIndex = (item.hashCode % 6) + 1;
    final cardBgImage = 'assets/icons/Friend_Card$cardIndex.png';

    return Builder(builder: (itemContext) {
      final controller = itemContext.read<CharacterController>();
      final discountedPrice =
          controller.getDiscountedPrice(item.id, item.price);
      final isDiscounted = discountedPrice < item.price;
      final canAfford = controller.currentUser!.points >= discountedPrice;

      void handleTap() async {
        if (isPurchased) return;
        final l10n = AppLocalizations.of(itemContext);
        final localizedName = item.getLocalizedName(itemContext);
        final categoryStr = _getItemCategoryLabel(item, itemContext);

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
                        child: NetworkOrAssetImage(
                          imagePath: item.imagePath!,
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
                '[$categoryStr]',
                style: TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 14,
                  color: colorScheme.textHint,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.getFormat('purchaseConfirm', {'item': localizedName}) ??
                    'Do you want to purchase $localizedName?',
                style: const TextStyle(fontFamily: 'BMJUA', fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (isDiscounted)
                Text(
                  l10n?.getFormat('salePrice', {
                        'original': item.price.toString(),
                        'discounted': discountedPrice.toString()
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
                  l10n?.get('notEnoughBranch') ?? 'Not enough branches.',
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
              isEnabled: AlwaysStoppedAnimation<bool>(canAfford),
              onPressed: (context) => Navigator.pop(context, true),
            ),
          ],
        );

        if (shouldPurchase == true) {
          try {
            await onPurchase(discountedPrice);
            if (mounted) {
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
                              child: NetworkOrAssetImage(
                                imagePath: item.imagePath!,
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
                      l10n?.getFormat(
                              'purchaseSuccess', {'item': localizedName}) ??
                          '$localizedName을(를) 구매했습니다.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontFamily: 'BMJUA'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                actions: [
                  AppDialogAction(
                    label: l10n?.get('close') ?? '닫기',
                    onPressed: (dialogCtx) => Navigator.pop(dialogCtx),
                  ),
                  AppDialogAction(
                    label: l10n?.get('decorate') ?? '꾸미기',
                    isPrimary: true,
                    onPressed: (dialogCtx) async {
                      Navigator.pop(dialogCtx);
                      // 다이얼로그가 닫히는 시간을 확보하여 Navigator lock 방지
                      await Future.delayed(Duration.zero);
                      if (!mounted) return;

                      final isCharacterItem =
                          CharacterAssets.items.any((i) => i.id == item.id);
                      if (isCharacterItem) {
                        context.push('/character-decoration');
                      } else {
                        context.push('/decoration');
                      }
                    },
                  ),
                ],
              );
            }
          } catch (e) {
            if (mounted) {
              MemoNotification.show(
                  context, e.toString().replaceFirst('Exception: ', ''));
            }
          }
        }
      }

      return GestureDetector(
        onTap: isPurchased ? null : handleTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
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
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: item.imagePath != null
                        ? NetworkOrAssetImage(
                            imagePath: item.imagePath!,
                            fit: BoxFit.contain,
                          )
                        : Icon(item.icon,
                            color: item.color ?? colorScheme.primaryButton,
                            size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.getLocalizedName(context),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'BMJUA',
                      color: Color(0xFF5D4037),
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  isPurchased
                      ? SizedBox(
                          width: double.infinity,
                          height: 20,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/icons/WakeUp_Button.png',
                                width: double.infinity,
                                height: 30,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.none,
                              ),
                              Text(
                                AppLocalizations.of(itemContext)
                                        ?.get('owned') ??
                                    'Owned',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF5D4037),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'BMJUA',
                                ),
                              ),
                            ],
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 20,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/icons/WakeUp_Button.png',
                                width: double.infinity,
                                height: 30,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.none,
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
                                    '$discountedPrice',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDiscounted
                                          ? Colors.red
                                          : const Color(0xFF5D4037),
                                      fontFamily: 'BMJUA',
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        ),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/constants/room_assets.dart';
import '../../../core/widgets/app_dialog.dart';
import '../controllers/character_controller.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final characterController = context.watch<CharacterController>();
    final user = characterController.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('상점', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.shadowColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.stars, color: colorScheme.pointStar, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${user.points}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('테마', Icons.palette),
            const SizedBox(height: 16),
            _buildThemeGrid(user, characterController, colorScheme),
            const SizedBox(height: 32),
            _buildSectionHeader('벽지', Icons.wallpaper),
            const SizedBox(height: 16),
            _buildWallpaperGrid(user, characterController, colorScheme),
            const SizedBox(height: 32),
            _buildSectionHeader('배경', Icons.landscape),
            const SizedBox(height: 16),
            _buildBackgroundGrid(user, characterController, colorScheme),
            const SizedBox(height: 32),
            _buildSectionHeader('소품', Icons.auto_awesome),
            const SizedBox(height: 16),
            _buildPropGrid(user, characterController, colorScheme),
            const SizedBox(height: 32),
            _buildSectionHeader('바닥', Icons.grid_on),
            const SizedBox(height: 16),
            _buildFloorGrid(user, characterController, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildThemeGrid(user, characterController, colorScheme) {
    final purchasableThemes =
        RoomAssets.themes.where((t) => t.price > 0).toList();
    return _buildGrid(purchasableThemes, (item) {
      final isPurchased = user.purchasedThemeIds.contains(item.id);
      return _buildShopItem(
        item: item,
        isPurchased: isPurchased,
        onPurchase: () =>
            characterController.purchaseTheme(user.uid, item.id, item.price),
        colorScheme: colorScheme,
      );
    });
  }

  Widget _buildWallpaperGrid(user, characterController, colorScheme) {
    final purchasableWallpapers =
        RoomAssets.wallpapers.where((w) => w.price > 0).toList();
    return _buildGrid(purchasableWallpapers, (item) {
      final isPurchased = user.purchasedThemeIds.contains(item.id);
      return _buildShopItem(
        item: item,
        isPurchased: isPurchased,
        onPurchase: () => characterController.purchaseWallpaper(
            user.uid, item.id, item.price),
        colorScheme: colorScheme,
      );
    });
  }

  Widget _buildBackgroundGrid(user, characterController, colorScheme) {
    final purchasableBackgrounds =
        RoomAssets.backgrounds.where((b) => b.price > 0).toList();
    return _buildGrid(purchasableBackgrounds, (item) {
      final isPurchased = user.purchasedBackgroundIds.contains(item.id);
      return _buildShopItem(
        item: item,
        isPurchased: isPurchased,
        onPurchase: () => characterController.purchaseBackground(
            user.uid, item.id, item.price),
        colorScheme: colorScheme,
      );
    });
  }

  Widget _buildPropGrid(user, characterController, colorScheme) {
    final purchasableProps =
        RoomAssets.props.where((p) => p.price > 0).toList();
    return _buildGrid(purchasableProps, (item) {
      final isPurchased = user.purchasedPropIds.contains(item.id);
      return _buildShopItem(
        item: item,
        isPurchased: isPurchased,
        onPurchase: () =>
            characterController.purchaseProp(user.uid, item.id, item.price),
        colorScheme: colorScheme,
      );
    });
  }

  Widget _buildFloorGrid(user, characterController, colorScheme) {
    final purchasableFloors =
        RoomAssets.floors.where((f) => f.price > 0).toList();
    return _buildGrid(purchasableFloors, (item) {
      final isPurchased = user.purchasedFloorIds.contains(item.id);
      return _buildShopItem(
        item: item,
        isPurchased: isPurchased,
        onPurchase: () =>
            characterController.purchaseFloor(user.uid, item.id, item.price),
        colorScheme: colorScheme,
      );
    });
  }

  Widget _buildGrid(
      List<RoomAsset> items, Widget Function(RoomAsset) itemBuilder) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(items[index]),
    );
  }

  Widget _buildShopItem({
    required RoomAsset item,
    required bool isPurchased,
    required Future<void> Function() onPurchase,
    required AppColorScheme colorScheme,
  }) {
    return Builder(builder: (context) {
      final canAfford =
          context.read<CharacterController>().currentUser!.points >= item.price;

      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    (item.color ?? colorScheme.primaryButton).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: item.imagePath != null
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: item.imagePath!.endsWith('.svg')
                          ? SvgPicture.asset(
                              item.imagePath!,
                            )
                          : Image.asset(item.imagePath!),
                    )
                  : Icon(item.icon,
                      color: item.color ?? colorScheme.primaryButton, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stars, color: colorScheme.pointStar, size: 12),
                const SizedBox(width: 2),
                Text(
                  '${item.price}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isPurchased || canAfford
                        ? colorScheme.textSecondary
                        : colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: isPurchased
                    ? null
                    : () async {
                        final shouldPurchase = await AppDialog.show<bool>(
                          context: context,
                          key: AppDialogKey.purchase,
                          content: Text('${item.name}을(를) 구매하시겠습니까?'),
                        );

                        if (shouldPurchase == true) {
                          try {
                            await onPurchase();
                            if (context.mounted) {
                              await AppDialog.show(
                                context: context,
                                key: AppDialogKey.purchaseComplete,
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 16),
                                    Center(
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: (item.color ??
                                                  colorScheme.primaryButton)
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: item.imagePath != null
                                            ? Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: item.imagePath!
                                                        .endsWith('.svg')
                                                    ? SvgPicture.asset(
                                                        item.imagePath!,
                                                      )
                                                    : Image.asset(
                                                        item.imagePath!),
                                              )
                                            : Icon(
                                                item.icon,
                                                size: 60,
                                                color: item.color ??
                                                    colorScheme.primaryButton,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      '${item.name}을(를) 구매했습니다.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: colorScheme.error),
                              );
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: isPurchased
                      ? Colors.grey.shade200
                      : colorScheme.primaryButton,
                  foregroundColor: isPurchased ? Colors.grey : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(isPurchased ? '완료' : '구매',
                    style: const TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      );
    });
  }
}

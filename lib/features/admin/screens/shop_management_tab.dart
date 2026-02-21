import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/room_assets.dart';
import '../../../../core/constants/character_assets.dart';
import '../../../../core/widgets/network_or_asset_image.dart';
import '../controllers/admin_controller.dart';
import 'asset_upload_dialog.dart';

class ShopManagementTab extends StatefulWidget {
  const ShopManagementTab({super.key});

  @override
  State<ShopManagementTab> createState() => _ShopManagementTabState();
}

class _ShopManagementTabState extends State<ShopManagementTab>
    with SingleTickerProviderStateMixin {
  // 모든 아이템 리스트 (가격이 0보다 큰 것만, 판매 가능한 품목)
  late List<dynamic> _allItems;
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _allItems = [
      ...RoomAssets.themes,
      ...RoomAssets.emoticons,
      ...RoomAssets.wallpapers,
      ...RoomAssets.backgrounds,
      ...RoomAssets.props,
      ...RoomAssets.floors,
      ...CharacterAssets.items,
    ].where((item) => item.price > 0).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _getFilteredItems(Map<String, int> discounts) {
    List<dynamic> items = [];

    switch (_tabController.index) {
      case 0: // 전체
        items = _allItems;
        break;
      case 1: // 테마
        items = RoomAssets.themes.where((item) => item.price > 0).toList();
        break;
      case 2: // 이모티콘
        items = RoomAssets.emoticons.where((item) => item.price > 0).toList();
        break;
      case 3: // 배경화면
        items = RoomAssets.wallpapers.where((item) => item.price > 0).toList();
        break;
      case 4: // 배경
        items = RoomAssets.backgrounds.where((item) => item.price > 0).toList();
        break;
      case 5: // 소품
        items = RoomAssets.props.where((item) => item.price > 0).toList();
        break;
      case 6: // 바닥
        items = RoomAssets.floors.where((item) => item.price > 0).toList();
        break;
      case 7: // 할인중
        items =
            _allItems.where((item) => discounts.containsKey(item.id)).toList();
        break;
    }

    // 검색어 필터링
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final name = item.name.toString();
        return name.contains(_searchQuery);
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final discounts = controller.shopDiscounts;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AssetUploadDialog(),
          ).then((_) {
            // 업로드 완료 후 새로고침 (간단히 setState 혹은 AdminController를 통해 refresh)
            setState(() {});
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('신규 아이템 추가'),
      ),
      body: Column(
        children: [
          // 탭바
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              onTap: (_) => setState(() {}),
              tabs: const [
                Tab(text: '전체'),
                Tab(text: '테마'),
                Tab(text: '이모티콘'),
                Tab(text: '배경화면'),
                Tab(text: '배경'),
                Tab(text: '소품'),
                Tab(text: '바닥'),
                Tab(text: '할인중'),
              ],
            ),
          ),
          // 검색바와 할인 제거 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: '아이템 검색',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                if (discounts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.remove_circle_outline),
                      label: Text('모든 할인 제거 (${discounts.length}개)'),
                      onPressed: () =>
                          _showRemoveAllDiscountsDialog(context, controller),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 아이템 리스트
          Expanded(
            child: Builder(
              builder: (context) {
                final filteredItems = _getFilteredItems(discounts);

                if (filteredItems.isEmpty) {
                  return const Center(child: Text('검색 결과가 없습니다.'));
                }

                return ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final itemId = item.id;
                    final isDiscounted = discounts.containsKey(itemId);
                    final discountPrice = discounts[itemId];
                    final originalPrice = item.price;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: _buildItemImage(item),
                        title: Text(item.name),
                        subtitle: Text(
                          isDiscounted
                              ? '원가: $originalPrice 가지 → 할인가: $discountPrice 가지'
                              : '가격: $originalPrice 가지',
                          style: TextStyle(
                            color: isDiscounted ? Colors.red : Colors.black87,
                            fontWeight: isDiscounted
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.local_offer,
                                color: isDiscounted ? Colors.red : Colors.grey,
                              ),
                              onPressed: () => _showDiscountDialog(
                                  context, item, discounts, controller),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings,
                                  color: Colors.blueGrey),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      AssetUploadDialog(itemToEdit: item),
                                ).then((_) => setState(() {}));
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(dynamic item) {
    if (item.imagePath != null) {
      return NetworkOrAssetImage(
        imagePath: item.imagePath!,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
      );
    }
    return Icon(item.icon ?? Icons.shopping_bag);
  }

  void _showDiscountDialog(BuildContext context, dynamic item,
      Map<String, int> discounts, AdminController controller) {
    final itemId = item.id;
    final originalPrice = item.price;
    final currentDiscount = discounts[itemId];

    final textController = TextEditingController(
      text: currentDiscount?.toString() ?? originalPrice.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${item.name} 할인 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('원가: $originalPrice 가지'),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '할인 가격',
                  border: OutlineInputBorder(),
                  suffixText: '가지',
                ),
              ),
            ],
          ),
          actions: [
            if (discounts.containsKey(itemId))
              TextButton(
                onPressed: () {
                  controller.removeShopDiscount(itemId);
                  Navigator.pop(dialogContext);
                },
                child: const Text('할인 해제', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final price = int.tryParse(textController.text);
                if (price != null && price >= 0) {
                  controller.setShopDiscount(itemId, price);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveAllDiscountsDialog(
      BuildContext context, AdminController controller) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('모든 할인 제거'),
          content: const Text('정말로 모든 할인을 제거하시겠습니까?\n모든 상품이 원래 가격으로 돌아갑니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                controller.removeAllShopDiscounts();
                Navigator.pop(dialogContext);
              },
              child: const Text('모두 제거'),
            ),
          ],
        );
      },
    );
  }
}

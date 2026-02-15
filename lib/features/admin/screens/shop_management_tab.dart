import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/room_assets.dart';
import '../../../../core/constants/character_assets.dart';
import '../controllers/admin_controller.dart';

class ShopManagementTab extends StatefulWidget {
  const ShopManagementTab({super.key});

  @override
  State<ShopManagementTab> createState() => _ShopManagementTabState();
}

class _ShopManagementTabState extends State<ShopManagementTab> {
  // 모든 아이템 리스트 (가격이 0보다 큰 것만, 판매 가능한 품목)
  late List<dynamic> _allItems;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();
    final discounts = controller.shopDiscounts;

    final filteredItems = _allItems.where((item) {
      final name = item.name.toString();
      return name.contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
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
        ),
        Expanded(
          child: filteredItems.isEmpty
              ? const Center(child: Text('검색 결과가 없습니다.'))
              : ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item =
                        filteredItems[index]; // RoomAsset or CharacterItem
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
                        trailing: IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: isDiscounted ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _showDiscountDialog(
                              context, item, discounts, controller),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildItemImage(dynamic item) {
    if (item.imagePath != null) {
      return Image.asset(
        item.imagePath!,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image_not_supported),
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
}

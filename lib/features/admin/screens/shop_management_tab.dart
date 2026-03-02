import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/room_assets.dart';
import '../../../../core/constants/character_assets.dart';
import '../../../../core/widgets/network_or_asset_image.dart';
import '../../../../services/asset_service.dart';
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
  String _searchQuery = '';
  late TabController _tabController;

  List<dynamic> get _allItems => [
        ...RoomAssets.themes,
        ...RoomAssets.emoticons,
        ...RoomAssets.wallpapers,
        ...RoomAssets.backgrounds,
        ...RoomAssets.props,
        ...RoomAssets.floors,
        ...RoomAssets.windows,
        ...CharacterAssets.items,
      ].where((item) => item.price > 0).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    // 관리자 페이지 열릴 때 Firestore에서 최신 에셋 목록을 가져와서 반영
    _refreshAssets();
  }

  Future<void> _refreshAssets() async {
    await AssetService().fetchDynamicAssets();
    if (mounted) setState(() {});
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
      case 7: // 창문
        items = RoomAssets.windows.where((item) => item.price > 0).toList();
        break;
      case 8: // 할인중
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

    return Column(
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
              Tab(text: '창문'),
              Tab(text: '할인중'),
            ],
          ),
        ),
        // 검색바와 할인 제거 버튼
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 동기화 및 추가 버튼 행
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              try {
                                await controller.syncShopAssets();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('로컬 에셋이 Firebase와 동기화되었습니다.')),
                                  );
                                  _refreshAssets();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('동기화 실패: $e')),
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.cloud_sync),
                      label: const Text('로컬 에셋 동기화 (Firebase 업로드)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AssetUploadDialog(),
                      ).then((_) => _refreshAssets());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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

              return Column(
                children: [
                  // 아이템 수 표시
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey[100],
                    width: double.infinity,
                    child: Text(
                      '📦 표시 중: ${filteredItems.length}개  |  '
                      'props: ${RoomAssets.props.where((p) => p.price > 0).length}  '
                      'wallpapers: ${RoomAssets.wallpapers.where((p) => p.price > 0).length}  '
                      'floors: ${RoomAssets.floors.where((p) => p.price > 0).length}  '
                      'windows: ${RoomAssets.windows.where((p) => p.price > 0).length}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  if (filteredItems.isEmpty)
                    const Expanded(child: Center(child: Text('검색 결과가 없습니다.')))
                  else
                    Expanded(
                      child: ListView.builder(
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
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: GestureDetector(
                                onTap: () => _quickChangeImage(
                                    context, item, controller),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                      ),
                                      child: _buildItemImage(item, size: 50),
                                    ),
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.edit,
                                          size: 12, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(item.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ID: ${item.id}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600])),
                                  Text(
                                    isDiscounted
                                        ? '원가: $originalPrice 가지 → 할인가: $discountPrice 가지'
                                        : '가격: $originalPrice 가지',
                                    style: TextStyle(
                                      color: isDiscounted
                                          ? Colors.red
                                          : Colors.black87,
                                      fontWeight: isDiscounted
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    item.imagePath != null
                                        ? (item.imagePath!.startsWith('http')
                                            ? '🌐 원격 이미지'
                                            : '🖼️ 로컬: ${item.imagePath}')
                                        : '❌ 이미지 없음',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.local_offer,
                                      color: isDiscounted
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    tooltip: '할인 설정',
                                    onPressed: () => _showDiscountDialog(
                                        context, item, discounts, controller),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.settings,
                                        color: Colors.blueGrey),
                                    tooltip: '상세 설정/삭제',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            AssetUploadDialog(itemToEdit: item),
                                      ).then((_) => _refreshAssets());
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _quickChangeImage(
      BuildContext context, dynamic item, AdminController controller) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();

      // 이미지 업로드 확인 다이얼로그
      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('이미지 즉시 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('선택한 이미지로 교체하시겠습니까? (서버에 즉시 반영됩니다)'),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: Image.memory(imageBytes, fit: BoxFit.contain),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('변경하기')),
          ],
        ),
      );

      if (confirm == true) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('이미지 업로드 중...'), duration: Duration(seconds: 1)));

          await AssetService().updateAsset(
            id: item.id,
            name: item.name,
            price: item.price,
            category: item.category ?? 'prop',
            imageBytes: imageBytes,
            existingImageUrl: item.imagePath ?? '',
            sizeMultiplier: item.sizeMultiplier,
            aspectRatio: item.aspectRatio,
            isWallMounted: item.isWallMounted,
            noShadow: item.noShadow,
            shadowDyCorrection: item.shadowDyCorrection,
            isLight: item.isLight,
            lightIntensity: item.lightIntensity,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('이미지가 업데이트되었습니다.')));
            _refreshAssets();
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
          }
        }
      }
    }
  }

  Widget _buildItemImage(dynamic item, {double size = 40}) {
    if (item.imagePath != null) {
      return NetworkOrAssetImage(
        imagePath: item.imagePath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Icon(item.icon ?? Icons.shopping_bag, size: size);
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

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
  int _currentPage = 0;
  static const int _itemsPerPage = 20;

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
    _tabController = TabController(length: 10, vsync: this);
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
      case 8: // 캐릭터
        items = CharacterAssets.items.where((item) => item.price > 0).toList();
        break;
      case 9: // 할인중
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
            onTap: (_) {
              setState(() {
                _currentPage = 0;
              });
            },
            tabs: const [
              Tab(text: '전체'),
              Tab(text: '테마'),
              Tab(text: '이모티콘'),
              Tab(text: '배경화면'),
              Tab(text: '배경'),
              Tab(text: '소품'),
              Tab(text: '바닥'),
              Tab(text: '창문'),
              Tab(text: '캐릭터'),
              Tab(text: '할인중'),
            ],
          ),
        ),
        // 검색바와 할인 제거 버튼
        // 검색바와 할인 제거 버튼
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 아이템 추가 버튼 (크게 배치)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AssetUploadDialog(),
                    ).then((_) => _refreshAssets());
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 24),
                  label: const Text('새로운 아이템 추가하기',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: '아이템 검색',
                  hintText: '아이템 이름으로 검색하세요',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 0;
                  });
                },
              ),
              if (discounts.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.red.shade200),
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
        // 아이템 그리드
        Expanded(
          child: Builder(
            builder: (context) {
              final filteredItems = _getFilteredItems(discounts);
              final totalPages = (filteredItems.length / _itemsPerPage).ceil();

              if (_currentPage >= totalPages && totalPages > 0) {
                _currentPage = totalPages - 1;
              }

              final startIndex = _currentPage * _itemsPerPage;
              final endIndex =
                  (startIndex + _itemsPerPage > filteredItems.length)
                      ? filteredItems.length
                      : startIndex + _itemsPerPage;

              final pagedItems = filteredItems.sublist(startIndex, endIndex);

              return Column(
                children: [
                  // 아이템 수 표시
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey[100],
                    width: double.infinity,
                    child: Text(
                      '📦 전체 검색 결과: ${filteredItems.length}개  |  '
                      '현재 페이지: ${_currentPage + 1} / ${totalPages == 0 ? 1 : totalPages}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  if (pagedItems.isEmpty)
                    const Expanded(child: Center(child: Text('검색 결과가 없습니다.')))
                  else
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: pagedItems.length,
                        itemBuilder: (context, index) {
                          final item = pagedItems[index];
                          final itemId = item.id;
                          final isDiscounted = discounts.containsKey(itemId);
                          final discountPrice = discounts[itemId];
                          final originalPrice = item.price;

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 상단 이미지 영역
                                Expanded(
                                  flex: 3,
                                  child: GestureDetector(
                                    onTap: () => _quickChangeImage(
                                        context, item, controller),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          _buildItemImage(item, size: 100),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black45,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(Icons.edit,
                                                  size: 14,
                                                  color: Colors.white),
                                            ),
                                          ),
                                          // 카테고리 태그
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blueGrey[700]!
                                                    .withOpacity(0.8),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _getCategoryLabel(
                                                    item.category),
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          if (isDiscounted)
                                            Positioned(
                                              top: 8,
                                              left: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text('SALE',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // 텍스트 정보 영역
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'ID: ${item.id}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600]),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (isDiscounted)
                                                  Text(
                                                    '$originalPrice 가지',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey[400],
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                    ),
                                                  ),
                                                Text(
                                                  '${isDiscounted ? discountPrice : originalPrice} 가지',
                                                  style: TextStyle(
                                                    color: isDiscounted
                                                        ? Colors.red
                                                        : Colors.blueAccent,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: Icon(
                                                    Icons.local_offer_outlined,
                                                    size: 18,
                                                    color: isDiscounted
                                                        ? Colors.red
                                                        : Colors.grey,
                                                  ),
                                                  onPressed: () =>
                                                      _showDiscountDialog(
                                                          context,
                                                          item,
                                                          discounts,
                                                          controller),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: const Icon(
                                                      Icons.settings_outlined,
                                                      size: 18,
                                                      color: Colors.blueGrey),
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          AssetUploadDialog(
                                                              itemToEdit: item),
                                                    ).then((_) =>
                                                        _refreshAssets());
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  // Pagination Controls
                  if (totalPages > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _currentPage > 0
                                ? () => setState(() => _currentPage--)
                                : null,
                          ),
                          Text(
                            '${_currentPage + 1} / $totalPages',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _currentPage < totalPages - 1
                                ? () => setState(() => _currentPage++)
                                : null,
                          ),
                        ],
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

  String _getCategoryLabel(String? category) {
    switch (category) {
      case 'theme':
        return '테마';
      case 'emoticon':
        return '이모티콘';
      case 'wallpaper':
        return '배경화면';
      case 'background':
        return '배경';
      case 'prop':
        return '소품';
      case 'floor':
        return '바닥';
      case 'window':
        return '창문';
      case 'character':
        return '캐릭터';
      default:
        return '기타';
    }
  }
}

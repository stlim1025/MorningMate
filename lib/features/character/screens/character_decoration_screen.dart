import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/constants/room_assets.dart';
import '../controllers/character_controller.dart';
import '../widgets/character_display.dart';
import '../../../core/widgets/memo_notification.dart';

class CharacterDecorationScreen extends StatefulWidget {
  const CharacterDecorationScreen({super.key});

  @override
  State<CharacterDecorationScreen> createState() =>
      _CharacterDecorationScreenState();
}

class _CharacterDecorationScreenState extends State<CharacterDecorationScreen> {
  String _selectedCategory = 'all';
  late PageController _pageController;
  int _currentIndex = 0;

  final Map<String, String> _categoryNames = {
    'all': '전체',
    'head': '머리',
    'face': '얼굴',
    'clothes': '옷',
    'body': '장식',
  };

  late final List<String> _categories = _categoryNames.keys.toList();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getCategory(String itemId) {
    if (itemId == 'necktie') return 'body';
    if (itemId == 'space_clothes' || itemId == 'prog_clothes') return 'clothes';
    if (itemId == 'sprout' || itemId == 'plogeyes') return 'head';
    return 'face';
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
        title: const Text(
          '캐릭터 꾸미기',
          style: TextStyle(
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
              onTap: () {
                MemoNotification.show(context, '설정이 저장되었습니다! ✨');
                context.pop();
              },
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
                child: const Text(
                  '저장',
                  style: TextStyle(
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
              child: Center(
                child: CharacterDisplay(
                  isAwake: true,
                  characterLevel: user.characterLevel,
                  size: 250,
                  enableAnimation: true,
                  equippedItems: user.equippedCharacterItems,
                ),
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
                        children: _categoryNames.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _buildTabItem(
                                entry.value, _selectedCategory == entry.key,
                                () {
                              final newIndex = _categories.indexOf(entry.key);
                              setState(() {
                                _currentIndex = newIndex;
                                _selectedCategory = entry.key;
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
                              RoomAssets.characterItems.where((item) {
                            if (category == 'all') return true;
                            return _getCategory(item.id) == category;
                          }).toList();

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 4, 24, 60),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              final isOwned = user.purchasedCharacterItemIds
                                  .contains(item.id);
                              final isEquipped = user.equippedCharacterItems
                                  .containsValue(item.id);

                              return _buildSelectionCard(
                                label: item.name,
                                imagePath: item.imagePath,
                                isSelected: isEquipped,
                                isLocked: !isOwned,
                                onTap: () async {
                                  if (!isOwned) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('상점에서 먼저 구매해주세요!')),
                                    );
                                    return;
                                  }
                                  try {
                                    await characterController
                                        .equipCharacterItem(user.uid, item.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
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
    required String label,
    required String? imagePath,
    required bool isSelected,
    required bool isLocked,
    required VoidCallback onTap,
    required AppColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/icons/Friend_Card${(label.hashCode.abs() % 6) + 1}.png',
            ),
            fit: BoxFit.fill,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (imagePath != null)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    opacity: isLocked
                        ? const AlwaysStoppedAnimation(0.5)
                        : const AlwaysStoppedAnimation(1.0),
                  ),
                ),
              ),
            Positioned(
              bottom: 12,
              left: 4,
              right: 4,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 12,
                  color: isLocked ? Colors.grey : const Color(0xFF4E342E),
                ),
              ),
            ),
            if (isLocked)
              const Icon(Icons.lock, size: 24, color: Colors.black26),
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
                  const Positioned(
                    top: 20,
                    child: Text(
                      '장착',
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

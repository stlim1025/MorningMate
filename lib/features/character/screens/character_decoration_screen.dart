import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/constants/room_assets.dart';
import '../controllers/character_controller.dart';
import '../widgets/character_display.dart';

class CharacterDecorationScreen extends StatefulWidget {
  const CharacterDecorationScreen({super.key});

  @override
  State<CharacterDecorationScreen> createState() =>
      _CharacterDecorationScreenState();
}

class _CharacterDecorationScreenState extends State<CharacterDecorationScreen> {
  // String _selectedCategory = 'accessory'; // Currently unused

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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8), // Warm background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4E342E)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '캐릭터 꾸미기',
          style: TextStyle(
            color: Color(0xFF4E342E),
            fontFamily: 'BMJUA',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              '저장',
              style: TextStyle(
                color: Color(0xFF4E342E),
                fontFamily: 'BMJUA',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                  size: 250, // Large size
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
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Tab Bar (Simplified for now)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        _buildTabItem('액세서리', true, colorScheme),
                        // Add more tabs later: Skin, Motion, etc.
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Items Grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: RoomAssets.characterItems.length,
                      itemBuilder: (context, index) {
                        final item = RoomAssets.characterItems[index];
                        final isOwned =
                            user.purchasedCharacterItemIds.contains(item.id);
                        final isEquipped =
                            user.equippedCharacterItems.containsValue(item.id);

                        return GestureDetector(
                          onTap: () async {
                            if (!isOwned) {
                              // Show purchase dialog or toast?
                              // User flow: Purchase in shop -> Equip here.
                              // But maybe allow "Use if owned"
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('상점에서 먼저 구매해주세요!')),
                              );
                              return;
                            }
                            // Toggle Equip
                            try {
                              await characterController.equipCharacterItem(
                                  user.uid, item.id);
                              if (!context.mounted) return;
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isEquipped
                                  ? colorScheme.primaryButton.withOpacity(0.1)
                                  : Colors.grey[50], // Highlight equipped
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isEquipped
                                    ? colorScheme.primaryButton
                                    : Colors.grey.shade300,
                                width: isEquipped ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      item.imagePath!,
                                      fit: BoxFit.contain,
                                      opacity: isOwned
                                          ? const AlwaysStoppedAnimation(1.0)
                                          : const AlwaysStoppedAnimation(0.5),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontFamily: 'BMJUA',
                                      fontSize: 14,
                                      color: isOwned
                                          ? Colors.black87
                                          : Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (!isOwned)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Icon(Icons.lock,
                                        size: 16, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
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

  Widget _buildTabItem(
      String label, bool isSelected, AppColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryButton : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? colorScheme.primaryButton : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontFamily: 'BMJUA',
        ),
      ),
    );
  }
}

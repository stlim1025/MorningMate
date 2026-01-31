import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_color_scheme.dart';
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

    final isAppDarkMode = Theme.of(context).brightness == Brightness.dark;

    final themes = [
      {
        'id': 'dark',
        'name': '다크 테마',
        'price': 100,
        'icon': Icons.dark_mode,
        'primaryColor':
            isAppDarkMode ? const Color(0xFF3D3D3D) : const Color(0xFF1E1E1E),
        'secondaryColor': Colors.white,
      },
      {
        'id': 'sky',
        'name': '하늘 테마',
        'price': 100,
        'icon': Icons.wb_sunny_outlined,
        'primaryColor': const Color(0xFFE3EFFB),
        'secondaryColor': const Color(0xFF5AA9E6),
      },
      {
        'id': 'purple',
        'name': '퍼플 테마',
        'price': 100,
        'icon': Icons.auto_awesome,
        'primaryColor': const Color(0xFFF8F5FF),
        'secondaryColor': const Color(0xFF9B6BFF),
      },
      {
        'id': 'pink',
        'name': '핑크 테마',
        'price': 100,
        'icon': Icons.favorite,
        'primaryColor': const Color(0xFFFFF5F8),
        'secondaryColor': const Color(0xFFFF7EB3),
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('상점'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '테마',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.6,
                ),
                itemCount: themes.length,
                itemBuilder: (context, index) {
                  final theme = themes[index];
                  final isPurchased =
                      user.purchasedThemeIds.contains(theme['id']);
                  final canAfford = user.points >= (theme['price'] as int);

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadowColor.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 테마 색상 미리보기
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: theme['primaryColor'] as Color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      colorScheme.shadowColor.withOpacity(0.1),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            Icon(
                              theme['icon'] as IconData,
                              size: 24,
                              color: theme['secondaryColor'] as Color,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          theme['name'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stars,
                                color: colorScheme.pointStar, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              '${theme['price']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: canAfford || isPurchased
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
                          height: 32,
                          child: ElevatedButton(
                            onPressed: isPurchased
                                ? null
                                : () async {
                                    if (!canAfford) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text('포인트가 부족합니다.'),
                                          backgroundColor: colorScheme.error,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    try {
                                      await characterController.purchaseTheme(
                                        user.uid,
                                        theme['id'] as String,
                                        theme['price'] as int,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${theme['name']} 구매가 완료되었습니다!'),
                                            backgroundColor:
                                                colorScheme.success,
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        String msg = e.toString();
                                        if (msg.contains('Exception:')) {
                                          msg = msg
                                              .split('Exception:')
                                              .last
                                              .trim();
                                        }
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(msg),
                                            backgroundColor: colorScheme.error,
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: isPurchased
                                  ? colorScheme.textHint.withOpacity(0.2)
                                  : colorScheme.primaryButton,
                              foregroundColor: isPurchased
                                  ? colorScheme.textHint
                                  : colorScheme.primaryButtonForeground,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isPurchased ? '완료' : '구매',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

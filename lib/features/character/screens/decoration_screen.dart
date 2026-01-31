import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/app_theme_type.dart';
import '../controllers/character_controller.dart';

class DecorationScreen extends StatelessWidget {
  const DecorationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final characterController = context.watch<CharacterController>();
    final themeController = context.read<ThemeController>();
    final user = characterController.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAppDarkMode = Theme.of(context).brightness == Brightness.dark;

    final allThemes = [
      {
        'id': 'light',
        'name': '라이트 테마',
        'type': AppThemeType.light,
        'icon': Icons.wb_sunny,
        'color': const Color(0xFFD4A574),
      },
      {
        'id': 'dark',
        'name': '다크 테마',
        'type': AppThemeType.dark,
        'icon': Icons.dark_mode,
        'color': isAppDarkMode ? Colors.white : const Color(0xFF1E1E1E),
      },
      {
        'id': 'sky',
        'name': '하늘 테마',
        'type': AppThemeType.sky,
        'icon': Icons.wb_sunny_outlined,
        'color': const Color(0xFF5AA9E6),
      },
      {
        'id': 'purple',
        'name': '퍼플 테마',
        'type': AppThemeType.purple,
        'icon': Icons.auto_awesome,
        'color': const Color(0xFF9B6BFF),
      },
      {
        'id': 'pink',
        'name': '핑크 테마',
        'type': AppThemeType.pink,
        'icon': Icons.favorite,
        'color': const Color(0xFFFF7EB3),
      },
    ];

    // 사용자가 구매한 테마만 필터링
    final purchasedThemes = allThemes
        .where((theme) => user.purchasedThemeIds.contains(theme['id']))
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('꾸미기'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 내 테마 섹션
            _buildSection(
              context,
              '내 테마',
              purchasedThemes.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('구매한 테마가 없습니다.'),
                    )
                  : SizedBox(
                      height: 110,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: purchasedThemes.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final theme = purchasedThemes[index];
                          final isSelected = user.currentThemeId == theme['id'];
                          final themeType = theme['type'] as AppThemeType;

                          return GestureDetector(
                            onTap: () async {
                              try {
                                await characterController.setTheme(
                                    user.uid, theme['id'] as String);
                                await themeController.setTheme(themeType);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('${theme['name']}가 적용되었습니다!'),
                                      backgroundColor: colorScheme.success,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: colorScheme.error,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? Border.all(
                                            color: colorScheme.primaryButton,
                                            width: 2)
                                        : Border.all(
                                            color: colorScheme.shadowColor
                                                .withOpacity(0.1),
                                            width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.shadowColor
                                            .withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      theme['icon'] as IconData,
                                      size: 32,
                                      color: theme['color'] as Color,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  theme['name'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: colorScheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
              colorScheme,
            ),

            const SizedBox(height: 32),

            // 2. 소품 섹션 (Placeholder)
            _buildSection(
              context,
              '소품',
              SizedBox(
                height: 100,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _buildPlaceholderItem(context, colorScheme, '준비 중');
                  },
                ),
              ),
              colorScheme,
            ),

            const SizedBox(height: 32),

            // 3. 벽지 섹션 (Placeholder)
            _buildSection(
              context,
              '벽지',
              SizedBox(
                height: 100,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _buildPlaceholderItem(context, colorScheme, '준비 중');
                  },
                ),
              ),
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content,
      AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildPlaceholderItem(
      BuildContext context, AppColorScheme colorScheme, String text) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: colorScheme.textHint.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.shadowColor.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.lock_outline,
              size: 24,
              color: colorScheme.textHint.withOpacity(0.3),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.textHint,
          ),
        ),
      ],
    );
  }
}

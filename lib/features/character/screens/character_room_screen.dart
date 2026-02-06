import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../controllers/character_controller.dart';
import 'shop_screen.dart';
import 'decoration_screen.dart';
import '../../common/widgets/custom_bottom_navigation_bar.dart';

class CharacterRoomScreen extends StatelessWidget {
  const CharacterRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, color: colorScheme.iconPrimary, size: 28),
            const SizedBox(width: 8),
            Text(
              '내 캐릭터',
              style: TextStyle(
                color: colorScheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Consumer<CharacterController>(
            builder: (context, controller, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.twig.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/branch.png',
                      width: 18,
                      height: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${controller.currentUser?.points ?? 0}',
                      style: TextStyle(
                        color: colorScheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '가지',
                      style: TextStyle(
                        color: colorScheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Ceiling.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: Consumer<CharacterController>(
                  builder: (context, controller, child) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCharacter(context, controller, colorScheme),
                          const SizedBox(height: 32),
                          _buildCharacterInfo(context, controller, colorScheme),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _buildBottomActions(context, colorScheme),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildCharacter(BuildContext context, CharacterController controller,
      AppColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryButton.withOpacity(0.2),
                  colorScheme.secondary.withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primaryButton.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _getCharacterIcon(controller.characterState),
                size: 100,
                color: colorScheme.primaryButton,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            controller.currentAnimation,
            style: TextStyle(
              color: colorScheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterInfo(BuildContext context,
      CharacterController controller, AppColorScheme colorScheme) {
    final currentLevel = controller.currentUser?.characterLevel ?? 1;
    final currentExp = controller.currentUser?.experience ?? 0;
    final requiredExp = controller.currentUser?.requiredExpForNextLevel ?? 10;
    final progress = controller.currentUser?.expProgress ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '레벨',
                style:
                    TextStyle(color: colorScheme.textSecondary, fontSize: 15),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryButton.withOpacity(0.2),
                      colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lv. $currentLevel',
                  style: TextStyle(
                    color: colorScheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '경험치',
                    style: TextStyle(
                      color: colorScheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currentLevel >= 6
                        ? 'MAX'
                        : '$currentExp / $requiredExp EXP',
                    style: TextStyle(
                      color: colorScheme.primaryButton,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: colorScheme.textHint.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    currentLevel >= 6
                        ? colorScheme.success
                        : colorScheme.primaryButton,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colorScheme.textHint.withOpacity(0.3)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '상태',
                style:
                    TextStyle(color: colorScheme.textSecondary, fontSize: 15),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStateName(controller.characterState),
                  style: TextStyle(
                    color: colorScheme.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _AnimatedCustomButton(
              bgImage: 'assets/images/Cancel_Button.png',
              iconPath: 'assets/icons/Store_Icon.png',
              label: '상점',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShopScreen()),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _AnimatedCustomButton(
              bgImage: 'assets/images/Confirm_Button.png',
              iconPath: 'assets/icons/Ggumim_Icon.png',
              label: '꾸미기',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DecorationScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return CustomBottomNavigationBar(
      currentIndex: 1,
      onTap: (index) {},
    );
  }

  IconData _getCharacterIcon(CharacterState state) {
    switch (state) {
      case CharacterState.egg:
        return Icons.egg;
      case CharacterState.cracking:
        return Icons.egg_alt;
      case CharacterState.hatching:
        return Icons.cruelty_free;
      case CharacterState.baby:
        return Icons.pets;
      case CharacterState.young:
        return Icons.flutter_dash;
      case CharacterState.adult:
        return Icons.flight;
      case CharacterState.sleeping:
        return Icons.bedtime;
    }
  }

  String _getStateName(CharacterState state) {
    switch (state) {
      case CharacterState.egg:
        return '알 🥚';
      case CharacterState.cracking:
        return '금이 간 알 🥚✨';
      case CharacterState.hatching:
        return '부화 중 🐣';
      case CharacterState.baby:
        return '새끼 새 🐥';
      case CharacterState.young:
        return '아기 새 🐦';
      case CharacterState.adult:
        return '귀여운 새 🕊️';
      case CharacterState.sleeping:
        return '수면 중 💤';
    }
  }
}

class _AnimatedCustomButton extends StatefulWidget {
  final String bgImage;
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const _AnimatedCustomButton({
    required this.bgImage,
    required this.iconPath,
    required this.label,
    required this.onTap,
  });

  @override
  State<_AnimatedCustomButton> createState() => _AnimatedCustomButtonState();
}

class _AnimatedCustomButtonState extends State<_AnimatedCustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Image.asset(
                  widget.bgImage,
                  fit: BoxFit.fill,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    widget.iconPath,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontFamily: 'BMJUA',
                      fontSize: 18,
                      color: Color(0xFF4E342E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

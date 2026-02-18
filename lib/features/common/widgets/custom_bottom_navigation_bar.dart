import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final StatefulNavigationShell? navigationShell;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final double navBarHeight = Platform.isIOS ? 75 : 90;

    return SizedBox(
      height: navBarHeight + MediaQuery.of(context).padding.bottom,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. Background Image (Down_Tab.png)
          Container(
            width: double.infinity,
            height: (Platform.isIOS ? 50 : 60) +
                MediaQuery.of(context).padding.bottom,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Down_Tab.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          // 2. Tab Items (Protruding icons)
          SafeArea(
            top: false,
            child: SizedBox(
              height: navBarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _TabItem(
                    iconPath: 'assets/icons/Home_Icon.png',
                    label: AppLocalizations.of(context)?.get('home') ?? 'Home',
                    width: 38,
                    height: 38,
                    isSelected: currentIndex == 0,
                    onTap: () => _handleNavigation(context, 0),
                  ),
                  _TabItem(
                    iconPath: 'assets/icons/Challenge_Icon.png',
                    label: AppLocalizations.of(context)?.get('challenge') ??
                        'Challenge',
                    width: 54,
                    height: 38,
                    isSelected: currentIndex == 1,
                    onTap: () => _handleNavigation(context, 1),
                  ),
                  _TabItem(
                    iconPath: 'assets/icons/Friend_Icon.png',
                    label: AppLocalizations.of(context)?.get('friends') ??
                        'Friends',
                    width: 64,
                    height: 45,
                    isSelected: currentIndex == 2,
                    labelOffset: -7,
                    onTap: () => _handleNavigation(context, 2),
                  ),
                  _TabItem(
                    iconPath: 'assets/icons/Calander_Icon.png',
                    label: AppLocalizations.of(context)?.get('myPage') ??
                        'My Page',
                    width: 48,
                    height: 38,
                    isSelected: currentIndex == 3,
                    onTap: () => _handleNavigation(context, 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    onTap(index);
    if (currentIndex == index) return;

    if (navigationShell != null) {
      navigationShell!.goBranch(
        index,
        initialLocation: index == navigationShell!.currentIndex,
      );
    } else {
      switch (index) {
        case 0:
          context.go('/morning');
          break;
        case 1:
          context.go('/challenge');
          break;
        case 2:
          context.go('/social');
          break;
        case 3:
          context.go('/archive');
          break;
      }
    }
  }
}

class _TabItem extends StatefulWidget {
  final String iconPath;
  final String label;
  final double width;
  final double height;
  final bool isSelected;
  final double labelOffset;
  final VoidCallback onTap;

  const _TabItem({
    required this.iconPath,
    required this.label,
    required this.width,
    required this.height,
    required this.isSelected,
    this.labelOffset = -4,
    required this.onTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
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
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent, // Ensure full area is hit-testable
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, -6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle shadow layer
                    Transform.translate(
                      offset: const Offset(1, 1),
                      child: Image.asset(
                        widget.iconPath,
                        width: widget.width,
                        height: widget.height,
                        fit: BoxFit.contain,
                        color: Colors.black.withOpacity(0.2),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                    // Main icon
                    Image.asset(
                      widget.iconPath,
                      width: widget.width,
                      height: widget.height,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      opacity: widget.isSelected
                          ? const AlwaysStoppedAnimation(1.0)
                          : const AlwaysStoppedAnimation(0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 0),
              Transform.translate(
                offset: Offset(0, widget.labelOffset),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'BMJUA',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.isSelected
                        ? const Color(0xFF4E342E)
                        : const Color(0xFF4E342E).withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

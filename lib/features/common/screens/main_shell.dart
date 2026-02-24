import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import '../../../router/app_router.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0,
    );
    _offsetAnimation = const AlwaysStoppedAnimation(Offset.zero);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      final oldIndex = oldWidget.navigationShell.currentIndex;
      final newIndex = widget.navigationShell.currentIndex;

      // 마이페이지(index 4)에서 다른 탭으로 이동할 때 열려있는 바텀시트(내 메모 등) 닫기
      if (oldIndex == 4) {
        if (AppRouter.archiveNavigatorKey.currentState?.canPop() ?? false) {
          AppRouter.archiveNavigatorKey.currentState?.pop();
        }
      }

      final isRight = newIndex > oldIndex;

      _controller.reset();
      _offsetAnimation = Tween<Offset>(
        begin: Offset(isRight ? 0.2 : -0.2, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _controller.drive(
            Tween<double>(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: Curves.easeIn),
            ),
          ),
          child: widget.navigationShell,
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: widget.navigationShell.currentIndex,
        navigationShell: widget.navigationShell,
        onTap: (index) {
          // Navigation is handled internally by CustomBottomNavigationBar
        },
      ),
    );
  }
}

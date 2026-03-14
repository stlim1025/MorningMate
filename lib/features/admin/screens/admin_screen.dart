import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../widgets/admin_dialog.dart';

import 'admin_dashboard_tab.dart';
import 'admin_user_list_tab.dart';
import 'admin_notice_tab.dart';
import 'admin_push_tab.dart';
import 'admin_report_tab.dart';
import 'shop_management_tab.dart';
import 'admin_version_tab.dart';
import 'admin_ad_log_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<AdminController>().fetchStats();
        context.read<AdminController>().fetchReports();
        context.read<AdminController>().fetchShopDiscounts();
      }
    });
  }

  static const _menuItems = [
    _MenuItem(Icons.grid_view_rounded, '대시보드'),
    _MenuItem(Icons.people_alt_rounded, '유저 관리'),
    _MenuItem(Icons.article_rounded, '공지사항'),
    _MenuItem(Icons.notifications_active_rounded, '푸시 발송'),
    _MenuItem(Icons.flag_rounded, '신고 관리'),
    _MenuItem(Icons.shopping_bag_rounded, '상점 관리'),
    _MenuItem(Icons.system_update_rounded, '버전 관리'),
    _MenuItem(Icons.smart_display_rounded, '광고 로그'),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 800;

    Widget bodyContent;
    switch (_currentIndex) {
      case 0:
        bodyContent = const AdminDashboardTab();
        break;
      case 1:
        bodyContent = const AdminUserListTab();
        break;
      case 2:
        bodyContent = const AdminNoticeTab();
        break;
      case 3:
        bodyContent = const AdminPushTab();
        break;
      case 4:
        bodyContent = const AdminReportTab();
        break;
      case 5:
        bodyContent = const ShopManagementTab();
        break;
      case 6:
        bodyContent = const AdminVersionTab();
        break;
      case 7:
        bodyContent = const AdminAdLogTab();
        break;
      default:
        bodyContent = const AdminDashboardTab();
    }

    if (!isWideScreen) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('관리자 페이지'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context)),
          ],
        ),
        body: bodyContent,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex > 4 ? 4 : _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: '유저'),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications), label: '공지'),
            BottomNavigationBarItem(icon: Icon(Icons.send), label: '푸시'),
            BottomNavigationBarItem(
                icon: Icon(Icons.ads_click), label: '광고'),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: bodyContent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Text(
            _menuItems[_currentIndex].label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (_currentIndex != 2)
            _buildHeaderAction(
              label: '공지 작성',
              icon: Icons.edit_note_rounded,
              onTap: () => setState(() => _currentIndex = 2),
            ),
          if (_currentIndex != 2) const SizedBox(width: 8),
          if (_currentIndex != 3)
            _buildHeaderAction(
              label: '푸시 발송',
              icon: Icons.send_rounded,
              filled: true,
              onTap: () => setState(() => _currentIndex = 3),
            ),
          const SizedBox(width: 16),
          InkWell(
            onTap: () => _showLogoutDialog(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded,
                  size: 18, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label,
          style:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF475569),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          // Logo area
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(Icons.wb_sunny_rounded,
                    size: 22, color: Color(0xFF6366F1)),
                SizedBox(width: 10),
                Text(
                  'MorningMate',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          const SizedBox(height: 16),

          // Menu Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMenuLabel('서비스'),
                _buildMenuItem(0),
                _buildMenuItem(1),

                const SizedBox(height: 16),
                _buildMenuLabel('운영'),
                _buildMenuItem(2),
                _buildMenuItem(3),
                _buildMenuItem(4),

                const SizedBox(height: 16),
                _buildMenuLabel('관리'),
                _buildMenuItem(5),
                _buildMenuItem(6),
                _buildMenuItem(7),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMenuLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem(int index) {
    final isSelected = _currentIndex == index;
    final item = _menuItems[index];

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEEF2FF)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 10),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AdminWebDialog(
        title: '로그아웃',
        titleIcon: Icons.logout,
        width: 400,
        height: 180,
        content: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('정말로 로그아웃 하시겠습니까?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthController>().signOut();
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem(this.icon, this.label);
}

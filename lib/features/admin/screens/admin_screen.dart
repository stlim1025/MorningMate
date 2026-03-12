import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/widgets/app_dialog.dart';

import 'admin_dashboard_tab.dart';
import 'admin_user_list_tab.dart';
import 'admin_notice_tab.dart';
import 'admin_push_tab.dart';
import 'admin_report_tab.dart';
import 'shop_management_tab.dart';
import 'admin_version_tab.dart';

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
      default:
        bodyContent = const AdminDashboardTab();
    }

    if (!isWideScreen) {
      // Fallback for portrait mobile views or small windows
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
            BottomNavigationBarItem(icon: Icon(Icons.report), label: '신고'),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Dashboard background
      body: Row(
        children: [
          _buildSidebar(),
          const VerticalDivider(thickness: 1, width: 1, color: Colors.black12),
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                const Divider(height: 1, thickness: 1, color: Colors.black12),
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
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getMenuTitle(_currentIndex),
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          Row(
            children: [
              if (_currentIndex != 2)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _currentIndex = 2),
                  icon: const Icon(Icons.edit_document, size: 18),
                  label: const Text('신규 공지 작성'),
                ),
              if (_currentIndex != 2) const SizedBox(width: 8),
              if (_currentIndex != 3)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                  onPressed: () => setState(() => _currentIndex = 3),
                  icon: const Icon(Icons.send, size: 18, color: Colors.white),
                  label: const Text('푸시 발송',
                      style: TextStyle(color: Colors.white)),
                ),
              const SizedBox(width: 16),
              IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _showLogoutDialog(context),
                  tooltip: '로그아웃'),
            ],
          )
        ],
      ),
    );
  }

  String _getMenuTitle(int index) {
    switch (index) {
      case 0:
        return '대시보드';
      case 1:
        return '유저 관리';
      case 2:
        return '공지사항 관리';
      case 3:
        return '푸시 발송';
      case 4:
        return '신고 관리';
      case 5:
        return '상점 관리';
      case 6:
        return '버전 관리';
      default:
        return '관리자 홈';
    }
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 250,
      child: Material(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text(
              'MorningMate Admin',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.indigo),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildSidebarItem('🏠 대시보드 (통계)', 0),
            _buildSidebarItem('👤 유저 관리 (상세정보)', 1),
            _buildSidebarItem('📝 공지사항 관리', 2),
            _buildSidebarItem('🔔 푸시 메시지 전송', 3),
            _buildSidebarItem('🚩 신고 관리', 4),
            _buildSidebarItem('📦 아이템/상점 관리', 5),
            _buildSidebarItem('🆙 버전 관리', 6),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        color:
            isSelected ? Colors.indigo.withOpacity(0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.indigo : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.chevron_right, color: Colors.indigo, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    AppDialog.show(
      context: context,
      key: AppDialogKey.logout,
      actions: [
        AppDialogAction(label: '취소', onPressed: () => Navigator.pop(context)),
        AppDialogAction(
          label: '로그아웃',
          isPrimary: true,
          onPressed: () {
            Navigator.pop(context);
            context.read<AuthController>().signOut();
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'shop_management_tab.dart';
import '../controllers/admin_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/widgets/app_dialog.dart';

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
    String title = '관리자 홈';
    if (_currentIndex == 1) title = '신고 관리';
    if (_currentIndex == 2) title = '상점 관리';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: _currentIndex == 0
          ? const AdminHomeTab()
          : _currentIndex == 1
              ? const ReportListTab()
              : const ShopManagementTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: '신고'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: '상점'),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    AppDialog.show(
      context: context,
      key: AppDialogKey.logout,
      actions: [
        AppDialogAction(
          label: '취소',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: '로그아웃',
          isPrimary: true,
          onPressed: () {
            Navigator.pop(context); // Close dialog
            context.read<AuthController>().signOut();
            // AuthController listener usually handles redirect to login
          },
        ),
      ],
    );
  }
}

class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatCard(
                title: '오늘 접속자 수',
                value: '${controller.dailyVisitorCount}명',
                icon: Icons.person,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              _buildStatCard(
                title: '총 가입자 수',
                value: '${controller.totalUserCount}명',
                icon: Icons.group,
                color: Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportListTab extends StatelessWidget {
  const ReportListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = controller.reports;
        if (reports.isEmpty) {
          return const Center(child: Text('신고 내역이 없습니다.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(context, controller, report);
          },
        );
      },
    );
  }

  Widget _buildReportCard(BuildContext context, AdminController controller,
      Map<String, dynamic> report) {
    final status = report['status'];
    final isPending = status == 'pending';
    final createdAt = report['createdAt'];
    String dateStr = '';
    if (createdAt is DateTime) {
      dateStr = DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
    } else {
      dateStr = createdAt.toString();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '상태: $status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPending ? Colors.red : Colors.grey,
                  ),
                ),
                Text(dateStr),
              ],
            ),
            const SizedBox(height: 8),
            Text('신고자: ${report['reporterName']}'),
            Text('작성자: ${report['targetUserName']}'),
            const SizedBox(height: 8),
            Text('신고 사유: ${report['reason']}'),
            const SizedBox(height: 8),
            const Text('내용:', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              color: Colors.grey[200],
              child: Text(report['targetContent'] ?? ''),
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        _showRejectDialog(context, controller, report),
                    child: const Text('반려'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () =>
                        _showDeleteConfirmDialog(context, controller, report),
                    child:
                        const Text('삭제', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
            if (status == 'rejected')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('반려 사유: ${report['rejectReason'] ?? ''}',
                    style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, AdminController controller,
      Map<String, dynamic> report) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('신고 반려'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: '반려 사유를 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                controller.rejectReport(
                  report['id'],
                  report['reporterId'],
                  reasonController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context,
      AdminController controller, Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('노트 삭제'),
        content: const Text('정말로 이 노트를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteNote(
                report['id'],
                report['targetUserId'],
                report['targetId'],
                report['reporterId'],
              );
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';

class AdminReportTab extends StatelessWidget {
  const AdminReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = controller.reports;
        if (reports.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              await controller.fetchReports();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: const Center(child: Text('신고 내역이 없습니다.')),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchReports();
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(context, controller, report);
            },
          ),
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
            Text(
                '신고 대상 종류: ${report['targetType'] == 'sticky_note' ? '포스트잇 메모' : (report['targetType'] ?? '기타')}'),
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
                        _showSuspendDialog(context, controller, report),
                    child:
                        const Text('정지', style: TextStyle(color: Colors.white)),
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
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                controller.rejectReport(
                    report['id'], report['reporterId'], reasonController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(BuildContext context, AdminController controller,
      Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('사용자 정지 기간 선택'),
        children: [
          _suspendSimpleAction(context, controller, report, '1일 정지', 1),
          _suspendSimpleAction(context, controller, report, '3일 정지', 3),
          _suspendSimpleAction(context, controller, report, '5일 정지', 5),
          _suspendSimpleAction(context, controller, report, '7일 정지', 7),
          _suspendSimpleAction(context, controller, report, '한달 정지', 30),
          _suspendSimpleAction(context, controller, report, '영구 정지', -1),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소')),
          ),
        ],
      ),
    );
  }

  Widget _suspendSimpleAction(BuildContext context, AdminController controller,
      Map<String, dynamic> report, String label, int days) {
    return SimpleDialogOption(
      onPressed: () {
        controller.suspendUser(
          reportId: report['id'],
          targetUserId: report['targetUserId'],
          reporterId: report['reporterId'],
          days: days,
        );
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: days == -1 ? Colors.red : Colors.blue[800],
            fontWeight: days == -1 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

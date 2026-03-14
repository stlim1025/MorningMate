import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_dialog.dart';

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

        return Column(
          children: [
            // ── Header Bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded,
                      size: 20, color: Color(0xFF475569)),
                  const SizedBox(width: 8),
                  Text(
                    '전체 ${reports.length}건',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => controller.fetchReports(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('새로고침'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side:
                          const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Empty State ──
            if (reports.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 64, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 16),
                      Text('처리할 신고가 없습니다.',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 15)),
                    ],
                  ),
                ),
              ),

            // ── Table ──
            if (reports.isNotEmpty) ...[
              // Table Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                color: const Color(0xFFF8FAFC),
                child: const Row(
                  children: [
                    SizedBox(
                        width: 80,
                        child: Center(
                          child: Text('상태',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B))),
                        )),
                    Expanded(
                        flex: 2,
                        child: Text('신고 대상',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B)))),
                    Expanded(
                        flex: 2,
                        child: Text('사유 / 내용',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B)))),
                    Expanded(
                        flex: 1,
                        child: Text('신고자',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B)))),
                    SizedBox(
                        width: 120,
                        child: Text('일시',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B)))),
                    SizedBox(
                        width: 160,
                        child: Center(
                          child: Text('조치',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B))),
                        )),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Table Body
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await controller.fetchReports();
                  },
                  child: ListView.separated(
                    itemCount: reports.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return _buildReportRow(context, controller, report);
                    },
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReportRow(BuildContext context, AdminController controller,
      Map<String, dynamic> report) {
    final status = report['status'];
    final isPending = status == 'pending';
    final createdAt = report['createdAt'];
    String dateStr = '';
    if (createdAt is DateTime) {
      dateStr = DateFormat('MM.dd HH:mm').format(createdAt);
    } else {
      dateStr = createdAt.toString();
    }

    Color statusColor;
    String statusLabel;
    if (isPending) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = '대기중';
    } else if (status == 'rejected') {
      statusColor = const Color(0xFF94A3B8);
      statusLabel = '반려';
    } else {
      statusColor = const Color(0xFF10B981);
      statusLabel = '처리완료';
    }

    final targetType = report['targetType'] == 'sticky_note'
        ? '포스트잇 메모'
        : (report['targetType'] ?? '기타');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status Badge
          SizedBox(
            width: 80,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ),
          // Target Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['targetUserName'] ?? '알 수 없는 유저',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  targetType,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          // Reason & Content
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['reason'] ?? '',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (report['targetContent'] != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      report['targetContent'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
                if (status == 'rejected' &&
                    report['rejectReason'] != null) ...[
                  const SizedBox(height: 4),
                  Text('반려: ${report['rejectReason']}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFF59E0B))),
                ],
              ],
            ),
          ),
          // Reporter
          Expanded(
            flex: 1,
            child: Text(
              report['reporterName'] ?? '-',
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          // Date
          SizedBox(
            width: 120,
            child: Text(
              dateStr,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontFamily: 'monospace'),
            ),
          ),
          // Actions
          SizedBox(
            width: 160,
            child: isPending
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        label: '반려',
                        color: const Color(0xFF64748B),
                        onTap: () =>
                            _showRejectDialog(context, controller, report),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        label: '정지',
                        color: const Color(0xFFEF4444),
                        filled: true,
                        onTap: () =>
                            _showSuspendDialog(context, controller, report),
                      ),
                    ],
                  )
                : const Center(
                    child: Text('—',
                        style: TextStyle(color: Color(0xFFCBD5E1))),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    bool filled = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, AdminController controller,
      Map<String, dynamic> report) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AdminWebDialog(
        title: '신고 반려',
        titleIcon: Icons.undo,
        height: 250,
        content: Padding(
          padding: const EdgeInsets.all(24.0),
          child: TextField(
            controller: reasonController,
            decoration: InputDecoration(
              hintText: '반려 사유를 입력하세요',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                controller.rejectReport(
                    report['id'], report['reporterId'], reasonController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
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
      builder: (context) => AdminWebDialog(
        title: '사용자 정지 기간 선택',
        titleIcon: Icons.block,
        height: 420,
        width: 380,
        content: Column(
          children: [
            _suspendOption(context, controller, report, '1일 정지', 1),
            _suspendOption(context, controller, report, '3일 정지', 3),
            _suspendOption(context, controller, report, '5일 정지', 5),
            _suspendOption(context, controller, report, '7일 정지', 7),
            _suspendOption(context, controller, report, '한달 정지', 30),
            const Divider(height: 1),
            _suspendOption(context, controller, report, '영구 정지', -1),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
        ],
      ),
    );
  }

  Widget _suspendOption(BuildContext context, AdminController controller,
      Map<String, dynamic> report, String label, int days) {
    final isPerma = days == -1;
    return InkWell(
      onTap: () {
        controller.suspendUser(
          reportId: report['id'],
          targetUserId: report['targetUserId'],
          reporterId: report['reporterId'],
          days: days,
        );
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(
              isPerma ? Icons.gavel_rounded : Icons.access_time_rounded,
              size: 18,
              color: isPerma
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isPerma
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF1E293B),
                fontWeight: isPerma ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

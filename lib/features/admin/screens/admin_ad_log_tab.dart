import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';
import '../../../data/models/ad_log_model.dart';

class AdminAdLogTab extends StatefulWidget {
  const AdminAdLogTab({super.key});

  @override
  State<AdminAdLogTab> createState() => _AdminAdLogTabState();
}

class _AdminAdLogTabState extends State<AdminAdLogTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<AdminController>().fetchAdLogs();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdminController>().loadMoreAdLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // ── Header Bar ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border:
                    Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smart_display_rounded,
                      size: 20, color: Color(0xFF475569)),
                  const SizedBox(width: 8),
                  Text(
                    '광고 로그 (${controller.adLogs.length}건)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () =>
                        controller.fetchAdLogs(refresh: true),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('새로고침'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Table Header ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              color: const Color(0xFFF8FAFC),
              child: const Row(
                children: [
                  SizedBox(
                      width: 40,
                      child: Text('결과',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B)))),
                  Expanded(
                      flex: 2,
                      child: Text('사용자',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B)))),
                  Expanded(
                      flex: 1,
                      child: Text('액션',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B)))),
                  Expanded(
                      flex: 1,
                      child: Text('제공자',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B)))),
                  Expanded(
                      flex: 1,
                      child: Text('유형',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B)))),
                  Expanded(
                      flex: 2,
                      child: Text('네트워크',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B)))),
                  SizedBox(
                      width: 120,
                      child: Text('시간',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B)))),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // ── Body ──
            Expanded(
              child: _buildBody(controller),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(AdminController controller) {
    if (controller.isLoading && controller.adLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final logs = controller.adLogs;
    if (logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => controller.fetchAdLogs(refresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 300,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.smart_display_outlined,
                      size: 64, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 16),
                  Text('광고 로그가 없습니다.',
                      style:
                          TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchAdLogs(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        itemCount: logs.length + (controller.hasMoreAdLogs ? 1 : 0),
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
        itemBuilder: (context, index) {
          if (index == logs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildLogRow(logs[index]);
        },
      ),
    );
  }

  Widget _buildLogRow(AdLogModel log) {
    final dateStr = DateFormat('MM.dd HH:mm:ss').format(log.timestamp);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status dot
              SizedBox(
                width: 40,
                child: Icon(
                  log.success
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 16,
                  color: log.success
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
              // User
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.userNickname,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1E293B)),
                    ),
                    Text(
                      log.userId.length > 12
                          ? '${log.userId.substring(log.userId.length - 8)}'
                          : log.userId,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              // Action
              Expanded(
                flex: 1,
                child: _buildTag(
                  log.action.toUpperCase(),
                  log.action == 'reward'
                      ? const Color(0xFF10B981)
                      : log.action == 'show'
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF64748B),
                ),
              ),
              // Provider
              Expanded(
                flex: 1,
                child:
                    _buildTag(log.adProvider, const Color(0xFF3B82F6)),
              ),
              // Type
              Expanded(
                flex: 1,
                child:
                    _buildTag(log.adType, const Color(0xFFF59E0B)),
              ),
              // Network
              Expanded(
                flex: 2,
                child: Text(
                  log.adNetworkClassName ?? '-',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Time
              SizedBox(
                width: 120,
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),

          // Error Details (expanded)
          if (!log.success) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(left: 40),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code ${log.errorCode}',
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      log.errorMessage ?? '알 수 없는 에러',
                      style: const TextStyle(
                          color: Color(0xFFB91C1C), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

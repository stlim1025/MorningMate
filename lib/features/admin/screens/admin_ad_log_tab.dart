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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '광고 로그',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => controller.fetchAdLogs(refresh: true),
                    tooltip: '새로고침',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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
            child: const Center(child: Text('광고 로그가 없습니다.')),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.fetchAdLogs(refresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: logs.length + (controller.hasMoreAdLogs ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          if (index == logs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final log = logs[index];
          return _buildLogTile(log);
        },
      ),
    );
  }

  Widget _buildLogTile(AdLogModel log) {
    final dateStr = DateFormat('MM-dd HH:mm:ss').format(log.timestamp);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                log.success ? Icons.check_circle : Icons.error_outline,
                color: log.success ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${log.userNickname} (${log.userId.substring(log.userId.length - 6)})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildBadge(log.adProvider, Colors.blue),
              const SizedBox(width: 4),
              _buildBadge(log.adType, Colors.orange),
              if (log.adNetworkClassName != null) ...[
                const SizedBox(width: 4),
                _buildBadge(log.adNetworkClassName!, Colors.teal),
              ],
            ],
          ),
          if (!log.success) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error Code: ${log.errorCode}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.errorMessage ?? '알 수 없는 에러',
                    style: TextStyle(color: Colors.red[900], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

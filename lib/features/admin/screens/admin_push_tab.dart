import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';

class AdminPushTab extends StatefulWidget {
  const AdminPushTab({super.key});

  @override
  State<AdminPushTab> createState() => _AdminPushTabState();
}

class _AdminPushTabState extends State<AdminPushTab> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _deepLinkController = TextEditingController();
  final _targetUserIdController = TextEditingController();
  String _target =
      'all'; // all, inactive_3days, consecutive_10days, specific_user

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AdminController>().fetchPushHistory());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _deepLinkController.dispose();
    _targetUserIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('푸시 메시지 전송 (FCM)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildPushForm(context)),
              const SizedBox(width: 32),
              Expanded(flex: 1, child: _buildHistoryPanel(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPushForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('새 푸시 발송',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 16),
            const Text('전송 대상 (Target)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: _target,
              items: const [
                DropdownMenuItem(
                    value: 'all', child: Text('전체 유저 (All Users)')),
                DropdownMenuItem(
                    value: 'inactive_3days', child: Text('최근 3일 미접속 유저')),
                DropdownMenuItem(
                    value: 'consecutive_10days',
                    child: Text('연속 일기 10일 달성 유저')),
                DropdownMenuItem(
                    value: 'specific_user', child: Text('특정 유저 (UID/이메일 입력)')),
              ],
              onChanged: (val) => setState(() => _target = val ?? 'all'),
            ),
            if (_target == 'specific_user') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _targetUserIdController,
                decoration: const InputDecoration(
                    labelText: '수신 유저 UID 또는 이메일',
                    border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                  labelText: '푸시 제목', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: '메시지 내용 (Body)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deepLinkController,
              decoration: const InputDecoration(
                  labelText: 'Deep Link (이동할 페이지. 예: shop, nest)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Consumer<AdminController>(
                builder: (context, controller, child) {
                  return ElevatedButton.icon(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: controller.isLoading
                        ? null
                        : () => _sendPush(controller),
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text('푸시 전송하기',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPanel(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('최근 발송 내역',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      context.read<AdminController>().fetchPushHistory(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Consumer<AdminController>(
              builder: (context, controller, child) {
                if (controller.isLoading && controller.pushHistory.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.pushHistory.isEmpty) {
                  return const Center(child: Text('최근 푸시 발송 기록이 없습니다.'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.pushHistory.length,
                  itemBuilder: (context, index) {
                    final h = controller.pushHistory[index];
                    final date = h['sentAt'] != null
                        ? (h['sentAt'] as dynamic).toDate()
                        : null;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notifications_active,
                          color: Colors.orange),
                      title: Text(h['title'] ?? '제목없음',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h['body'] ?? '',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Row(
                            children: [
                              Text('대상: ${h['target']}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.blue)),
                              const SizedBox(width: 8),
                              Text('링크: ${h['deepLink'] ?? "없음"}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      trailing: Text(
                          date != null
                              ? DateFormat('MM/dd HH:mm').format(date)
                              : '-',
                          style: const TextStyle(fontSize: 12)),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendPush(AdminController controller) {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요.')));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('푸시 발송'),
        content: const Text('정말로 이 메시지를 발송하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.sendPushMessage(
                title: _titleController.text,
                body: _bodyController.text,
                target: _target == 'specific_user'
                    ? 'uid:${_targetUserIdController.text}'
                    : _target,
                deepLink: _deepLinkController.text.isNotEmpty
                    ? _deepLinkController.text
                    : null,
              );
              _titleController.clear();
              _bodyController.clear();
              _deepLinkController.clear();
              _targetUserIdController.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('푸시 전송을 요청했습니다.')));
            },
            child: const Text('발송'),
          ),
        ],
      ),
    );
  }
}

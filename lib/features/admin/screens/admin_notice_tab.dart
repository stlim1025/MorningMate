import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';

class AdminNoticeTab extends StatefulWidget {
  const AdminNoticeTab({super.key});

  @override
  State<AdminNoticeTab> createState() => _AdminNoticeTabState();
}

class _AdminNoticeTabState extends State<AdminNoticeTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AdminController>().fetchNotices());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.notices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('공지사항 목록',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => _showEditorDialog(context, controller),
                    icon: const Icon(Icons.edit),
                    label: const Text('신규 공지 작성'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => controller.fetchNotices(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.notices.length,
                  itemBuilder: (context, index) {
                    final notice = controller.notices[index];
                    final date = notice['createdAt'] != null
                        ? (notice['createdAt'] as dynamic).toDate()
                        : null;
                    return Card(
                      child: ListTile(
                        leading:
                            _buildCategoryChip(notice['category'] ?? '[이벤트]'),
                        title: Row(
                          children: [
                            if (notice['isPinned'] == true)
                              const Icon(Icons.push_pin,
                                  size: 16, color: Colors.orange),
                            if (notice['isPinned'] == true)
                              const SizedBox(width: 4),
                            Text(notice['title'] ?? '제목 없음',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        subtitle: Text(date != null
                            ? DateFormat('yyyy-MM-dd HH:mm').format(date)
                            : '-'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _confirmDelete(context, controller, notice['id']),
                        ),
                        onTap: () {
                          // TODO: 공지 상세 보기 (선택사항)
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip(String category) {
    Color color = Colors.grey;
    if (category == '[이벤트]') color = Colors.pink;
    if (category == '[업데이트]') color = Colors.blue;
    if (category == '[점검 안내]') color = Colors.red;

    return Chip(
      label: Text(category,
          style: const TextStyle(fontSize: 10, color: Colors.white)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  void _showEditorDialog(BuildContext context, AdminController controller) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = '[이벤트]';
    bool isPinned = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('공지사항 작성'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          DropdownButton<String>(
                            value: category,
                            items: const [
                              DropdownMenuItem(
                                  value: '[이벤트]', child: Text('[이벤트]')),
                              DropdownMenuItem(
                                  value: '[업데이트]', child: Text('[업데이트]')),
                              DropdownMenuItem(
                                  value: '[점검 안내]', child: Text('[점검 안내]')),
                            ],
                            onChanged: (val) =>
                                setState(() => category = val ?? category),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Text('상단 고정'),
                              Checkbox(
                                value: isPinned,
                                onChanged: (val) =>
                                    setState(() => isPinned = val ?? false),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                            labelText: '제목', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: contentController,
                        maxLines: 10,
                        decoration: const InputDecoration(
                            labelText: '본문',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소')),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        contentController.text.isNotEmpty) {
                      controller.createNotice(
                        title: titleController.text,
                        content: contentController.text,
                        category: category,
                        isPinned: isPinned,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('게시'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, AdminController controller, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('공지 삭제'),
        content: const Text('정말로 이 공지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteNotice(id);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

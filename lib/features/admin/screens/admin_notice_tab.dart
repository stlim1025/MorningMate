import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_dialog.dart';

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
                  const Icon(Icons.article_rounded,
                      size: 20, color: Color(0xFF475569)),
                  const SizedBox(width: 8),
                  Text(
                    '전체 ${controller.notices.length}건',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showEditorDialog(context, controller),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('신규 공지 작성',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
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
                      width: 80,
                      child: Text('카테고리',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B)))),
                  Expanded(
                      flex: 4,
                      child: Text('제목',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B)))),
                  SizedBox(
                      width: 140,
                      child: Text('작성일',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B)))),
                  SizedBox(
                      width: 60,
                      child: Text('관리',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B)))),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // ── List ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => controller.fetchNotices(),
                child: controller.notices.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 64, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 16),
                            Text('공지사항이 없습니다.',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: controller.notices.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final notice = controller.notices[index];
                          final date = notice['createdAt'] != null
                              ? (notice['createdAt'] as dynamic).toDate()
                              : null;
                          final category =
                              notice['category'] ?? '[이벤트]';

                          return Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            child: Row(
                              children: [
                                // Category
                                SizedBox(
                                  width: 80,
                                  child: _buildCategoryTag(category),
                                ),
                                // Title
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      if (notice['isPinned'] == true) ...[
                                        const Icon(Icons.push_pin_rounded,
                                            size: 14,
                                            color: Color(0xFFF59E0B)),
                                        const SizedBox(width: 6),
                                      ],
                                      Expanded(
                                        child: Text(
                                          notice['title'] ?? '제목 없음',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Date
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    date != null
                                        ? DateFormat('yyyy.MM.dd HH:mm')
                                            .format(date)
                                        : '-',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                // Delete
                                SizedBox(
                                  width: 60,
                                  child: Center(
                                    child: InkWell(
                                      onTap: () => _confirmDelete(
                                          context,
                                          controller,
                                          notice['id']),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: Color(0xFFEF4444)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildCategoryTag(String category) {
    Color color;
    if (category == '[이벤트]') {
      color = const Color(0xFFEC4899);
    } else if (category == '[업데이트]') {
      color = const Color(0xFF3B82F6);
    } else if (category == '[점검 안내]') {
      color = const Color(0xFFEF4444);
    } else {
      color = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.replaceAll('[', '').replaceAll(']', ''),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
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
            return AdminWebDialog(
              title: '공지사항 작성',
              titleIcon: Icons.edit_note,
              width: 700,
              height: 600,
              content: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('카테고리',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: category,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFFAFAFA),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: '[이벤트]',
                                      child: Text('[이벤트]')),
                                  DropdownMenuItem(
                                      value: '[업데이트]',
                                      child: Text('[업데이트]')),
                                  DropdownMenuItem(
                                      value: '[점검 안내]',
                                      child: Text('[점검 안내]')),
                                ],
                                onChanged: (val) => setState(
                                    () => category = val ?? category),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isPinned
                                ? const Color(0xFFFFF7ED)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: isPinned
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.push_pin_rounded,
                                  size: 16,
                                  color: isPinned
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF94A3B8)),
                              const SizedBox(width: 6),
                              const Text('상단 고정',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Switch(
                                value: isPinned,
                                onChanged: (val) =>
                                    setState(() => isPinned = val),
                                activeColor: const Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('제목',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: '공지사항 제목을 입력하세요',
                        hintStyle: const TextStyle(
                            color: Color(0xFFCBD5E1), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('본문',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: contentController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        hintText: '본문 내용을 입력하세요',
                        hintStyle: const TextStyle(
                            color: Color(0xFFCBD5E1), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0))),
                      ),
                    ),
                  ],
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
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
      builder: (ctx) => AdminWebDialog(
        title: '공지 삭제',
        titleIcon: Icons.delete_outline,
        height: 200,
        content: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('정말로 이 공지를 삭제하시겠습니까?'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteNotice(id);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

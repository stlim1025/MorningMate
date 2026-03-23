import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_dialog.dart';

class AdminReleaseNoteTab extends StatefulWidget {
  const AdminReleaseNoteTab({super.key});

  @override
  State<AdminReleaseNoteTab> createState() => _AdminReleaseNoteTabState();
}

class _AdminReleaseNoteTabState extends State<AdminReleaseNoteTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AdminController>().fetchReleaseNotes());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.releaseNotes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

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
                  const Icon(Icons.notes_rounded,
                      size: 20, color: Color(0xFF475569)),
                  const SizedBox(width: 8),
                  Text(
                    '총 ${controller.releaseNotes.length}건',
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
                    label: const Text('출시노트 작성',
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              color: const Color(0xFFF8FAFC),
              child: const Row(
                children: [
                  SizedBox(
                      width: 100,
                      child: Text('버전',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B)))),
                  Expanded(
                      flex: 4,
                      child: Text('주요 내용 (한국어)',
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
                      width: 180,
                      child: Text('내용 복사',
                          textAlign: TextAlign.center,
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
                onRefresh: () async => controller.fetchReleaseNotes(),
                child: controller.releaseNotes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 64, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 16),
                            Text('작성된 출시노트가 없습니다.',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: controller.releaseNotes.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final note = controller.releaseNotes[index];
                          final dateRaw = note['createdAt'];
                          DateTime? date;
                          if (dateRaw != null) {
                            try {
                              date = dateRaw.toDate();
                            } catch (_) {
                              // is timestamp or maybe string
                            }
                          }
                          final version = note['version'] ?? '-';
                          final contentKo = note['contentKo'] ?? '-';

                          return InkWell(
                            onTap: () => _showEditorDialog(context, controller,
                                existingNote: note),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      version,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      contentKo,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF1E293B),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 140,
                                    child: Text(
                                      date != null
                                          ? DateFormat('yyyy.MM.dd')
                                              .format(date)
                                          : '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 180,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildCopyAllButton(context, note),
                                        _buildCopyButton(context, 'KO',
                                            note['contentKo'] ?? ''),
                                        _buildCopyButton(context, 'EN',
                                            note['contentEn'] ?? ''),
                                        _buildCopyButton(context, 'JA',
                                            note['contentJa'] ?? ''),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Center(
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: Color(0xFFEF4444)),
                                        onPressed: () => _confirmDelete(
                                            context, controller, note['id']),
                                        splashRadius: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

  void _showEditorDialog(BuildContext context, AdminController controller,
      {Map<String, dynamic>? existingNote}) {
    final versionController =
        TextEditingController(text: existingNote?['version'] ?? '');
    final koController =
        TextEditingController(text: existingNote?['contentKo'] ?? '');
    final enController =
        TextEditingController(text: existingNote?['contentEn'] ?? '');
    final jaController =
        TextEditingController(text: existingNote?['contentJa'] ?? '');
    bool isTranslating = false;
    final translator = GoogleTranslator();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> handleTranslate() async {
              if (koController.text.trim().isEmpty) return;
              setState(() => isTranslating = true);

              try {
                final textKo = koController.text.trim();
                final enResult =
                    await translator.translate(textKo, from: 'ko', to: 'en');
                final jaResult =
                    await translator.translate(textKo, from: 'ko', to: 'ja');

                enController.text = enResult.text;
                jaController.text = jaResult.text;
              } catch (e) {
                // error dialog could be shown here
              } finally {
                setState(() => isTranslating = false);
              }
            }

            return AdminWebDialog(
              title: existingNote == null ? '출시노트 작성' : '출시노트 수정',
              titleIcon: Icons.edit_note,
              width: 800,
              height: 900,
              content: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('버전',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: versionController,
                      decoration: InputDecoration(
                        hintText: '예: 1.0.0',
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('내용 (한국어)',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569))),
                        TextButton.icon(
                          onPressed: isTranslating ? null : handleTranslate,
                          icon: isTranslating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.translate, size: 16),
                          label: const Text('번역하기 (EN/JA)'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: koController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: '출시노트 내용을 한글로 입력하세요',
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Content (English)',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: enController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('コンテンツ (日本語)',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: jaController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
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
                    final version = versionController.text.trim();
                    final ko = koController.text.trim();
                    final en = enController.text.trim();
                    final ja = jaController.text.trim();

                    if (version.isEmpty || ko.isEmpty) return;

                    if (existingNote == null) {
                      controller.createReleaseNote(
                          version: version,
                          contentKo: ko,
                          contentEn: en,
                          contentJa: ja);
                    } else {
                      controller.updateReleaseNote(
                          id: existingNote['id'],
                          version: version,
                          contentKo: ko,
                          contentEn: en,
                          contentJa: ja);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('저장'),
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
        title: '출시노트 삭제',
        titleIcon: Icons.delete_outline,
        height: 200,
        content: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('정말로 이 출시노트를 삭제하시겠습니까?'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteReleaseNote(id);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context, String label, String text) {
    return Tooltip(
      message: '$label 내용 복사',
      child: InkWell(
        onTap: () {
          if (text.isEmpty) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$label 내용이 없습니다.')));
            return;
          }
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$label 내용이 복사되었습니다.')));
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569))),
        ),
      ),
    );
  }

  Widget _buildCopyAllButton(BuildContext context, Map<String, dynamic> note) {
    return Tooltip(
      message: '전체 (XML) 복사',
      child: InkWell(
        onTap: () {
          final ko = note['contentKo'] ?? '';
          final en = note['contentEn'] ?? '';
          final ja = note['contentJa'] ?? '';

          final text = '''<en-US>
$en
</en-US>
<ja-JP>
$ja
</ja-JP>
<ko-KR>
$ko
</ko-KR>''';

          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('전체 내용 형식으로 복사되었습니다.')));
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('ALL',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
      ),
    );
  }
}


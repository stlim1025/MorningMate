import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_dialog.dart';
import '../../../data/models/user_model.dart';

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
  String _target = 'all';
  UserModel? _foundUser;
  bool _isCheckingUser = false;
  final Set<String> _selectedUids = {};
  final _userSearchController = TextEditingController();

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
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: Push Form ──
              Expanded(
                flex: 5,
                child: _buildPushForm(context),
              ),
              const SizedBox(width: 24),
              // ── Right: Target Info or User Selection ──
              Expanded(
                flex: 4,
                child: _target == 'specific_user'
                    ? _buildUserSelectionPanel(context)
                    : _buildTargetInfoPanel(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildHistoryPanel(context),
        ],
      ),
    );
  }

  // ── Target Info Panel ──
  Widget _buildTargetInfoPanel(BuildContext context) {
    String description = '';
    IconData icon = Icons.info_outline;
    Color color = const Color(0xFF6366F1);
    switch (_target) {
      case 'all':
        description = '가입한 모든 사용자에게 알림을 보냅니다.';
        icon = Icons.groups_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case 'inactive_3days':
        description = '최근 3일 동안 접속하지 않은 사용자에게 알림을 보냅니다.';
        icon = Icons.person_off_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'consecutive_10days':
        description = '10일 연속으로 일기를 작성 중인 열혈 사용자에게 알림을 보냅니다.';
        icon = Icons.local_fire_department_rounded;
        color = const Color(0xFFEF4444);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: 20),
          Text(description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5)),
          const SizedBox(height: 12),
          const Text('선택한 타겟 대상으로 일괄 발송됩니다.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Push Form ──
  Widget _buildPushForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('새 푸시 발송',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 24),

          // Target Dropdown
          _buildLabel('전송 대상'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _target,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('모든 사용자')),
              DropdownMenuItem(
                  value: 'inactive_3days', child: Text('미접속자 (3일)')),
              DropdownMenuItem(
                  value: 'consecutive_10days',
                  child: Text('10일 연속 일기 작성자')),
              DropdownMenuItem(
                  value: 'specific_user',
                  child: Text('특정 유저 (UID/이메일 입력)')),
            ],
            onChanged: (val) => setState(() {
              _target = val!;
              _foundUser = null;
            }),
          ),

          // Specific User Input
          if (_target == 'specific_user') ...[
            const SizedBox(height: 16),
            _buildLabel('개별 입력 또는 우측 리스트에서 선택'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _targetUserIdController,
                    hint: 'UID 또는 이메일 직접 입력',
                    onChanged: (_) => setState(() => _foundUser = null),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF475569),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: _isCheckingUser ? null : _checkUser,
                    child: _isCheckingUser
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('추가', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
            if (_foundUser != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '추가됨: ${_foundUser!.nickname}',
                        style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _foundUser = null),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
            if (_selectedUids.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 80),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedUids.map((uid) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                uid.length > 15
                                    ? '${uid.substring(0, 12)}...'
                                    : uid,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF475569))),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () =>
                                  setState(() => _selectedUids.remove(uid)),
                              child: const Icon(Icons.close_rounded,
                                  size: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _selectedUids.clear()),
                  child: const Text('모두 해제',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFFEF4444))),
                ),
              ),
            ],
          ] else
            const SizedBox(height: 16),
          const SizedBox(height: 8),

          // Title
          _buildLabel('푸시 제목'),
          const SizedBox(height: 6),
          _buildTextField(
              controller: _titleController, hint: '푸시 알림 제목을 입력하세요'),
          const SizedBox(height: 16),

          // Body
          _buildLabel('메시지 내용'),
          const SizedBox(height: 6),
          _buildTextField(
              controller: _bodyController,
              hint: '메시지 본문을 작성하세요',
              maxLines: 3),
          const SizedBox(height: 16),

          // Deep Link
          _buildLabel('Deep Link'),
          const SizedBox(height: 6),
          _buildTextField(
              controller: _deepLinkController,
              hint: '이동할 페이지 (예: shop, nest)'),
          const SizedBox(height: 28),

          // Send Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: Consumer<AdminController>(
              builder: (context, controller, child) {
                return ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('푸시 전송하기',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: controller.isLoading
                      ? null
                      : () => _sendPush(controller),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── User Selection Panel ──
  Widget _buildUserSelectionPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('수신 유저 선택',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${_selectedUids.length}명 선택',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _userSearchController,
                  hint: '닉네임 검색...',
                  prefixIcon: Icons.search_rounded,
                  onSubmitted: (val) {
                    context
                        .read<AdminController>()
                        .fetchUsers(isRefresh: true, searchQuery: val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  context.read<AdminController>().fetchUsers(
                      isRefresh: true,
                      searchQuery: _userSearchController.text);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 350,
            child: Consumer<AdminController>(
              builder: (context, controller, child) {
                final users = controller.allUsers;
                if (controller.isLoading && users.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (users.isEmpty) {
                  return const Center(
                      child: Text('검색 결과가 없습니다.',
                          style: TextStyle(color: Color(0xFF94A3B8))));
                }

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isSelected = _selectedUids.contains(user.uid);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedUids.remove(user.uid);
                          } else {
                            _selectedUids.add(user.uid);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        color: isSelected
                            ? const Color(0xFFF5F3FF)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(user.nickname,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(user.email,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (context.watch<AdminController>().hasMoreUsers)
            Center(
              child: TextButton(
                onPressed: () =>
                    context.read<AdminController>().fetchUsers(),
                child: const Text('더 불러오기',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF6366F1))),
              ),
            ),
        ],
      ),
    );
  }

  // ── History Panel ──
  Widget _buildHistoryPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('발송 내역',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B))),
              InkWell(
                onTap: () =>
                    context.read<AdminController>().fetchPushHistory(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 14, color: Color(0xFF64748B)),
                      SizedBox(width: 4),
                      Text('새로고침',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: const Row(
              children: [
                SizedBox(
                    width: 60,
                    child: Center(
                      child: Text('상태',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B))),
                    )),
                Expanded(
                    flex: 3,
                    child: Text('제목 / 내용',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B)))),
                Expanded(
                    flex: 1,
                    child: Text('대상',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B)))),
                SizedBox(
                    width: 100,
                    child: Center(
                      child: Text('결과',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B))),
                    )),
                SizedBox(
                    width: 110,
                    child: Center(
                      child: Text('발송일시',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B))),
                    )),
              ],
            ),
          ),
          Consumer<AdminController>(
            builder: (context, controller, child) {
              if (controller.isLoading && controller.pushHistory.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.pushHistory.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('발송 내역이 없습니다.',
                        style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.pushHistory.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final h = controller.pushHistory[index];
                  final date = h['sentAt'] != null
                      ? (h['sentAt'] as dynamic).toDate()
                      : null;
                  final status = h['status'] ?? 'sent';
                  final success = h['successCount'] ?? 0;
                  final failure = h['failureCount'] ?? 0;
                  final error = h['error'];

                  Color statusColor;
                  String statusLabel;
                  if (status == 'processed') {
                    statusColor = const Color(0xFF10B981);
                    statusLabel = '완료';
                  } else if (status == 'error') {
                    statusColor = const Color(0xFFEF4444);
                    statusLabel = '오류';
                  } else {
                    statusColor = const Color(0xFFF59E0B);
                    statusLabel = '대기';
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(statusLabel,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: statusColor,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(h['title'] ?? '제목없음',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Color(0xFF1E293B))),
                              const SizedBox(height: 2),
                              Text(h['body'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8))),
                              if (error != null) ...[
                                const SizedBox(height: 2),
                                Text('에러: $error',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFEF4444))),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('${h['target']}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B))),
                        ),
                        SizedBox(
                          width: 100,
                          child: status == 'processed'
                              ? Text('$success / $failure',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w600))
                              : const Text('—',
                                  style: TextStyle(
                                      color: Color(0xFFCBD5E1))),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text(
                            date != null
                                ? DateFormat('MM.dd HH:mm')
                                    .format(date)
                                : '-',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                                fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Common Building Blocks ──

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569)));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    IconData? prefixIcon,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: const Color(0xFF94A3B8))
            : null,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
      ),
    );
  }

  // ── Logic ──

  Future<void> _checkUser() async {
    final target = _targetUserIdController.text.trim();
    if (target.isEmpty) return;

    setState(() => _isCheckingUser = true);
    final user = await context.read<AdminController>().findUserByTarget(target);
    setState(() {
      if (user != null) {
        _selectedUids.add(user.uid);
        _targetUserIdController.clear();
      }
      _foundUser = user;
      _isCheckingUser = false;
    });

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해당 UID 또는 이메일을 가진 유저를 찾을 수 없습니다.')),
        );
      }
    }
  }

  void _sendPush(AdminController controller) {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요.')));
      return;
    }

    if (_target == 'specific_user' && _selectedUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수신할 유저를 최소 1명 이상 선택하거나 입력해주세요.')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AdminWebDialog(
        title: '푸시 발송 확인',
        titleIcon: Icons.send,
        height: 250,
        content: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_target == 'specific_user'
              ? '${_selectedUids.length}명의 유저에게 푸시를 발송하시겠습니까?'
              : '정말로 이 메시지를 모든 대상에게 발송하시겠습니까?'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);

              String finalTarget;
              if (_target == 'specific_user') {
                finalTarget = 'uids:${_selectedUids.join(',')}';
              } else {
                finalTarget = _target;
              }

              controller.sendPushMessage(
                title: _titleController.text,
                body: _bodyController.text,
                target: finalTarget,
                deepLink: _deepLinkController.text.isNotEmpty
                    ? _deepLinkController.text
                    : null,
              );
              _titleController.clear();
              _bodyController.clear();
              _deepLinkController.clear();
              _targetUserIdController.clear();
              setState(() {
                _foundUser = null;
                _selectedUids.clear();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('푸시 전송을 요청했습니다.')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('발송'),
          ),
        ],
      ),
    );
  }
}

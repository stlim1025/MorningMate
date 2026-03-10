import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';
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
  String _target =
      'all'; // all, inactive_3days, consecutive_10days, specific_user
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
              Expanded(
                flex: 5,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 560),
                  child: _buildPushForm(context),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 560),
                  child: _target == 'specific_user'
                      ? _buildUserSelectionPanel(context)
                      : _buildTargetInfoPanel(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildHistoryPanel(context),
        ],
      ),
    );
  }

  Widget _buildTargetInfoPanel(BuildContext context) {
    String description = '';
    IconData icon = Icons.info_outline;
    switch (_target) {
      case 'all':
        description = '가입한 모든 사용자에게 알림을 보냅니다.';
        icon = Icons.group;
        break;
      case 'inactive_3days':
        description = '최근 3일 동안 접속하지 않은 사용자에게 알림을 보냅니다.';
        icon = Icons.person_off;
        break;
      case 'consecutive_10days':
        description = '10일 연속으로 일기를 작성 중인 열혈 사용자에게 알림을 보냅니다.';
        icon = Icons.local_fire_department;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.blue.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            const Text('현재 타겟을 대상으로 일괄 발송이 가능합니다.',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPushForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('새 푸시 발송',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 16),
            const Text('전송 대상 (Target)',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _target,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('모든 사용자')),
                DropdownMenuItem(
                    value: 'inactive_3days', child: Text('미접속자 (3일)')),
                DropdownMenuItem(
                    value: 'consecutive_10days', child: Text('10일 연속 일기 작성자')),
                DropdownMenuItem(
                    value: 'specific_user', child: Text('특정 유저 (UID/이메일 입력)')),
              ],
              onChanged: (val) => setState(() {
                _target = val!;
                _foundUser = null;
                // _selectedUids.clear(); // 타겟 변경 시 선택 목록 초기화할지 선택 (현재는 유지)
              }),
            ),
            if (_target == 'specific_user') ...[
              const SizedBox(height: 16),
              const Text('개별 입력 또는 우측 리스트에서 선택',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetUserIdController,
                      decoration: const InputDecoration(
                          hintText: 'UID 또는 이메일 직접 입력',
                          labelText: '수신 유저',
                          isDense: true,
                          border: OutlineInputBorder()),
                      onChanged: (_) => setState(() => _foundUser = null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isCheckingUser ? null : _checkUser,
                      child: _isCheckingUser
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('추가'),
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
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[100]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '추가됨: ${_foundUser!.nickname}',
                          style: const TextStyle(
                              color: Colors.green,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _foundUser = null),
                      ),
                    ],
                  ),
                ),
              ],
              if (_selectedUids.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedUids.map((uid) {
                        return Chip(
                          backgroundColor: Colors.blue[50],
                          side: BorderSide(color: Colors.blue[100]!),
                          label: Text(
                              uid.length > 15
                                  ? uid.substring(0, 12) + '...'
                                  : uid,
                              style: const TextStyle(fontSize: 11)),
                          onDeleted: () =>
                              setState(() => _selectedUids.remove(uid)),
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
                        style: TextStyle(fontSize: 12, color: Colors.red)),
                  ),
                ),
              ],
            ] else
              const SizedBox(height: 16),
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
              height: 50,
              child: Consumer<AdminController>(
                builder: (context, controller, child) {
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('푸시 전송하기',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
      ),
    );
  }

  Widget _buildUserSelectionPanel(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('수신 유저 선택',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('선택됨: ${_selectedUids.length}명',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userSearchController,
                    decoration: InputDecoration(
                      hintText: '닉네임 검색...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (val) {
                      context
                          .read<AdminController>()
                          .fetchUsers(isRefresh: true, searchQuery: val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<AdminController>().fetchUsers(
                        isRefresh: true,
                        searchQuery: _userSearchController.text);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 350, // Expanded 대신 고정 높이 또는 제한 높이 사용
              child: Consumer<AdminController>(
                builder: (context, controller, child) {
                  final users = controller.allUsers;
                  if (controller.isLoading && users.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (users.isEmpty) {
                    return const Center(child: Text('검색 결과가 없습니다.'));
                  }

                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isSelected = _selectedUids.contains(user.uid);

                      return CheckboxListTile(
                        value: isSelected,
                        dense: true,
                        title: Text(user.nickname,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(user.email,
                            style: const TextStyle(fontSize: 11)),
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              _selectedUids.add(user.uid);
                            } else {
                              _selectedUids.remove(user.uid);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            if (context.watch<AdminController>().hasMoreUsers)
              Center(
                child: TextButton(
                  onPressed: () => context.read<AdminController>().fetchUsers(),
                  child: const Text('더 불러오기'),
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
            const SizedBox(height: 8),
            Consumer<AdminController>(
              builder: (context, controller, child) {
                if (controller.isLoading && controller.pushHistory.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.pushHistory.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('발송 내역이 없습니다.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  );
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
                    final status = h['status'] ?? 'sent';
                    final success = h['successCount'] ?? 0;
                    final failure = h['failureCount'] ?? 0;
                    final error = h['error'];

                    Color statusColor = Colors.grey;
                    String statusLabel = '대기중';

                    if (status == 'processed') {
                      statusColor = Colors.green;
                      statusLabel = '완료';
                    } else if (status == 'error') {
                      statusColor = Colors.red;
                      statusLabel = '오류';
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.notifications_active,
                          color: status == 'error'
                              ? Colors.red
                              : status == 'processed'
                                  ? Colors.green
                                  : Colors.orange),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(h['title'] ?? '제목없음',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(statusLabel,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h['body'] ?? '',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (status == 'processed')
                            Text('성공: $success / 실패: $failure',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold)),
                          if (error != null)
                            Text('에러: $error',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.red)),
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
      builder: (ctx) => AlertDialog(
        title: const Text('푸시 발송'),
        content: Text(_target == 'specific_user'
            ? '${_selectedUids.length}명의 유저에게 푸시를 발송하시겠습니까?'
            : '정말로 이 메시지를 모든 대상에게 발송하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
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
            child: const Text('발송'),
          ),
        ],
      ),
    );
  }
}

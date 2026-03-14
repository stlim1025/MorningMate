import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_dialog.dart';
import '../../../data/models/user_model.dart';

class AdminUserListTab extends StatefulWidget {
  const AdminUserListTab({super.key});

  @override
  State<AdminUserListTab> createState() => _AdminUserListTabState();
}

class _AdminUserListTabState extends State<AdminUserListTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => context.read<AdminController>().fetchUsers(isRefresh: true));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        final users = controller.allUsers;

        return Column(
          children: [
            // ── Header Bar ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border:
                    Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  // Search
                  SizedBox(
                    width: 320,
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '닉네임으로 검색...',
                        hintStyle: const TextStyle(
                            color: Color(0xFFCBD5E1), fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 18, color: Color(0xFF94A3B8)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 16, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  _searchController.clear();
                                  controller.fetchUsers(
                                      isRefresh: true, searchQuery: '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF6366F1), width: 1.5),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (value) => controller.fetchUsers(
                          isRefresh: true, searchQuery: value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => controller.fetchUsers(
                        isRefresh: true,
                        searchQuery: _searchController.text),
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
                  const Spacer(),
                  Text(
                    '총 ${users.length}명',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // ── Table ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.fetchUsers(
                    isRefresh: true,
                    searchQuery: _searchController.text),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dataTableTheme: DataTableThemeData(
                            headingTextStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                            dataTextStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                            ),
                            headingRowColor:
                                MaterialStateProperty.all(
                                    const Color(0xFFF8FAFC)),
                          ),

                        ),
                        child: PaginatedDataTable(
                          header: null,
                          rowsPerPage: 10,
                          availableRowsPerPage: const [10, 20, 50],
                          showCheckboxColumn: false,
                          onPageChanged: (pageIndex) {
                            if (pageIndex + 20 >= users.length &&
                                controller.hasMoreUsers) {
                              controller.fetchUsers();
                            }
                          },
                          columns: const [
                            DataColumn(label: Text('상태')),
                            DataColumn(label: Text('닉네임')),
                            DataColumn(label: Text('가입/이메일')),
                            DataColumn(label: Text('OS')),
                            DataColumn(label: Text('연속출석')),
                            DataColumn(label: Text('보유 가지')),
                            DataColumn(label: Text('마지막 접속/일기')),
                            DataColumn(label: Text('관리')),
                          ],
                          source: _UserDataSource(
                            context: context,
                            users: users,
                            controller: controller,
                            onShowLog: (u) => _showUserLogDialog(
                                context, u, controller),
                            onEditPoints: (u) =>
                                _showEditPointsDialog(context, u),
                            onRecoverDiary: (u) =>
                                _showLocalDiaryRecoveryDialog(
                                    context, u),
                            onUnsuspend: (u) =>
                                _confirmUnsuspend(context, u),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUserLogDialog(
      BuildContext context, UserModel user, AdminController controller) {
    controller.fetchUserLogs(user.uid);
    showDialog(
      context: context,
      builder: (context) {
        return AdminWebDialog(
          title: '${user.nickname} 활동 로그',
          titleIcon: Icons.history_rounded,
          width: 600,
          content: Consumer<AdminController>(
            builder: (context, c, child) {
              if (c.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (c.userLogs.isEmpty) {
                return const Center(child: Text('로그가 없습니다.'));
              }
              return ListView.separated(
                itemCount: c.userLogs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final log = c.userLogs[index];
                  final date = log['createdAt'] != null
                      ? (log['createdAt'] as dynamic).toDate()
                      : null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.receipt_long_rounded,
                              size: 14, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            log['message'] ?? '내용 없음',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF334155)),
                          ),
                        ),
                        Text(
                          _formatDate(date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  void _showEditPointsDialog(BuildContext context, UserModel user) {
    final pointsController =
        TextEditingController(text: user.points.toString());
    showDialog(
      context: context,
      builder: (context) => AdminWebDialog(
        title: '가지 수량 수정',
        titleIcon: Icons.edit_rounded,
        width: 400,
        height: 280,
        content: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('수정할 가지 수',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569))),
              const SizedBox(height: 6),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '숫자를 입력하세요',
                  hintStyle: const TextStyle(
                      color: Color(0xFFCBD5E1), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPoints = int.tryParse(pointsController.text);
              if (newPoints != null) {
                Navigator.pop(context);
                context
                    .read<AdminController>()
                    .updateUserPoints(user.uid, newPoints);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  void _showLocalDiaryRecoveryDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AdminWebDialog(
        title: '${user.nickname} 일기 스캔',
        titleIcon: Icons.scanner_rounded,
        width: 500,
        content: FutureBuilder<List<String>>(
          future:
              context.read<AdminController>().scanLocalDiaries(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final dates = snapshot.data ?? [];
            if (dates.isEmpty) {
              return const Center(
                  child: Text('로컬 암호화 일기가 없습니다.'));
            }
            return ListView.separated(
              itemCount: dates.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded,
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(dates[index],
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await context
                              .read<AdminController>()
                              .recoverLocalDiary(
                                  user.uid, dates[index]);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: const Text('복구',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          )
        ],
      ),
    );
  }

  void _confirmUnsuspend(BuildContext context, UserModel user) {
    context.read<AdminController>().unsuspendUser(user.uid);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }
}

class _UserDataSource extends DataTableSource {
  final BuildContext context;
  final List<UserModel> users;
  final AdminController controller;
  final Function(UserModel) onShowLog;
  final Function(UserModel) onEditPoints;
  final Function(UserModel) onRecoverDiary;
  final Function(UserModel) onUnsuspend;

  _UserDataSource({
    required this.context,
    required this.users,
    required this.controller,
    required this.onShowLog,
    required this.onEditPoints,
    required this.onRecoverDiary,
    required this.onUnsuspend,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= users.length) return null;
    final user = users[index];
    final isSuspended = user.suspendedUntil != null &&
        user.suspendedUntil!.isAfter(DateTime.now());

    bool hasNotWrittenDiaryRecently = false;
    if (user.lastDiaryDate != null) {
      final daysSinceLastDiary =
          DateTime.now().difference(user.lastDiaryDate!).inDays;
      if (daysSinceLastDiary >= 7) {
        hasNotWrittenDiaryRecently = true;
      }
    } else {
      final daysSinceJoined =
          DateTime.now().difference(user.createdAt).inDays;
      if (daysSinceJoined >= 7) {
        hasNotWrittenDiaryRecently = true;
      }
    }

    final rowColor =
        hasNotWrittenDiaryRecently ? const Color(0xFFFEF2F2) : null;

    return DataRow.byIndex(
      index: index,
      color:
          rowColor != null ? MaterialStateProperty.all(rowColor) : null,
      cells: [
        // Status
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isSuspended
                  ? const Tooltip(
                      message: '이용정지',
                      child: Icon(Icons.block_rounded,
                          color: Color(0xFFEF4444), size: 18))
                  : hasNotWrittenDiaryRecently
                      ? const Tooltip(
                          message: '7일 이상 일기 미작성',
                          child: Icon(Icons.warning_rounded,
                              color: Color(0xFFF59E0B), size: 18))
                      : const Tooltip(
                          message: '정상',
                          child: Icon(Icons.check_circle_rounded,
                              color: Color(0xFF10B981), size: 18)),
              if (user.fcmToken != null)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Tooltip(
                    message: '푸시 수신 가능',
                    child: Icon(Icons.notifications_active_rounded,
                        size: 14, color: Color(0xFF6366F1)),
                  ),
                ),
            ],
          ),
        ),
        // Nickname
        DataCell(
          InkWell(
            onTap: () => onShowLog(user),
            child: Text(user.nickname,
                style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline)),
          ),
        ),
        // Email
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(user.loginProviderLabel,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 2),
            Text(user.email,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B))),
          ],
        )),
        // OS
        DataCell(
          Center(
            child: Icon(
              user.platform == 'ios'
                  ? Icons.apple_rounded
                  : (user.platform == 'android'
                      ? Icons.android_rounded
                      : Icons.device_unknown_rounded),
              size: 18,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        // Streak
        DataCell(Text('${user.consecutiveDays}일',
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF334155)))),
        // Points
        DataCell(
          Row(
            children: [
              Text('${user.points}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E))),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => onEditPoints(user),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.edit_rounded,
                      size: 14, color: Color(0xFF6366F1)),
                ),
              ),
            ],
          ),
        ),
        // Last activity
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('접속: ${_formatDate(user.lastLoginDate)}',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF475569))),
            Text('작성: ${_formatDate(user.lastDiaryDate)}',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        )),
        // Actions
        DataCell(
          isSuspended
              ? ElevatedButton(
                  onPressed: () => onUnsuspend(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                  child: const Text('정지 해제',
                      style: TextStyle(fontSize: 11)),
                )
              : OutlinedButton(
                  onPressed: () => onRecoverDiary(user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(
                        color: Color(0xFFCBD5E1)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('일기 복구',
                      style: TextStyle(fontSize: 11)),
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}

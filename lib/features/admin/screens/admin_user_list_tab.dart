import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../core/widgets/app_dialog.dart';

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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '닉네임으로 검색...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  controller.fetchUsers(
                                      isRefresh: true, searchQuery: '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (value) => controller.fetchUsers(
                          isRefresh: true, searchQuery: value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => controller.fetchUsers(
                        isRefresh: true, searchQuery: _searchController.text),
                    icon: const Icon(Icons.refresh),
                    label: const Text('새로고침'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.fetchUsers(
                    isRefresh: true, searchQuery: _searchController.text),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: PaginatedDataTable(
                        header: const Text('유저 목록',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        rowsPerPage: 10,
                        availableRowsPerPage: const [10, 20, 50],
                        showCheckboxColumn: false,
                        onPageChanged: (pageIndex) {
                          // 페이지가 뒤로 넘어갈 때(마지막에 도달했을 때) 더 불러오기
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
                          DataColumn(label: Text('관리 기능')),
                        ],
                        source: _UserDataSource(
                          context: context,
                          users: users,
                          controller: controller,
                          onShowLog: (u) =>
                              _showUserLogDialog(context, u, controller),
                          onEditPoints: (u) =>
                              _showEditPointsDialog(context, u),
                          onRecoverDiary: (u) =>
                              _showLocalDiaryRecoveryDialog(context, u),
                          onUnsuspend: (u) => _confirmUnsuspend(context, u),
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
        return AlertDialog(
          title: Text('${user.nickname} 로그 (최근 50건)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Consumer<AdminController>(
              builder: (context, c, child) {
                if (c.isLoading)
                  return const Center(child: CircularProgressIndicator());
                if (c.userLogs.isEmpty)
                  return const Center(child: Text('로그가 없습니다.'));
                return ListView.builder(
                  itemCount: c.userLogs.length,
                  itemBuilder: (context, index) {
                    final log = c.userLogs[index];
                    final date = log['createdAt'] != null
                        ? (log['createdAt'] as dynamic).toDate()
                        : null;
                    return ListTile(
                      title: Text(log['message'] ?? '내용 없음'),
                      subtitle: Text(_formatDate(date)),
                      leading: const Icon(Icons.info_outline),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기')),
          ],
        );
      },
    );
  }

  void _showEditPointsDialog(BuildContext context, UserModel user) {
    final pointsController =
        TextEditingController(text: user.points.toString());
    AppDialog.show(
      context: context,
      key: AppDialogKey.editPoints,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: pointsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: '수정할 가지 갯수', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        AppDialogAction(label: '취소', onPressed: () => Navigator.pop(context)),
        AppDialogAction(
          label: '수정',
          isPrimary: true,
          onPressed: () {
            final newPoints = int.tryParse(pointsController.text);
            if (newPoints != null) {
              Navigator.pop(context);
              context
                  .read<AdminController>()
                  .updateUserPoints(user.uid, newPoints);
            }
          },
        ),
      ],
    );
  }

  void _showLocalDiaryRecoveryDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.nickname} 일기 스캔'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: FutureBuilder<List<String>>(
            future: context.read<AdminController>().scanLocalDiaries(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              final dates = snapshot.data ?? [];
              if (dates.isEmpty)
                return const Center(child: Text('로컬 암호화 일기가 없습니다.'));
              return ListView.builder(
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(dates[index]),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await context
                            .read<AdminController>()
                            .recoverLocalDiary(user.uid, dates[index]);
                      },
                      child: const Text('복구'),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('닫기'))
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
      final daysSinceJoined = DateTime.now().difference(user.createdAt).inDays;
      if (daysSinceJoined >= 7) {
        hasNotWrittenDiaryRecently = true;
      }
    }

    final rowColor = hasNotWrittenDiaryRecently ? Colors.red[50] : null;

    return DataRow.byIndex(
      index: index,
      color: rowColor != null ? MaterialStateProperty.all(rowColor) : null,
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isSuspended
                  ? const Tooltip(
                      message: '이용정지',
                      child: Icon(Icons.block, color: Colors.red))
                  : hasNotWrittenDiaryRecently
                      ? const Tooltip(
                          message: '7일 이상 일기 미성성',
                          child: Icon(Icons.warning, color: Colors.redAccent))
                      : const Tooltip(
                          message: '정상',
                          child: Icon(Icons.check_circle, color: Colors.green)),
              if (user.fcmToken != null)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Tooltip(
                    message: '푸시 수신 가능',
                    child: Icon(Icons.notifications_active,
                        size: 16, color: Colors.blueAccent),
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          InkWell(
            onTap: () => onShowLog(user),
            child: Text(user.nickname,
                style: const TextStyle(
                    color: Colors.blue, decoration: TextDecoration.underline)),
          ),
        ),
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(user.loginProviderLabel,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            Text(user.email, style: const TextStyle(fontSize: 12)),
          ],
        )),
        DataCell(
          Center(
            child: Icon(
              user.platform == 'ios'
                  ? Icons.apple
                  : (user.platform == 'android'
                      ? Icons.android
                      : Icons.device_unknown),
              size: 20,
              color: Colors.grey[600],
            ),
          ),
        ),
        DataCell(Text('${user.consecutiveDays}일',
            style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(
          Row(
            children: [
              Text('${user.points}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.brown)),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                onPressed: () => onEditPoints(user),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('접속: ${_formatDate(user.lastLoginDate)}',
                style: const TextStyle(fontSize: 10)),
            Text('작성: ${_formatDate(user.lastDiaryDate)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        )),
        DataCell(
          Row(
            children: [
              if (isSuspended)
                ElevatedButton(
                  onPressed: () => onUnsuspend(user),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: const Text('정지 해제',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                )
              else
                OutlinedButton(
                  onPressed: () => onRecoverDiary(user),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: const Text('일기 복구', style: TextStyle(fontSize: 12)),
                ),
            ],
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'shop_management_tab.dart';
import '../controllers/admin_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/models/user_model.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<AdminController>().fetchStats();
        context.read<AdminController>().fetchReports();
        context.read<AdminController>().fetchShopDiscounts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String title = '관리자 홈';
    if (_currentIndex == 1) title = '유저 관리';
    if (_currentIndex == 2) title = '신고 관리';
    if (_currentIndex == 3) title = '상점 관리';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: _currentIndex == 0
          ? const AdminHomeTab()
          : _currentIndex == 1
              ? const UserListTab()
              : _currentIndex == 2
                  ? const ReportListTab()
                  : const ShopManagementTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: '유저'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: '신고'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: '상점'),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    AppDialog.show(
      context: context,
      key: AppDialogKey.logout,
      actions: [
        AppDialogAction(
          label: '취소',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: '로그아웃',
          isPrimary: true,
          onPressed: () {
            Navigator.pop(context); // Close dialog
            context.read<AuthController>().signOut();
            // AuthController listener usually handles redirect to login
          },
        ),
      ],
    );
  }
}

class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchStats();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  kBottomNavigationBarHeight -
                  MediaQuery.of(context).padding.top,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatCard(
                      title: '오늘 접속자 수',
                      value: '${controller.dailyVisitorCount}명',
                      icon: Icons.person,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    _buildStatCard(
                      title: '총 가입자 수',
                      value: '${controller.totalUserCount}명',
                      icon: Icons.group,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              await controller.updateQuestionTranslations();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('질문 번역이 업데이트되었습니다.')),
                                );
                              }
                            },
                      icon: const Icon(Icons.translate),
                      label: const Text('모든 질문 번역하기 (Firebase)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              await controller.syncAllFriendData();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          '모든 기존 유저 친구 동기화 방안 조치가 완료되었습니다.')),
                                );
                              }
                            },
                      icon: const Icon(Icons.sync),
                      label: const Text('기존 유저 친구 캐시 동기화'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              await controller.migrateAssetsToFirestore();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Firebase 로컬 에셋 마이그레이션 (DB 업로드) 완료!')),
                                );
                              }
                            },
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('초기 소품들을 Firebase로 업로드(마이그레이션)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class UserListTab extends StatefulWidget {
  const UserListTab({super.key});

  @override
  State<UserListTab> createState() => _UserListTabState();
}

class _UserListTabState extends State<UserListTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => context.read<AdminController>().fetchUsers(isRefresh: true));

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<AdminController>().fetchUsers();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (value) {
                  controller.fetchUsers(isRefresh: true, searchQuery: value);
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.fetchUsers(
                    isRefresh: true, searchQuery: _searchController.text),
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length + (controller.hasMoreUsers ? 1 : 0),
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    if (index == users.length) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ));
                    }

                    final user = users[index];
                    final isSuspended = user.suspendedUntil != null &&
                        user.suspendedUntil!.isAfter(DateTime.now());

                    return ListTile(
                      title: Text(user.nickname),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('이메일: ${user.email}'),
                          Text('가입경로: ${user.loginProviderLabel}'),
                          Row(
                            children: [
                              const Text('보유 가지: '),
                              Text(
                                '${user.points}개',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    _showEditPointsDialog(context, user),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showLocalDiaryRecoveryDialog(context, user),
                              icon: const Icon(Icons.restore, size: 16),
                              label: const Text('유실된 로컬 일기 스캔 / 복구',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          if (isSuspended) ...[
                            Text('정지상태: ${_formatDate(user.suspendedUntil)} 까지',
                                style: const TextStyle(color: Colors.red)),
                            Text('사유: ${user.suspensionReason ?? "없음"}',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12)),
                          ],
                        ],
                      ),
                      trailing: isSuspended
                          ? ElevatedButton(
                              onPressed: () => _confirmUnsuspend(context, user),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue),
                              child: const Text('정지 해제',
                                  style: TextStyle(color: Colors.white)),
                            )
                          : null,
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

  void _showEditPointsDialog(BuildContext context, UserModel user) {
    final pointsController =
        TextEditingController(text: user.points.toString());

    AppDialog.show(
      context: context,
      key: AppDialogKey.editPoints,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${user.nickname}님의 가지 수량을 수정합니다.'),
          const SizedBox(height: 16),
          TextField(
            controller: pointsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '수정할 가지 갯수',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        AppDialogAction(
          label: '취소',
          onPressed: () => Navigator.pop(context),
        ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('${user.nickname}님의 가지가 $newPoints개로 수정되었습니다.')),
              );
            }
          },
        ),
      ],
    );
  }

  void _showLocalDiaryRecoveryDialog(BuildContext context, UserModel user) {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            final controller = context.read<AdminController>();

            return AlertDialog(
              title: Text('${user.nickname}님의 로컬 기기 일기 스캔'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: FutureBuilder<List<String>>(
                  future: controller.scanLocalDiaries(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('오류 발생: ${snapshot.error}'));
                    }

                    final availableDates = snapshot.data ?? [];
                    if (availableDates.isEmpty) {
                      return const Center(
                        child: Text(
                          '현재 기기에 이 사용자의 로컬 암호화 일기 파일이 없습니다.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: availableDates.length,
                      itemBuilder: (context, index) {
                        final dateStr = availableDates[index];
                        return ListTile(
                          title: Text(dateStr),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              final success = await controller
                                  .recoverLocalDiary(user.uid, dateStr);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? '$dateStr 일기 서버 백업/복구 성공!'
                                        : '복구 실패.'),
                                  ),
                                );
                              }
                            },
                            child: const Text('복구 (덮어쓰기)'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            );
          });
        });
  }

  void _confirmUnsuspend(BuildContext context, UserModel user) {
    AppDialog.show(
      context: context,
      key: AppDialogKey.unsuspend,
      content: Text('${user.nickname}님의 이용 정지를 해제하시겠습니까?'),
      actions: [
        AppDialogAction(
          label: '취소',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: '해제',
          isPrimary: true,
          onPressed: () {
            Navigator.pop(context);
            context.read<AdminController>().unsuspendUser(user.uid);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${user.nickname}님의 정지가 해제되었습니다.')),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }
}

class ReportListTab extends StatelessWidget {
  const ReportListTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = controller.reports;
        if (reports.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              await controller.fetchReports();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    AppBar().preferredSize.height -
                    kBottomNavigationBarHeight -
                    MediaQuery.of(context).padding.top,
                child: const Center(child: Text('신고 내역이 없습니다.')),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchReports();
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(context, controller, report);
            },
          ),
        );
      },
    );
  }

  Widget _buildReportCard(BuildContext context, AdminController controller,
      Map<String, dynamic> report) {
    final status = report['status'];
    final isPending = status == 'pending';
    final createdAt = report['createdAt'];
    String dateStr = '';
    if (createdAt is DateTime) {
      dateStr = DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
    } else {
      dateStr = createdAt.toString();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '상태: $status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPending ? Colors.red : Colors.grey,
                  ),
                ),
                Text(dateStr),
              ],
            ),
            const SizedBox(height: 8),
            Text('신고자: ${report['reporterName']}'),
            Text('작성자: ${report['targetUserName']}'),
            const SizedBox(height: 8),
            Text('신고 사유: ${report['reason']}'),
            const SizedBox(height: 8),
            const Text('내용:', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              color: Colors.grey[200],
              child: Text(report['targetContent'] ?? ''),
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        _showRejectDialog(context, controller, report),
                    child: const Text('반려'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () =>
                        _showSuspendDialog(context, controller, report),
                    child:
                        const Text('정지', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
            if (status == 'rejected')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('반려 사유: ${report['rejectReason'] ?? ''}',
                    style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, AdminController controller,
      Map<String, dynamic> report) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('신고 반려'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: '반려 사유를 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                controller.rejectReport(
                  report['id'],
                  report['reporterId'],
                  reasonController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showSuspendDialog(BuildContext context, AdminController controller,
      Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('사용자 정지 기간 선택'),
        children: [
          _suspendSimpleAction(context, controller, report, '1일 정지', 1),
          _suspendSimpleAction(context, controller, report, '3일 정지', 3),
          _suspendSimpleAction(context, controller, report, '5일 정지', 5),
          _suspendSimpleAction(context, controller, report, '7일 정지', 7),
          _suspendSimpleAction(context, controller, report, '한달 정지', 30),
          _suspendSimpleAction(context, controller, report, '영구 정지', -1),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suspendSimpleAction(BuildContext context, AdminController controller,
      Map<String, dynamic> report, String label, int days) {
    return SimpleDialogOption(
      onPressed: () {
        controller.suspendUser(
          reportId: report['id'],
          targetUserId: report['targetUserId'],
          reporterId: report['reporterId'],
          days: days,
        );
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: days == -1 ? Colors.red : Colors.blue[800],
            fontWeight: days == -1 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

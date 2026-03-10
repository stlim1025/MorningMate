import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/admin_controller.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘의 활동 요약',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard(
                        context,
                        controller,
                        '신규 가입자',
                        '${controller.todayNewUserCount}명',
                        Icons.person_add,
                        Colors.blue,
                        onTap: () => _showUsersDialog(context,
                            controller.getTodayNewUsers(), '오늘 신규 가입자')),
                    _buildStatCard(
                        context,
                        controller,
                        '오늘 접속자',
                        '${controller.dailyVisitorCount}명',
                        Icons.login,
                        Colors.green,
                        onTap: () => _showUsersDialog(context,
                            controller.getTodayLoginUsers(), '오늘 접속한 유저')),
                    _buildStatCard(
                        context,
                        controller,
                        '오늘 생성된 일기',
                        '${controller.todayDiaryCount}개',
                        Icons.book,
                        Colors.orange,
                        onTap: () => _showDiariesDialog(context,
                            controller.getTodayDiaries(), '오늘 작성된 일기')),
                    _buildStatCard(
                        context,
                        controller,
                        '오늘 광고 시청',
                        '${controller.todayAdViewerCount}명',
                        Icons.play_circle_fill,
                        Colors.redAccent,
                        onTap: () => _showUsersDialog(context,
                            controller.getTodayAdViewerUsers(), '오늘 광고 시청자')),
                    _buildStatCard(
                        context,
                        controller,
                        '총 가입자',
                        '${controller.totalUserCount}명',
                        Icons.groups,
                        Colors.purple,
                        onTap: null),
                  ],
                ),
                const SizedBox(height: 48),
                // 시간대별 접속자 수 삭제됨 (읽기 최적화)
                const SizedBox(height: 48),
                const Text('시스템 관리 기능',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              await controller.updateQuestionTranslations();
                            },
                      icon: const Icon(Icons.translate),
                      label: const Text('질문 번역/동기화 실행'),
                    ),
                    ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              await controller.syncAllFriendData();
                            },
                      icon: const Icon(Icons.sync),
                      label: const Text('친구 캐시 동기화'),
                    ),
                    ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              await controller.syncShopAssets();
                            },
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('초기 소품 Firebase 마이그레이션'),
                    ),
                    ElevatedButton.icon(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              await controller.assignReferralCodesToOldUsers();
                            },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                      icon: const Icon(Icons.code),
                      label: const Text('기존 유저 추천인 코드 부여'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, AdminController controller,
      String title, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            if (onTap != null) ...[
              const SizedBox(height: 8),
              const Text('상세 보기',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline)),
            ]
          ],
        ),
      ),
    );
  }

  void _showUsersDialog(
      BuildContext context, Future<List<dynamic>> futureUsers, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.analytics_outlined, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 600,
          child: FutureBuilder<List<dynamic>>(
            future: futureUsers,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return const Center(child: Text('데이터가 없습니다.'));
              }

              return Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                            flex: 2,
                            child: Text('닉네임',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 3,
                            child: Text('이메일',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 1,
                            child: Text('가입경로',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 2,
                            child: Text('발생 시간',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        String timeStr = '-';
                        if (title.contains('접속')) {
                          timeStr = user.lastLoginDate != null
                              ? DateFormat('HH:mm:ss')
                                  .format(user.lastLoginDate!)
                              : '-';
                        } else if (title.contains('광고')) {
                          timeStr = user.lastAdRewardDate != null
                              ? DateFormat('HH:mm:ss')
                                  .format(user.lastAdRewardDate!)
                              : '-';
                        } else if (title.contains('신규')) {
                          timeStr = DateFormat('yy/MM/dd HH:mm')
                              .format(user.createdAt);
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(user.nickname,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(user.email,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 13)),
                              ),
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(user.loginProviderLabel,
                                        style: TextStyle(
                                            color: Colors.blue[700],
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(timeStr,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontFamily: 'monospace', fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showDiariesDialog(BuildContext context,
      Future<List<Map<String, dynamic>>> futureDiaries, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.book_outlined, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 600,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: futureDiaries,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final diaries = snapshot.data ?? [];
              if (diaries.isEmpty) {
                return const Center(child: Text('작성된 일기가 없습니다.'));
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                            flex: 2,
                            child: Text('작성자',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 3,
                            child: Text('UID',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 1,
                            child: Text('글자수',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 2,
                            child: Text('작성시간',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: diaries.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final d = diaries[index];
                        final createdAt = d['createdAt'] is Timestamp
                            ? (d['createdAt'] as Timestamp).toDate()
                            : DateTime.now();
                        final timeStr =
                            DateFormat('HH:mm:ss').format(createdAt);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(d['nickname'] ?? '알 수 없음',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(d['userId'] ?? '-',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                        fontFamily: 'monospace')),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text('${d['wordCount'] ?? 0}자',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(timeStr,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontFamily: 'monospace', fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

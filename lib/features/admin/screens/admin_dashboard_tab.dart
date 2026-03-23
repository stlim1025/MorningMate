import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/admin_controller.dart';
import '../widgets/admin_dialog.dart';
import '../widgets/admin_date_picker.dart';
import '../../../utils/country_utils.dart';

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
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 섹션 1: 서비스 전체 현황 ──
                _buildSectionHeader(
                  '서비스 전체 현황',
                  subtitle: '전체 누적 데이터입니다.',
                  icon: Icons.bar_chart_rounded,
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 48) / 3;
                    return Row(
                      children: [
                        _buildOverviewCard(
                          width: cardWidth < 200 ? 200 : cardWidth,
                          title: '총 가입자',
                          value: '${controller.totalUserCount}',
                          unit: '명',
                          icon: Icons.groups_rounded,
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 24),
                        _buildOverviewCard(
                          width: cardWidth < 200 ? 200 : cardWidth,
                          title: '플랫폼 현황',
                          value: '',
                          valueWidget: Row(
                            children: [
                              Icon(Icons.android_rounded,
                                  size: 18, color: Colors.green[600]),
                              const SizedBox(width: 4),
                              Text('${controller.androidUserCount}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B))),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('/',
                                    style: TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 14)),
                              ),
                              const Icon(Icons.apple_rounded,
                                  size: 18, color: Color(0xFF1E293B)),
                              const SizedBox(width: 4),
                              Text('${controller.iosUserCount}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E293B))),
                            ],
                          ),
                          icon: Icons.phonelink_setup_rounded,
                          color: const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 24),
                        _buildOverviewCard(
                          width: cardWidth < 200 ? 200 : cardWidth,
                          title: '접속 국가',
                          value: '${controller.countryStats.length}',
                          unit: '개국',
                          icon: Icons.public_rounded,
                          color: const Color(0xFF0EA5E9),
                          onTap: () => _showCountryStatsDialog(
                              context, controller.countryStats),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 48),

                // ── 섹션 2: 일별 활동 지표 ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildSectionHeader(
                      '일별 활동 지표',
                      subtitle: '선택한 날짜의 실시간 데이터입니다.',
                      icon: Icons.calendar_today_rounded,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            final prevDate = controller.selectedDate.subtract(const Duration(days: 1));
                            controller.setSelectedDate(prevDate);
                          },
                          icon: const Icon(Icons.chevron_left_rounded),
                          tooltip: '이전날',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6366F1),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildDatePicker(context, controller),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            final nextDate = controller.selectedDate.add(const Duration(days: 1));
                            controller.setSelectedDate(nextDate);
                          },
                          icon: const Icon(Icons.chevron_right_rounded),
                          tooltip: '다음날',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6366F1),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => controller.fetchStats(),
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: '데이터 새로고침',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6366F1),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.all(10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth =
                        (constraints.maxWidth - 96) / 5; // 5 cards
                    return Row(
                      children: [
                        _buildDailyMetricCard(
                          context: context,
                          width: cardWidth < 140 ? 140 : cardWidth,
                          title: '신규 가입자',
                          value: controller.todayNewUserCount,
                          unit: '명',
                          icon: Icons.person_add_alt_1_rounded,
                          color: const Color(0xFF3B82F6),
                          onTap: () => _showUsersDialog(context,
                              controller.getTodayNewUsers(), '신규 가입자 (${DateFormat('MM/dd').format(controller.selectedDate)})'),
                        ),
                        const SizedBox(width: 24),
                        _buildDailyMetricCard(
                          context: context,
                          width: cardWidth < 140 ? 140 : cardWidth,
                          title: '일일 접속자',
                          value: controller.dailyVisitorCount,
                          unit: '명',
                          icon: Icons.login_rounded,
                          color: const Color(0xFF10B981),
                          onTap: () => _showUsersDialog(context,
                              controller.getTodayLoginUsers(), '접속 유저 (${DateFormat('MM/dd').format(controller.selectedDate)})'),
                        ),
                        const SizedBox(width: 24),
                        _buildDailyMetricCard(
                          context: context,
                          width: cardWidth < 140 ? 140 : cardWidth,
                          title: '일기 작성',
                          value: controller.todayDiaryCount,
                          unit: '개',
                          icon: Icons.auto_stories_rounded,
                          color: const Color(0xFFF59E0B),
                          onTap: () => _showDiariesDialog(context,
                              controller.getTodayDiaries(), '작성된 일기 (${DateFormat('MM/dd').format(controller.selectedDate)})'),
                        ),
                        const SizedBox(width: 24),
                        _buildDailyMetricCard(
                          context: context,
                          width: cardWidth < 140 ? 140 : cardWidth,
                          title: '광고 인원',
                          value: controller.todayAdViewerCount,
                          unit: '명',
                          icon: Icons.group_outlined,
                          color: const Color(0xFFEF4444),
                          onTap: () => _showUsersDialog(
                              context,
                              controller.getTodayAdViewerUsers(),
                              '광고 시청자 (${DateFormat('MM/dd').format(controller.selectedDate)})'),
                        ),
                        const SizedBox(width: 24),
                        _buildDailyMetricCard(
                          context: context,
                          width: cardWidth < 140 ? 140 : cardWidth,
                          title: '광고 횟수',
                          value: controller.todayAdImpressionCount,
                          unit: '회',
                          icon: Icons.play_circle_rounded,
                          color: const Color(0xFFFF4D00),
                          onTap: () => _showAdImpressionsDialog(
                              context,
                              controller.getTodayAdImpressions(),
                              '광고 시청 횟수 및 인원 (${DateFormat('MM/dd').format(controller.selectedDate)})'),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 48),

                // ── 섹션 3: 시스템 관리 ──
                _buildSectionHeader(
                  '시스템 관리',
                  subtitle: '데이터 동기화 및 마이그레이션 작업',
                  icon: Icons.settings_rounded,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildSystemButton(
                        label: '질문 번역/동기화',
                        icon: Icons.translate_rounded,
                        isLoading: controller.isLoading,
                        onPressed: () =>
                            controller.updateQuestionTranslations(),
                      ),
                      _buildSystemButton(
                        label: '친구 캐시 동기화',
                        icon: Icons.sync_rounded,
                        isLoading: controller.isLoading,
                        onPressed: () => controller.syncAllFriendData(),
                      ),
                      _buildSystemButton(
                        label: '초기 소품 마이그레이션',
                        icon: Icons.cloud_upload_rounded,
                        isLoading: controller.isLoading,
                        onPressed: () => controller.syncShopAssets(),
                      ),
                      _buildSystemButton(
                        label: '일본어 데이터 추가',
                        icon: Icons.translate_rounded,
                        isLoading: controller.isLoading,
                        onPressed: () => controller.updateJapaneseAssetNames(),
                        color: const Color(0xFF10B981),
                      ),
                      _buildSystemButton(
                        label: '추천인 코드 부여',
                        icon: Icons.code_rounded,
                        isLoading: controller.isLoading,
                        onPressed: () =>
                            controller.assignReferralCodesToOldUsers(),
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── UI Building Blocks ──

  Widget _buildSectionHeader(String title,
      {String? subtitle, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: const Color(0xFF475569)),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ],
    );
  }

  Widget _buildOverviewCard({
    required double width,
    required String title,
    required String value,
    Widget? valueWidget,
    String? unit,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (valueWidget != null)
                      valueWidget
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (unit != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              unit,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyMetricCard({
    required BuildContext context,
    required double width,
    required String title,
    required int value,
    required String unit,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (onTap != null)
                    Icon(Icons.open_in_new_rounded,
                        size: 16, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final btnColor = color ?? const Color(0xFF6366F1);
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: Icon(icon, size: 16, color: btnColor),
      label: Text(label,
          style: TextStyle(
              color: btnColor, fontSize: 13, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: btnColor.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, AdminController controller) {
    return AdminDatePicker(
      selectedDate: controller.selectedDate,
      onDateSelected: (date) => controller.setSelectedDate(date),
    );
  }

  // ── Dialogs (기존 로직 유지) ──

  void _showUsersDialog(
      BuildContext context, Future<List<dynamic>> futureUsers, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AdminWebDialog(
        title: title,
        titleIcon: Icons.analytics_outlined,
        width: 800,
        content: FutureBuilder<List<dynamic>>(
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
                _buildTableHeader(
                  columns: [
                    _col('닉네임', 2),
                    _col('이메일', 3),
                    _col('가입경로', 1),
                    _col('국가/OS', 1),
                    _col('발생 시간', 2),
                  ],
                ),
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
                                child: _buildBadge(
                                    user.loginProviderLabel, Colors.blue),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Tooltip(
                                    message: CountryUtils.getCountryNameKo(user.countryCode),
                                    child: Text(
                                      CountryUtils.getFlagEmoji(user.countryCode),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    user.platform == 'ios'
                                        ? Icons.apple
                                        : (user.platform == 'android'
                                            ? Icons.android
                                            : Icons.device_unknown),
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ],
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
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('닫기'),
          )
        ],
      ),
    );
  }

  void _showAdImpressionsDialog(BuildContext context,
      Future<List<Map<String, dynamic>>> futureImpressions, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AdminWebDialog(
        title: title,
        titleIcon: Icons.play_circle_outline,
        width: 800,
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: futureImpressions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final impressions = snapshot.data ?? [];
            if (impressions.isEmpty) {
              return const Center(child: Text('데이터가 없습니다.'));
            }

            return Column(
              children: [
                _buildTableHeader(
                  columns: [
                    _col('닉네임', 2),
                    _col('이메일', 3),
                    _col('시청 횟수', 1),
                    _col('국가/OS', 1),
                    _col('최근 시청 시간', 2),
                  ],
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: impressions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = impressions[index];
                      final user = item['user'] as dynamic; // UserModel
                      final count = item['count'] as int;
                      final lastTime = item['lastViewTime'] as DateTime;
                      final timeStr = DateFormat('HH:mm:ss').format(lastTime);

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
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.orange.withOpacity(0.3)),
                                  ),
                                  child: Text('$count회',
                                      style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Tooltip(
                                    message: CountryUtils.getCountryNameKo(
                                        user.countryCode),
                                    child: Text(
                                      CountryUtils.getFlagEmoji(
                                          user.countryCode),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    user.platform == 'ios'
                                        ? Icons.apple
                                        : (user.platform == 'android'
                                            ? Icons.android
                                            : Icons.device_unknown),
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ],
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
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('닫기'),
          )
        ],
      ),
    );
  }

  void _showDiariesDialog(BuildContext context,
      Future<List<Map<String, dynamic>>> futureDiaries, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AdminWebDialog(
        title: title,
        titleIcon: Icons.book_outlined,
        width: 800,
        content: FutureBuilder<List<Map<String, dynamic>>>(
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
                _buildTableHeader(
                  columns: [
                    _col('작성자', 2),
                    _col('UID', 3),
                    _col('글자수', 1),
                    _col('OS', 1),
                    _col('작성시간', 2),
                  ],
                ),
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
                      final timeStr = DateFormat('HH:mm:ss').format(createdAt);

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
                              flex: 1,
                              child: Center(
                                child: Icon(
                                  d['platform'] == 'ios'
                                      ? Icons.apple
                                      : (d['platform'] == 'android'
                                          ? Icons.android
                                          : Icons.device_unknown),
                                  size: 16,
                                  color: Colors.grey[600],
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
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('닫기'),
          )
        ],
      ),
    );
  }

  void _showCountryStatsDialog(BuildContext context, Map<String, int> stats) {
    final sortedEntries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sortedEntries.fold<int>(0, (currentSum, e) => currentSum + e.value);

    showDialog(
      context: context,
      builder: (ctx) => AdminWebDialog(
        title: '국가별 접속 분포',
        titleIcon: Icons.public,
        width: 450,
        content: sortedEntries.isEmpty
            ? const Center(child: Text('접속 데이터가 없습니다.'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sortedEntries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final e = sortedEntries[index];
                  final pct =
                      total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Text('${index + 1}',
                            style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Text(CountryUtils.getFlagEmoji(e.key), style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(CountryUtils.getCountryNameKo(e.key),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 14)),
                              ),
                            ]
                          ),
                        ),
                        Text('$pct%',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(width: 16),
                        Text('${e.value}명',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  );
                },
              ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          )
        ],
      ),
    );
  }

  // ── Table Helpers ──

  Widget _buildTableHeader(
      {required List<Widget> columns, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFF1F5F9),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(children: columns),
    );
  }

  Widget _col(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color(0xFF64748B),
          )),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
    );
  }
}

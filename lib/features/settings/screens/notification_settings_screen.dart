import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../services/user_service.dart';
import '../../../core/widgets/memo_notification.dart';
import '../../../core/localization/app_localizations.dart';

// ─────────────────────────────────────────────
// 커스텀 시간 선택 팝업 (종이 카드 스타일)
// ─────────────────────────────────────────────
class _TimePickerPopup extends StatefulWidget {
  final String initialTime; // "HH:mm" 24h 포맷

  const _TimePickerPopup({required this.initialTime});

  @override
  State<_TimePickerPopup> createState() => _TimePickerPopupState();
}

class _TimePickerPopupState extends State<_TimePickerPopup>
    with SingleTickerProviderStateMixin {
  late int _hour12; // 1~12
  late int _minute; // 0~59
  late bool _isAm;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    final parts = widget.initialTime.split(':');
    final h24 = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    _isAm = h24 < 12;
    _hour12 = h24 % 12 == 0 ? 12 : h24 % 12;
    _minute = m;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get _hour24 {
    if (_isAm) {
      return _hour12 == 12 ? 0 : _hour12;
    } else {
      return _hour12 == 12 ? 12 : _hour12 + 12;
    }
  }

  String get _formattedTime =>
      '${_hour24.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── 배경 종이 카드 ──
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/Popup_Background.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 44, 24, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── 타이틀 ──
                        Text(
                          AppLocalizations.of(context)
                                  ?.get('notificationTime') ??
                              '알림 시간 설정',
                          style: const TextStyle(
                            fontFamily: 'BMJUA',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4E342E),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── 시간 디스플레이 ──
                        _buildTimeDisplay(),
                        const SizedBox(height: 20),

                        // ── AM / PM 토글 ──
                        _buildAmPmToggle(),
                        const SizedBox(height: 24),

                        // ── 시 스와이퍼 ──
                        _NumberSwiper(
                          label: AppLocalizations.of(context)
                                  ?.get('timePickerHour') ??
                              '시',
                          value: _hour12,
                          min: 1,
                          max: 12,
                          onChanged: (v) => setState(() => _hour12 = v),
                        ),
                        const SizedBox(height: 12),

                        // ── 분 스와이퍼 ──
                        _NumberSwiper(
                          label: AppLocalizations.of(context)
                                  ?.get('timePickerMinute') ??
                              '분',
                          value: _minute,
                          min: 0,
                          max: 59,
                          onChanged: (v) => setState(() => _minute = v),
                        ),
                        const SizedBox(height: 28),

                        // ── 버튼 ──
                        Row(
                          children: [
                            Expanded(
                              child: _ActionBtn(
                                imagePath: 'assets/images/Cancel_Button.png',
                                label: AppLocalizations.of(context)
                                        ?.get('cancel') ??
                                    '취소',
                                onTap: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionBtn(
                                imagePath: 'assets/images/Confirm_Button.png',
                                label: AppLocalizations.of(context)
                                        ?.get('confirm') ??
                                    '확인',
                                onTap: () =>
                                    Navigator.pop(context, _formattedTime),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 마스킹테이프 스티커 ──
            Positioned(
              top: -25,
              left: -10,
              child: Image.asset(
                'assets/images/Popup_Sticker.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay() {
    final hourStr = _hour12.toString().padLeft(2, '0');
    final minStr = _minute.toString().padLeft(2, '0');
    return Stack(
      alignment: Alignment.center,
      children: [
        // AddFriend_Button.png 배경
        Image.asset(
          'assets/icons/AddFriend_Button.png',
          fit: BoxFit.fill,
          width: double.infinity,
          height: 72,
        ),
        // 시간 텍스트 — 아래로 살짝 내림
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeBox(value: hourStr),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontFamily: 'BMJUA',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4E342E),
                  ),
                ),
              ),
              _TimeBox(value: minStr),
              const SizedBox(width: 12),
              Text(
                _isAm ? 'AM' : 'PM',
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8D6E63),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmPmToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ToggleBtn(
          label: 'AM',
          selected: _isAm,
          onTap: () => setState(() => _isAm = true),
        ),
        const SizedBox(width: 8),
        _ToggleBtn(
          label: 'PM',
          selected: !_isAm,
          onTap: () => setState(() => _isAm = false),
        ),
      ],
    );
  }
}

// ── 드럼롤 숫자 선택 위젯 ──
// 중앙: 선택된 숫자 (크고 선명), 좌우: 이전/다음 숫자 (작고 흐릿)
class _NumberSwiper extends StatefulWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberSwiper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_NumberSwiper> createState() => _NumberSwiperState();
}

class _NumberSwiperState extends State<_NumberSwiper> {
  late PageController _pageCtrl;

  // 순환을 위해 큰 가상 페이지 수 사용
  static const int _virtualCount = 10000;

  int get _range => widget.max - widget.min + 1;

  // 가상 인덱스 → 실제 값
  int _valueAt(int virtualIndex) => widget.min + (virtualIndex % _range);

  // 실제 값 → 초기 가상 인덱스 (중앙 근처)
  int _initialPage() =>
      (_virtualCount ~/ 2) -
      ((_virtualCount ~/ 2) % _range) +
      (widget.value - widget.min);

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(
      initialPage: _initialPage(),
      viewportFraction: 0.33, // 한 화면에 3개 표시
    );
  }

  @override
  void didUpdateWidget(_NumberSwiper old) {
    super.didUpdateWidget(old);
    // 부모에서 값이 바뀌면 PageView 동기화
    if (old.value != widget.value) {
      final currentPage = _pageCtrl.page?.round() ?? _initialPage();
      final currentVal = _valueAt(currentPage);
      if (currentVal != widget.value) {
        final diff = widget.value - currentVal;
        _pageCtrl.animateToPage(
          currentPage + diff,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 레이블 (시 / 분)
        SizedBox(
          width: 28,
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'BMJUA',
              fontSize: 15,
              color: Color(0xFF4E342E),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 드럼롤 영역
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // TextBox_Background 배경
              Image.asset(
                'assets/images/TextBox_Background.png',
                fit: BoxFit.fill,
                width: double.infinity,
                height: 56,
              ),

              // PageView 숫자 롤러
              SizedBox(
                height: 56,
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: _virtualCount,
                  onPageChanged: (idx) {
                    widget.onChanged(_valueAt(idx));
                  },
                  itemBuilder: (context, idx) {
                    final val = _valueAt(idx);
                    final isSelected = val == widget.value;
                    return Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        style: TextStyle(
                          fontFamily: 'BMJUA',
                          fontSize: isSelected ? 24 : 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF4E342E)
                              : const Color(0xFF4E342E).withOpacity(0.28),
                        ),
                        child: Text(
                          val.toString().padLeft(2, '0'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 시간 숫자 박스 ──
class _TimeBox extends StatelessWidget {
  final String value;
  const _TimeBox({required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        fontFamily: 'BMJUA',
        fontSize: 42,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4E342E),
        letterSpacing: 2,
      ),
    );
  }
}

// ── AM/PM 탭 버튼 (이미지 기반) ──
class _ToggleBtn extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ToggleBtn> createState() => _ToggleBtnState();
}

class _ToggleBtnState extends State<_ToggleBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // 선택 중: ShopTab_ButtonClick.png / 미선택: ShopTab_Button.png
    final imagePath = widget.selected
        ? 'assets/images/ShopTab_ButtonClick.png'
        : 'assets/images/ShopTab_Button.png';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Transform.scale(
        scale: _pressed ? 0.95 : 1.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.fill,
              width: 80,
              height: 40,
            ),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'BMJUA',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: widget.selected
                    ? const Color(0xFF4E342E)
                    : const Color(0xFF8D6E63),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 이미지 액션 버튼 ──
class _ActionBtn extends StatefulWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Transform.scale(
        scale: _pressed ? 0.95 : 1.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              widget.imagePath,
              fit: BoxFit.fill,
              width: double.infinity,
              height: 52,
            ),
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'BMJUA',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4E342E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 알림 설정 화면
// ─────────────────────────────────────────────
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Image.asset(
              'assets/icons/X_Button.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)?.get('notificationSettings') ??
              'Notification Settings',
          style: TextStyle(
            color: colorScheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'BMJUA',
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/Diary_Background.png',
              fit: BoxFit.cover,
            ),
          ),
          Consumer<AuthController>(
            builder: (context, authController, child) {
              final user = authController.userModel;
              if (user == null) return const SizedBox.shrink();

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 60,
                  20,
                  20,
                ),
                children: [
                  _buildSectionTitle(
                      AppLocalizations.of(context)
                              ?.get('serviceNotification') ??
                          'Service Notifications',
                      colorScheme),
                  const SizedBox(height: 12),
                  _buildOptionArea(
                    context,
                    children: [
                      _buildNotiTile(
                        context,
                        AppLocalizations.of(context)?.get('morningDiaryNoti') ??
                            'Morning Diary Alert',
                        AppLocalizations.of(context)
                                ?.get('morningDiaryNotiDesc') ??
                            'Remind you to write diary every morning',
                        user.morningDiaryNoti,
                        (val) => _updateNoti(
                            context, authController, {'morningDiaryNoti': val}),
                        colorScheme,
                      ),
                      if (user.morningDiaryNoti) ...[
                        _buildDivider(colorScheme),
                        _buildTimeTile(
                          context,
                          AppLocalizations.of(context)
                                  ?.get('notificationTime') ??
                              'Notification Time',
                          user.morningDiaryNotiTime,
                          (time) => _updateNoti(context, authController,
                              {'morningDiaryNotiTime': time}),
                          colorScheme,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                      AppLocalizations.of(context)
                              ?.get('activityNotification') ??
                          'Activity Notifications',
                      colorScheme),
                  const SizedBox(height: 12),
                  _buildOptionArea(
                    context,
                    children: [
                      _buildNotiTile(
                        context,
                        AppLocalizations.of(context)?.get('wakeUpNoti') ??
                            'Wake Up Alert',
                        AppLocalizations.of(context)?.get('wakeUpNotiDesc') ??
                            'Get notified when a friend wakes you up',
                        user.wakeUpNoti,
                        (val) => _updateNoti(
                            context, authController, {'wakeUpNoti': val}),
                        colorScheme,
                      ),
                      _buildDivider(colorScheme),
                      _buildNotiTile(
                        context,
                        AppLocalizations.of(context)?.get('cheerMessageNoti') ??
                            'Cheer Message Alert',
                        AppLocalizations.of(context)
                                ?.get('cheerMessageNotiDesc') ??
                            'Get notified when a friend sends a cheer',
                        user.cheerMessageNoti,
                        (val) => _updateNoti(
                            context, authController, {'cheerMessageNoti': val}),
                        colorScheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                      AppLocalizations.of(context)?.get('friendNotification') ??
                          'Friend Notifications',
                      colorScheme),
                  const SizedBox(height: 12),
                  _buildOptionArea(
                    context,
                    children: [
                      _buildNotiTile(
                        context,
                        AppLocalizations.of(context)
                                ?.get('friendRequestNoti') ??
                            'Friend Request Alert',
                        AppLocalizations.of(context)
                                ?.get('friendRequestNotiDesc') ??
                            'Get notified of new friend requests',
                        user.friendRequestNoti,
                        (val) => _updateNoti(context, authController,
                            {'friendRequestNoti': val}),
                        colorScheme,
                      ),
                      _buildDivider(colorScheme),
                      _buildNotiTile(
                        context,
                        AppLocalizations.of(context)?.get('friendAcceptNoti') ??
                            'Friend Accept Alert',
                        AppLocalizations.of(context)
                                ?.get('friendAcceptNotiDesc') ??
                            'Get notified when your request is accepted',
                        user.friendAcceptNoti,
                        (val) => _updateNoti(
                            context, authController, {'friendAcceptNoti': val}),
                        colorScheme,
                      ),
                      _buildDivider(colorScheme),
                      _buildNotiTile(
                        context,
                        AppLocalizations.of(context)?.get('friendRejectNoti') ??
                            'Friend Reject Alert',
                        AppLocalizations.of(context)
                                ?.get('friendRejectNotiDesc') ??
                            'Get notified when your request is rejected',
                        user.friendRejectNoti,
                        (val) => _updateNoti(
                            context, authController, {'friendRejectNoti': val}),
                        colorScheme,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Transform.translate(
        offset: const Offset(-10, 0),
        child: Container(
          width: 140, // Increased from 120
          height: 42, // Increased from 32 to prevent clipping
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icons/Store_Tab.png'),
              fit: BoxFit.fill,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                45, 2, 16, 0), // Increased left padding from 20 to 32
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF4E342E),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'BMJUA',
                height: 1.1, // Adjusted line height
              ),
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotiTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    AppColorScheme colorScheme,
  ) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.textPrimary,
          fontSize: 16,
          fontFamily: 'BMJUA',
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            color: colorScheme.textSecondary,
            fontSize: 13,
            fontFamily: 'BMJUA',
          ),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: colorScheme.primaryButton,
    );
  }

  Widget _buildTimeTile(
    BuildContext context,
    String title,
    String time,
    Function(String) onTimeChanged,
    AppColorScheme colorScheme,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.textPrimary,
          fontSize: 16,
          fontFamily: 'BMJUA',
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primaryButton.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: colorScheme.primaryButton,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'BMJUA',
          ),
        ),
      ),
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          barrierDismissible: true,
          builder: (_) => _TimePickerPopup(initialTime: time),
        );
        if (result != null) {
          onTimeChanged(result);
        }
      },
    );
  }

  Widget _buildOptionArea(BuildContext context,
      {required List<Widget> children}) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Option_Area.png'),
          fit: BoxFit.fill,
        ),
      ),
      padding: const EdgeInsets.only(top: 32, bottom: 12),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider(AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 3.0;
          const dashHeight = 1.0;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E342E).withOpacity(0.2),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Future<void> _updateNoti(
    BuildContext context,
    AuthController authController,
    Map<String, dynamic> data,
  ) async {
    final userService = context.read<UserService>();
    final userId = authController.currentUser?.uid;
    if (userId == null) return;

    try {
      await userService.updateUser(userId, data);

      // 로컬 모델 업데이트
      final currentModel = authController.userModel!;
      authController.updateUserModel(
        currentModel.copyWith(
          morningDiaryNoti:
              data['morningDiaryNoti'] ?? currentModel.morningDiaryNoti,
          morningDiaryNotiTime:
              data['morningDiaryNotiTime'] ?? currentModel.morningDiaryNotiTime,
          wakeUpNoti: data['wakeUpNoti'] ?? currentModel.wakeUpNoti,
          cheerMessageNoti:
              data['cheerMessageNoti'] ?? currentModel.cheerMessageNoti,
          friendRequestNoti:
              data['friendRequestNoti'] ?? currentModel.friendRequestNoti,
          friendAcceptNoti:
              data['friendAcceptNoti'] ?? currentModel.friendAcceptNoti,
          friendRejectNoti:
              data['friendRejectNoti'] ?? currentModel.friendRejectNoti,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        MemoNotification.show(context,
            '${AppLocalizations.of(context)?.get('errorSavingSettings') ?? 'Error saving settings: '} ⚠️');
      }
    }
  }
}

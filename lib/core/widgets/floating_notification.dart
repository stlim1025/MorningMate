import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_color_scheme.dart';

class FloatingNotification extends StatefulWidget {
  final String title;
  final String? body;
  final String? type;
  final Map<String, dynamic>? data;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;
  final Duration duration;

  const FloatingNotification({
    super.key,
    required this.title,
    this.body,
    this.type,
    this.data,
    required this.onDismiss,
    this.onTap,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<FloatingNotification> createState() => _FloatingNotificationState();
}

class _FloatingNotificationState extends State<FloatingNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isDismissing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    _timer = Timer(widget.duration - const Duration(milliseconds: 500), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (_isDismissing || !mounted) return;
    setState(() {
      _isDismissing = true;
    });
    _timer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIcon(AppColorScheme colors) {
    // 둥지 관련 알림인지 확인
    final isNestNotification = widget.type == 'nestInvite' ||
        widget.type == 'nest_invite' ||
        widget.type == 'nestDonation' ||
        widget.type == 'nest_donation' ||
        (widget.data != null && widget.data!['nestId'] != null);

    if (isNestNotification) {
      return Image.asset(
        'assets/icons/Nest_Notification_Icon.png',
        width: 36,
        height: 36,
        fit: BoxFit.contain,
      );
    }

    return Icon(
      _getIconData(),
      color: _getIconColor(colors),
      size: 26,
    );
  }

  IconData _getIconData() {
    switch (widget.type) {
      case 'wake_up':
        return Icons.wb_sunny_rounded;
      case 'cheer_message':
        return Icons.favorite_rounded;
      case 'friend_request':
        return Icons.person_add_rounded;
      case 'friend_accept':
        return Icons.how_to_reg_rounded;
      case 'friend_reject':
        return Icons.person_remove_rounded;
      case 'character_evolved':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getIconColor(AppColorScheme colors) {
    switch (widget.type) {
      case 'wake_up':
        return colors.warning;
      case 'cheer_message':
        return colors.error;
      case 'friend_request':
      case 'friend_accept':
        return colors.success;
      case 'character_evolved':
        return colors.accent;
      default:
        return colors.primaryButton;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/images/TodaySpeak_TextBox.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (widget.onTap != null) {
                      widget.onTap!();
                    }
                    if (mounted) widget.onDismiss();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Enhanced Left Icon Part
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getIconColor(colorScheme).withOpacity(0.2),
                                _getIconColor(colorScheme).withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _buildIcon(colorScheme),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  color: colorScheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.body != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    widget.body!,
                                    style: TextStyle(
                                      color: colorScheme.textSecondary,
                                      fontSize: 13,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: colorScheme.textHint.withOpacity(0.5),
                            size: 20,
                          ),
                          onPressed: _dismiss,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

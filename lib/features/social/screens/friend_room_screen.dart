import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/user_service.dart';
import '../../../data/models/user_model.dart';
import '../../morning/widgets/enhanced_character_room_widget.dart';
import '../controllers/social_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notification/controllers/notification_controller.dart';

class FriendRoomScreen extends StatefulWidget {
  final String friendId;

  const FriendRoomScreen({
    super.key,
    required this.friendId,
  });

  @override
  State<FriendRoomScreen> createState() => _FriendRoomScreenState();
}

class _FriendRoomScreenState extends State<FriendRoomScreen> {
  UserModel? _friend;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendData();
  }

  Future<void> _loadFriendData() async {
    final userService = context.read<UserService>();

    try {
      final friend = await userService.getUser(widget.friendId);
      setState(() {
        _friend = friend;
        _isLoading = false;
      });
    } catch (e) {
      print('친구 데이터 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SocialController>(
        builder: (context, socialController, child) {
          final isAwake = _friend != null
              ? socialController.isFriendAwake(_friend!.uid)
              : false;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isAwake
                    ? [
                        const Color(0xFF87CEEB), // 하늘색
                        const Color(0xFFB0E0E6), // 파우더 블루
                        const Color(0xFFFFF8DC), // 코니실크
                      ]
                    : [
                        const Color(0xFF0F2027), // 어두운 밤
                        const Color(0xFF203A43),
                        const Color(0xFF2C5364),
                      ],
              ),
            ),
            child: SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _friend == null
                      ? _buildErrorState()
                      : _buildFriendRoom(isAwake),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          const Text(
            '친구를 찾을 수 없습니다',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRoom(bool isAwake) {
    return Column(
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back,
                    color: isAwake ? const Color(0xFF2C3E50) : Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_friend!.nickname}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: isAwake
                                ? const Color(0xFF2C3E50)
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_friend!.consecutiveDays}일 연속 기록 중 🔥',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isAwake
                                ? const Color(0xFF5A6C7D)
                                : Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 캐릭터 영역 (방 모양)
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: EnhancedCharacterRoomWidget(
                    isAwake: isAwake,
                    characterLevel: _friend!.characterLevel,
                    consecutiveDays: _friend!.consecutiveDays,
                  ),
                ),
                // 기존 스탯 위젯 제거 (메인 화면과 동일하게 맞춤)
              ],
            ),
          ),
        ),

        // 방명록 영역
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isAwake
                ? Colors.white.withOpacity(0.9)
                : Colors.black.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '친구에게 한마디',
                    style: TextStyle(
                      color:
                          isAwake ? AppColors.textPrimary : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.chat_bubble_outline,
                    color: isAwake
                        ? AppColors.textSecondary.withOpacity(0.6)
                        : Colors.white.withOpacity(0.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showGuestbookDialog(),
                  icon: const Icon(Icons.edit),
                  label: const Text('응원 메시지 남기기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showGuestbookDialog() async {
    final messageController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '응원 메시지',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: messageController,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '친구에게 응원의 메시지를 남겨주세요',
            hintStyle:
                TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0F0F0),
              foregroundColor: AppColors.textSecondary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final message = messageController.text.trim();
              if (message.isEmpty) return;

              Navigator.pop(context);

              final userModel = context.read<AuthController>().userModel;
              if (userModel != null) {
                final callable = FirebaseFunctions.instance
                    .httpsCallable('sendCheerMessage');
                try {
                  await callable.call({
                    'userId': userModel.uid,
                    'friendId': _friend!.uid,
                    'message': message,
                    'senderNickname': userModel.nickname,
                  });
                } catch (e) {
                  print('응원 메시지 FCM 전송 오류: $e');
                }

                await context.read<NotificationController>().sendCheerMessage(
                      userModel.uid,
                      userModel.nickname,
                      _friend!.uid,
                      message,
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('응원 메시지를 보냈습니다! 💌'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: AppColors.textPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '남기기',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

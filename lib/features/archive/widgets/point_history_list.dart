import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/point_history_service.dart';
import '../../../data/models/point_history_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/room_assets.dart';
import '../../../core/constants/character_assets.dart';
import '../../../core/widgets/network_or_asset_image.dart';

class PointHistoryList extends StatelessWidget {
  const PointHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final pointHistoryService = context.read<PointHistoryService>();
    final authController = context.read<AuthController>();
    final userId = authController.currentUser?.uid;

    if (userId == null) return const Center(child: Text('로그인이 필요합니다.'));

    return StreamBuilder<List<PointHistoryModel>>(
      stream: pointHistoryService.getUserHistoryStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('오류가 발생했습니다: ${snapshot.error}')),
          );
        }

        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text(
                AppLocalizations.of(context)?.get('noPointHistory') ??
                    '포인트 내역이 없습니다.',
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  color: Color(0xFF8D6E63),
                ),
              ),
            ),
          );
        }

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          width: double.infinity,
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: history.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.brown.withOpacity(0.1),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final item = history[index];
              return _buildHistoryItem(context, item);
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, PointHistoryModel item) {
    final isPositive = item.amount > 0;
    final amountText = isPositive ? '+${item.amount}' : '${item.amount}';
    final amountColor = isPositive ? Colors.green[700] : Colors.red[700];

    // 날짜 포맷팅
    final dateStr = DateFormat('MM.dd HH:mm').format(item.createdAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: _buildTypeIcon(context, item),
      title: Text(
        _getLocalizedDescription(context, item),
        style: const TextStyle(
          fontFamily: 'BMJUA',
          fontSize: 14,
          color: Color(0xFF4E342E),
        ),
      ),
      subtitle: Text(
        dateStr,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF8D6E63),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/branch.png',
            width: 16,
            height: 16,
            cacheWidth: 64,
          ),
          const SizedBox(width: 4),
          Text(
            amountText,
            style: TextStyle(
              fontFamily: 'BMJUA',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  RoomAsset? _getAssetById(String id) {
    // 테마, 배경, 벽지, 소품, 바닥, 창문 등 전체 검색
    final allRoomAssets = [
      ...RoomAssets.themes,
      ...RoomAssets.backgrounds,
      ...RoomAssets.wallpapers,
      ...RoomAssets.props,
      ...RoomAssets.floors,
      ...RoomAssets.windows,
      ...RoomAssets.emoticons,
      ...CharacterAssets.items,
    ];

    try {
      return allRoomAssets.firstWhere((asset) => asset.id == id);
    } catch (_) {
      return null;
    }
  }

  String _getLocalizedDescription(
      BuildContext context, PointHistoryModel item) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return item.description;

    String desc = item.description;

    // 1. 유형별 처리
    if (item.type == 'purchase' && desc.contains(': ')) {
      final parts = desc.split(': ');
      if (parts.length == 2) {
        String category = parts[0];
        String itemId = parts[1];

        String key = '';
        if (category.contains('테마'))
          key = 'historyPurchaseTheme';
        else if (category.contains('배경'))
          key = 'historyPurchaseBackground';
        else if (category.contains('벽지'))
          key = 'historyPurchaseWallpaper';
        else if (category.contains('소품'))
          key = 'historyPurchaseProp';
        else if (category.contains('이모티콘'))
          key = 'historyPurchaseEmoticon';
        else if (category.contains('바닥'))
          key = 'historyPurchaseFloor';
        else if (category.contains('창문'))
          key = 'historyPurchaseWindow';
        else if (category.contains('캐릭터 아이템'))
          key = 'historyPurchaseCharacterItem';

        String prefix = key.isNotEmpty ? localizations.get(key) : category;

        // RoomAssets에서 이름 가져오기 시도
        final asset = _getAssetById(itemId);
        String name = asset?.getLocalizedName(context) ??
            localizations.get('item_name_$itemId');

        return '$prefix: $name';
      }
    } else if (item.type == 'challenge' && desc.contains(': ')) {
      final parts = desc.split(': ');
      if (parts.length == 2) {
        String challengeId = parts[1];
        String prefix = localizations.get('historyChallengeReward');
        String title = localizations.get('challenge_${challengeId}_title');
        return '$prefix: $title';
      }
    } else if (item.type == 'diary') {
      return localizations.get('historyDiaryReward');
    } else if (item.type == 'ad') {
      return localizations.get('historyAdReward');
    } else if (item.type == 'sticky_note') {
      return localizations.get('historyStickyNote');
    } else if (item.type == 'donation' && desc.contains(': ')) {
      final parts = desc.split(': ');
      if (parts.length == 2) {
        String nestName = parts[1];
        String prefix = localizations.get('historyDonation');
        return '$prefix: $nestName';
      }
    } else if (item.type == 'reward') {
      if (desc.contains('오늘의 한마디')) {
        return localizations.get('historyNestReward');
      }
    }

    // 기본 번역 시도 (정확히 일치하는 경우)
    if (desc == '메모 작성') return localizations.get('historyStickyNote');
    if (desc == '광고 보상') return localizations.get('historyAdReward');
    if (desc == '오늘의 한마디 보상') return localizations.get('historyNestReward');

    return desc;
  }

  Widget _buildTypeIcon(BuildContext context, PointHistoryModel item) {
    IconData? iconData;
    Color iconColor = Colors.grey;
    String? imagePath;

    switch (item.type) {
      case 'diary':
        iconData = Icons.edit_note;
        iconColor = Colors.blue;
        break;
      case 'challenge':
        iconData = Icons.emoji_events;
        iconColor = Colors.orange;
        break;
      case 'ad':
        imagePath = 'assets/icons/Megaphone_Icon.png';
        iconColor = Colors.purple;
        break;
      case 'purchase':
        // 아이템 ID 추출 시도
        if (item.description.contains(': ')) {
          final itemId = item.description.split(': ').last;
          final asset = _getAssetById(itemId);
          if (asset != null && asset.imagePath != null) {
            imagePath = asset.imagePath;
          }
        }
        iconData = Icons.shopping_bag;
        iconColor = Colors.brown;
        break;
      case 'donation':
        iconData = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'reward':
        iconData = Icons.card_giftcard;
        iconColor = Colors.teal;
        break;
      case 'sticky_note':
        iconData = Icons.sticky_note_2;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.stars;
        iconColor = Colors.grey;
    }

    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: imagePath != null
          ? NetworkOrAssetImage(
              imagePath: imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                iconData ?? Icons.stars,
                size: 20,
                color: iconColor,
              ),
            )
          : Icon(
              iconData ?? Icons.stars,
              size: 20,
              color: iconColor,
            ),
    );
  }
}

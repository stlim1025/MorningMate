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

    if (userId == null) return Center(child: Text('로그인이 필요합니다.'));

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
                style: TextStyle(
                  fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
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
      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: _buildTypeIcon(context, item),
      title: Text(
        _getLocalizedDescription(context, item),
        style: TextStyle(
          fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
          fontSize: 14,
          color: Color(0xFF4E342E),
        ),
      ),
      subtitle: Text(
        dateStr,
        style: TextStyle(
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
          SizedBox(width: 4),
          Text(
            amountText,
            style: TextStyle(
              fontFamily: AppLocalizations.of(context)?.mainFontFamily ?? 'BMJUA',
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

    // 1. type 기반 처리 (언어 독립적)
    if (item.type == 'diary') {
      return localizations.get('historyDiaryReward');
    } else if (item.type == 'ad') {
      return localizations.get('historyAdReward');
    } else if (item.type == 'sticky_note') {
      return localizations.get('historyStickyNote');
    } else if (item.type == 'challenge' && desc.contains(': ')) {
      // description 형식: '도전과제 달성: {challengeId}'
      final colonIdx = desc.indexOf(': ');
      if (colonIdx != -1) {
        final challengeId = desc.substring(colonIdx + 2).trim();
        final prefix = localizations.get('historyChallengeReward');
        final title = localizations.get('challenge_${challengeId}_title');
        return '$prefix: $title';
      }
    } else if (item.type == 'donation' && desc.contains(': ')) {
      // description 형식: '둥지 기부: {nestName}'
      final colonIdx = desc.indexOf(': ');
      if (colonIdx != -1) {
        final nestName = desc.substring(colonIdx + 2).trim();
        final prefix = localizations.get('historyDonation');
        return '$prefix: $nestName';
      }
    } else if (item.type == 'reward') {
      // description에 한국어 키워드로 분기 (서버에 한국어로 저장되어 있음)
      if (desc.contains('오늘의 한마디') || desc == '오늘의 한마디 보상') {
        return localizations.get('historyNestReward');
      } else if (desc.contains('상점 튜토리얼') || desc == '상점 튜토리얼 완료 보상') {
        return localizations.get('historyShopTutorialReward');
      }
      // 기타 reward (레벨업 등)는 원본 표시
      return localizations.get('historyAdReward'); // fallback
    } else if (item.type == 'purchase' && desc.contains(': ')) {
      // description 형식: '{카테고리한국어} 구매: {itemId}'
      // ': ' 기준으로 마지막 부분이 아이템 ID
      final colonIdx = desc.indexOf(': ');
      if (colonIdx != -1) {
        final category = desc.substring(0, colonIdx).trim();
        final itemId = desc.substring(colonIdx + 2).trim();

        // 카테고리 한국어 → localization key 매핑
        String key = '';
        if (category.contains('테마')) {
          key = 'historyPurchaseTheme';
        } else if (category.contains('벽지')) {
          key = 'historyPurchaseWallpaper';
        } else if (category.contains('배경')) {
          key = 'historyPurchaseBackground';
        } else if (category.contains('이모티콘')) {
          key = 'historyPurchaseEmoticon';
        } else if (category.contains('소품')) {
          key = 'historyPurchaseProp';
        } else if (category.contains('바닥')) {
          key = 'historyPurchaseFloor';
        } else if (category.contains('창문')) {
          key = 'historyPurchaseWindow';
        } else if (category.contains('캐릭터 아이템')) {
          key = 'historyPurchaseCharacterItem';
        }

        final prefix = key.isNotEmpty ? localizations.get(key) : localizations.get('historyPurchaseProp');

        // 아이템 이름 번역 (RoomAssets → localization 순서로 시도)
        final asset = _getAssetById(itemId);
        final name = asset?.getLocalizedName(context) ??
            localizations.get('item_name_$itemId');

        return '$prefix: $name';
      }
    }

    // 기본 번역 시도 (정확히 일치하는 경우 - 이전 데이터 호환)
    if (desc == '메모 작성') return localizations.get('historyStickyNote');
    if (desc == '광고 보상') return localizations.get('historyAdReward');
    if (desc == '광고 시청 보상') return localizations.get('historyAdReward');
    if (desc == '오늘의 한마디 보상') return localizations.get('historyNestReward');
    if (desc == '상점 튜토리얼 완료 보상') return localizations.get('historyShopTutorialReward');

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

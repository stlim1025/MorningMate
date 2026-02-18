import '../../../data/models/user_model.dart';

class Challenge {
  final String id;
  final String titleKey;
  final String descKey;
  final int reward;
  final bool Function(UserModel) isCompleted;

  const Challenge({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.reward,
    required this.isCompleted,
  });
}

final List<Challenge> challenges = [
  // 1. Streak Challenges
  Challenge(
    id: 'dawn_start',
    titleKey: 'challenge_dawn_start_title',
    descKey: 'challenge_dawn_start_desc',
    reward: 50,
    isCompleted: (user) => user.displayConsecutiveDays >= 1,
  ),
  Challenge(
    id: 'steady_habit',
    titleKey: 'challenge_steady_habit_title',
    descKey: 'challenge_steady_habit_desc',
    reward: 100,
    isCompleted: (user) => user.displayConsecutiveDays >= 3,
  ),
  Challenge(
    id: 'morning_person',
    titleKey: 'challenge_morning_person_title',
    descKey: 'challenge_morning_person_desc',
    reward: 300,
    isCompleted: (user) => user.displayConsecutiveDays >= 7,
  ),
  Challenge(
    id: 'streak_14',
    titleKey: 'challenge_streak_14_title',
    descKey: 'challenge_streak_14_desc',
    reward: 500,
    isCompleted: (user) => user.displayConsecutiveDays >= 14,
  ),
  Challenge(
    id: 'streak_21',
    titleKey: 'challenge_streak_21_title',
    descKey: 'challenge_streak_21_desc',
    reward: 700,
    isCompleted: (user) => user.displayConsecutiveDays >= 21,
  ),
  Challenge(
    id: 'streak_30',
    titleKey: 'challenge_streak_30_title',
    descKey: 'challenge_streak_30_desc',
    reward: 1000,
    isCompleted: (user) => user.displayConsecutiveDays >= 30,
  ),

  // 2. Social Challenges
  Challenge(
    id: 'friend_1',
    titleKey: 'challenge_friend_1_title',
    descKey: 'challenge_friend_1_desc',
    reward: 50,
    isCompleted: (user) => user.friendIds.isNotEmpty,
  ),
  Challenge(
    id: 'social_king',
    titleKey: 'challenge_social_king_title',
    descKey: 'challenge_social_king_desc',
    reward: 200,
    isCompleted: (user) => user.friendIds.length >= 5,
  ),
  Challenge(
    id: 'friend_10',
    titleKey: 'challenge_friend_10_title',
    descKey: 'challenge_friend_10_desc',
    reward: 400,
    isCompleted: (user) => user.friendIds.length >= 10,
  ),
  Challenge(
    id: 'friend_20',
    titleKey: 'challenge_friend_20_title',
    descKey: 'challenge_friend_20_desc',
    reward: 800,
    isCompleted: (user) => user.friendIds.length >= 20,
  ),

  // 3. Prop Collection
  Challenge(
    id: 'prop_1',
    titleKey: 'challenge_prop_1_title',
    descKey: 'challenge_prop_1_desc',
    reward: 30,
    isCompleted: (user) => user.purchasedPropIds.isNotEmpty,
  ),
  Challenge(
    id: 'rich_room',
    titleKey: 'challenge_rich_room_title',
    descKey: 'challenge_rich_room_desc',
    reward: 150,
    isCompleted: (user) => user.purchasedPropIds.length >= 3,
  ),
  Challenge(
    id: 'prop_5',
    titleKey: 'challenge_prop_5_title',
    descKey: 'challenge_prop_5_desc',
    reward: 300,
    isCompleted: (user) => user.purchasedPropIds.length >= 5,
  ),
  Challenge(
    id: 'prop_10',
    titleKey: 'challenge_prop_10_title',
    descKey: 'challenge_prop_10_desc',
    reward: 600,
    isCompleted: (user) => user.purchasedPropIds.length >= 10,
  ),

  // 4. Character Items
  Challenge(
    id: 'fashion_3',
    titleKey: 'challenge_fashion_3_title',
    descKey: 'challenge_fashion_3_desc',
    reward: 200,
    isCompleted: (user) => user.purchasedCharacterItemIds.length >= 3,
  ),
  Challenge(
    id: 'fashion_5',
    titleKey: 'challenge_fashion_5_title',
    descKey: 'challenge_fashion_5_desc',
    reward: 400,
    isCompleted: (user) => user.purchasedCharacterItemIds.length >= 5,
  ),

  // 5. Backgrounds
  Challenge(
    id: 'bg_1',
    titleKey: 'challenge_bg_1_title',
    descKey: 'challenge_bg_1_desc',
    reward: 100,
    isCompleted: (user) =>
        user.purchasedBackgroundIds.where((e) => e != 'none').isNotEmpty,
  ),
  Challenge(
    id: 'bg_3',
    titleKey: 'challenge_bg_3_title',
    descKey: 'challenge_bg_3_desc',
    reward: 300,
    isCompleted: (user) =>
        user.purchasedBackgroundIds.where((e) => e != 'none').length >= 3,
  ),

  // 6. Growth
  Challenge(
    id: 'level_2',
    titleKey: 'challenge_level_2_title',
    descKey: 'challenge_level_2_desc',
    reward: 100,
    isCompleted: (user) => user.characterLevel >= 2,
  ),
  Challenge(
    id: 'level_5',
    titleKey: 'challenge_level_5_title',
    descKey: 'challenge_level_5_desc',
    reward: 500,
    isCompleted: (user) => user.characterLevel >= 5,
  ),

  // 7. Memos
  Challenge(
    id: 'memo_1',
    titleKey: 'challenge_memo_1_title',
    descKey: 'challenge_memo_1_desc',
    reward: 30,
    isCompleted: (user) => user.memoCount >= 1,
  ),
  Challenge(
    id: 'memo_3',
    titleKey: 'challenge_memo_3_title',
    descKey: 'challenge_memo_3_desc',
    reward: 100,
    isCompleted: (user) => user.memoCount >= 3,
  ),
  Challenge(
    id: 'memo_10',
    titleKey: 'challenge_memo_10_title',
    descKey: 'challenge_memo_10_desc',
    reward: 300,
    isCompleted: (user) => user.memoCount >= 10,
  ),
  Challenge(
    id: 'memo_30',
    titleKey: 'challenge_memo_30_title',
    descKey: 'challenge_memo_30_desc',
    reward: 500,
    isCompleted: (user) => user.memoCount >= 30,
  ),

  // 8. General
  Challenge(
    id: 'diary_master',
    titleKey: 'challenge_diary_master_title',
    descKey: 'challenge_diary_master_desc',
    reward: 500,
    isCompleted: (user) => user.diaryCount >= 30,
  ),
];

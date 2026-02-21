import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../character/controllers/character_controller.dart';
import '../../../core/localization/app_localizations.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final characterController = context.watch<CharacterController>();
    final user = characterController.currentUser;

    final List<Map<String, dynamic>> challenges = [
      // 1. Streak Challenges
      {
        'id': 'dawn_start',
        'title':
            AppLocalizations.of(context)?.get('challenge_dawn_start_title') ??
                'Start of Dawn',
        'description':
            AppLocalizations.of(context)?.get('challenge_dawn_start_desc') ??
                'Write a diary before 6 AM once',
        'isCompleted': (user?.displayConsecutiveDays ?? 0) >= 1,
        'reward':
            '50 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'steady_habit',
        'title':
            AppLocalizations.of(context)?.get('challenge_steady_habit_title') ??
                'Steady Habit',
        'description':
            AppLocalizations.of(context)?.get('challenge_steady_habit_desc') ??
                'Write diary for 3 consecutive days',
        'isCompleted': (user?.displayConsecutiveDays ?? 0) >= 3,
        'reward':
            '100 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'morning_person',
        'title': AppLocalizations.of(context)
                ?.get('challenge_morning_person_title') ??
            'True Morning Person',
        'description': AppLocalizations.of(context)
                ?.get('challenge_morning_person_desc') ??
            'Write diary for 7 consecutive days',
        'isCompleted': (user?.displayConsecutiveDays ?? 0) >= 7,
        'reward':
            '300 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'streak_14',
        'title':
            AppLocalizations.of(context)?.get('challenge_streak_14_title') ??
                '2 Weeks Streak',
        'description':
            AppLocalizations.of(context)?.get('challenge_streak_14_desc') ??
                'Write diary for 14 consecutive days',
        'isCompleted': (user?.displayConsecutiveDays ?? 0) >= 14,
        'reward':
            '500 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'streak_21',
        'title':
            AppLocalizations.of(context)?.get('challenge_streak_21_title') ??
                '3 Weeks Streak',
        'description':
            AppLocalizations.of(context)?.get('challenge_streak_21_desc') ??
                'Write diary for 21 consecutive days',
        'isCompleted': (user?.displayConsecutiveDays ?? 0) >= 21,
        'reward':
            '700 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'streak_30',
        'title':
            AppLocalizations.of(context)?.get('challenge_streak_30_title') ??
                'Monthly Master',
        'description':
            AppLocalizations.of(context)?.get('challenge_streak_30_desc') ??
                'Write diary for 30 consecutive days',
        'isCompleted': (user?.displayConsecutiveDays ?? 0) >= 30,
        'reward':
            '1000 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },

      // 2. Social Challenges
      {
        'id': 'friend_1',
        'title':
            AppLocalizations.of(context)?.get('challenge_friend_1_title') ??
                'First Friend',
        'description':
            AppLocalizations.of(context)?.get('challenge_friend_1_desc') ??
                'Make your first friend',
        'isCompleted': (user?.friendIds.length ?? 0) >= 1,
        'reward':
            '50 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'social_king',
        'title':
            AppLocalizations.of(context)?.get('challenge_social_king_title') ??
                'Social King',
        'description':
            AppLocalizations.of(context)?.get('challenge_social_king_desc') ??
                'Make 5 friends',
        'isCompleted': (user?.friendIds.length ?? 0) >= 5,
        'reward':
            '200 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'friend_10',
        'title':
            AppLocalizations.of(context)?.get('challenge_friend_10_title') ??
                'Popular',
        'description':
            AppLocalizations.of(context)?.get('challenge_friend_10_desc') ??
                'Make 10 friends',
        'isCompleted': (user?.friendIds.length ?? 0) >= 10,
        'reward':
            '400 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'friend_20',
        'title':
            AppLocalizations.of(context)?.get('challenge_friend_20_title') ??
                'Social Celebrity',
        'description':
            AppLocalizations.of(context)?.get('challenge_friend_20_desc') ??
                'Make 20 friends',
        'isCompleted': (user?.friendIds.length ?? 0) >= 20,
        'reward':
            '800 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },

      // 3. Prop Collection
      {
        'id': 'prop_1',
        'title': AppLocalizations.of(context)?.get('challenge_prop_1_title') ??
            'First Decoration',
        'description':
            AppLocalizations.of(context)?.get('challenge_prop_1_desc') ??
                'Buy 1 prop',
        'isCompleted': (user?.purchasedPropIds.length ?? 0) >= 1,
        'reward':
            '30 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'rich_room',
        'title':
            AppLocalizations.of(context)?.get('challenge_rich_room_title') ??
                'Rich Room',
        'description':
            AppLocalizations.of(context)?.get('challenge_rich_room_desc') ??
                'Buy 3 or more props',
        'isCompleted': (user?.purchasedPropIds.length ?? 0) >= 3,
        'reward':
            '150 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'prop_5',
        'title': AppLocalizations.of(context)?.get('challenge_prop_5_title') ??
            'Decorator',
        'description':
            AppLocalizations.of(context)?.get('challenge_prop_5_desc') ??
                'Buy 5 props',
        'isCompleted': (user?.purchasedPropIds.length ?? 0) >= 5,
        'reward':
            '300 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'prop_10',
        'title': AppLocalizations.of(context)?.get('challenge_prop_10_title') ??
            'Maximalist',
        'description':
            AppLocalizations.of(context)?.get('challenge_prop_10_desc') ??
                'Buy 10 props',
        'isCompleted': (user?.purchasedPropIds.length ?? 0) >= 10,
        'reward':
            '600 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },

      // 4. Character Items
      {
        'id': 'fashion_3',
        'title':
            AppLocalizations.of(context)?.get('challenge_fashion_3_title') ??
                'Fashionista',
        'description':
            AppLocalizations.of(context)?.get('challenge_fashion_3_desc') ??
                'Buy 3 character items',
        'isCompleted': (user?.purchasedCharacterItemIds.length ?? 0) >= 3,
        'reward':
            '200 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'fashion_5',
        'title':
            AppLocalizations.of(context)?.get('challenge_fashion_5_title') ??
                'Trendsetter',
        'description':
            AppLocalizations.of(context)?.get('challenge_fashion_5_desc') ??
                'Buy 5 character items',
        'isCompleted': (user?.purchasedCharacterItemIds.length ?? 0) >= 5,
        'reward':
            '400 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },

      // 5. Backgrounds
      {
        'id': 'bg_1',
        'title': AppLocalizations.of(context)?.get('challenge_bg_1_title') ??
            'Mood Change',
        'description':
            AppLocalizations.of(context)?.get('challenge_bg_1_desc') ??
                'Buy 1 background',
        'isCompleted':
            (user?.purchasedBackgroundIds.where((e) => e != 'none').length ??
                    0) >=
                1,
        'reward':
            '100 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'bg_3',
        'title': AppLocalizations.of(context)?.get('challenge_bg_3_title') ??
            'Atmosphere Master',
        'description':
            AppLocalizations.of(context)?.get('challenge_bg_3_desc') ??
                'Buy 3 backgrounds',
        'isCompleted':
            (user?.purchasedBackgroundIds.where((e) => e != 'none').length ??
                    0) >=
                3,
        'reward':
            '300 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },

      // 6. Growth
      {
        'id': 'level_2',
        'title': AppLocalizations.of(context)?.get('challenge_level_2_title') ??
            'First Growth',
        'description':
            AppLocalizations.of(context)?.get('challenge_level_2_desc') ??
                'Reach Character Level 2',
        'isCompleted': (user?.characterLevel ?? 1) >= 2,
        'reward':
            '100 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'level_3',
        'title': AppLocalizations.of(context)?.get('challenge_level_3_title') ??
            'Growing Up',
        'description':
            AppLocalizations.of(context)?.get('challenge_level_3_desc') ??
                'Reach Character Level 3',
        'isCompleted': (user?.characterLevel ?? 1) >= 3,
        'reward':
            '200 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'level_4',
        'title': AppLocalizations.of(context)?.get('challenge_level_4_title') ??
            'Almost There',
        'description':
            AppLocalizations.of(context)?.get('challenge_level_4_desc') ??
                'Reach Character Level 4',
        'isCompleted': (user?.characterLevel ?? 1) >= 4,
        'reward':
            '350 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'level_5',
        'title': AppLocalizations.of(context)?.get('challenge_level_5_title') ??
            'Fully Grown',
        'description':
            AppLocalizations.of(context)?.get('challenge_level_5_desc') ??
                'Reach Character Level 5',
        'isCompleted': (user?.characterLevel ?? 1) >= 5,
        'reward':
            '500 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },

      // 7. Memos
      {
        'id': 'memo_1',
        'title': AppLocalizations.of(context)?.get('challenge_memo_1_title') ??
            'First Memo',
        'description':
            AppLocalizations.of(context)?.get('challenge_memo_1_desc') ??
                'Write your first memo',
        'isCompleted': (user?.memoCount ?? 0) >= 1,
        'reward':
            '30 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'memo_3',
        'title': AppLocalizations.of(context)?.get('challenge_memo_3_title') ??
            'Memo Collector',
        'description':
            AppLocalizations.of(context)?.get('challenge_memo_3_desc') ??
                'Write 3 memos',
        'isCompleted': (user?.memoCount ?? 0) >= 3,
        'reward':
            '100 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'memo_10',
        'title': AppLocalizations.of(context)?.get('challenge_memo_10_title') ??
            'Memo Maniac',
        'description':
            AppLocalizations.of(context)?.get('challenge_memo_10_desc') ??
                'Write 10 memos',
        'isCompleted': (user?.memoCount ?? 0) >= 10,
        'reward':
            '300 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
      {
        'id': 'memo_30',
        'title': AppLocalizations.of(context)?.get('challenge_memo_30_title') ??
            'Memo Master',
        'description':
            AppLocalizations.of(context)?.get('challenge_memo_30_desc') ??
                'Write 30 memos',
        'isCompleted': (user?.memoCount ?? 0) >= 30,
        'reward':
            '500 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },

      // 8. General
      {
        'id': 'diary_master',
        'title':
            AppLocalizations.of(context)?.get('challenge_diary_master_title') ??
                'Diary Master',
        'description':
            AppLocalizations.of(context)?.get('challenge_diary_master_desc') ??
                'Write 30 diaries in total',
        'isCompleted': (user?.diaryCount ?? 0) >= 30,
        'reward':
            '500 ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      },
    ];

    // isCompleted가 true인 항목을 뒤로 보내기
    challenges.sort((a, b) {
      bool aCompleted = a['isCompleted'];
      bool bCompleted = b['isCompleted'];
      if (aCompleted == bCompleted) return 0;
      return aCompleted ? 1 : -1;
    });

    final completedCount = challenges.where((c) => c['isCompleted']).length;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Challenge_Background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Challenge_Note.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    // Title
                    Text(
                      AppLocalizations.of(context)?.get('challengesTitle') ??
                          'Challenges',
                      style: const TextStyle(
                        fontFamily: 'BMJUA',
                        fontSize: 18,
                        color: Color(0xFF4E342E),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Progress Section
                    _buildHeaderProgress(
                        context, completedCount, challenges.length),
                    const SizedBox(height: 10),
                    // Dotted Separator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child:
                          _DottedDivider(color: Colors.brown.withOpacity(0.3)),
                    ),
                    // List Section
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(35, 10, 35, 120),
                        itemCount: challenges.length,
                        itemBuilder: (context, index) {
                          return _buildChallengeListItem(
                              context, challenges[index], colorScheme);
                        },
                      ),
                    ),
                    const SizedBox(
                        height:
                            25), // Bottom margin to keep list inside note image
                  ],
                ),
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderProgress(BuildContext context, int completed, int total) {
    final double progressRatio = total > 0 ? completed / total : 0;
    // 가득 찼을 때도 좌우 여백을 위해 끝까지 차지 않도록 조절
    final double constrainedRatio = progressRatio * 0.94;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          // 1. 텍스트와 게이지 바 커테이너
          Padding(
            padding: const EdgeInsets.only(right: 25), // 상자와 겹칠 공간 확보
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 4),
                      child: Text(
                        AppLocalizations.of(context)
                                ?.get('challengesProgress') ??
                            'Challenges Completed',
                        style: const TextStyle(
                          fontFamily: 'BMJUA',
                          fontSize: 14,
                          color: Color(0xFF4E342E),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 20, top: 4),
                      child: Text(
                        '$completed / $total',
                        style: const TextStyle(
                          fontFamily: 'BMJUA',
                          fontSize: 14,
                          color: Color(0xFF4E342E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 게이지 바 (배경 이미지 + 노란색 바 이미지)
                Transform.translate(
                  offset: const Offset(15, 0), // 우측으로 더 이동시켜 상자와 겹치게 함
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // 배경 틀 (Empty)
                      Image.asset(
                        'assets/images/Challenge_ProgressBar_Empty.png',
                        width: double.infinity,
                        height: 22,
                        fit: BoxFit.fill,
                      ),
                      // 노란 게이지 (ProgressBar)
                      // 세로 중앙 배치를 위해 배경보다 높이를 낮게 설정
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 5), // 끝부분 여백
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: constrainedRatio,
                            child: Image.asset(
                              'assets/images/Challenge_ProgressBar.png',
                              width: double.infinity,
                              height: 12, // 배경보다 얇게 설정하여 세로 중앙에 오게 함
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 2. 상자 이미지 (게이지 바 우측 상단에 겹치게 배치)
          Positioned(
            right: -15,
            bottom: -8,
            child: Image.asset(
              'assets/icons/Challenge_Box.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeListItem(BuildContext context,
      Map<String, dynamic> challenge, AppColorScheme colorScheme) {
    final bool isCompleted = challenge['isCompleted'];

    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            context.push('/challenge-detail/${challenge['id']}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge['title'],
                        style: const TextStyle(
                          fontFamily: 'BMJUA',
                          fontSize: 16,
                          color: Color(0xFF4E342E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/branch.png',
                            width: 14,
                            height: 14,
                            color: Colors.brown,
                          ),
                          Text(
                            ' ${challenge['reward']} ',
                            style: const TextStyle(
                              fontFamily: 'BMJUA',
                              fontSize: 12,
                              color: Colors.brown,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              challenge['description'],
                              style: TextStyle(
                                fontFamily: 'KyoboHandwriting2024psw',
                                fontSize: 12,
                                color: const Color(0xFF4E342E).withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isCompleted)
                  Transform.rotate(
                    angle: -0.1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.redAccent.withOpacity(0.6),
                            width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.get('completed') ??
                            'Completed',
                        style: TextStyle(
                          color: Colors.redAccent.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'BMJUA',
                        ),
                      ),
                    ),
                  )
                else
                  Image.asset(
                    'assets/icons/Lock_Icon.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
              ],
            ),
          ),
        ),
        _DottedDivider(color: Colors.brown.withOpacity(0.5)),
      ],
    );
  }
}

class _DottedDivider extends StatelessWidget {
  final Color color;
  const _DottedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 2.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

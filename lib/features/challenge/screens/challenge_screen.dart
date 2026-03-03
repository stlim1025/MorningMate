import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../character/controllers/character_controller.dart';
import '../../../core/localization/app_localizations.dart';
import '../data/challenge_data.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final characterController = context.watch<CharacterController>();
    final user = characterController.currentUser;

    final List<Map<String, dynamic>> challengesList = challenges.map((c) {
      final bool isCompleted = user != null &&
          (user.completedChallengeIds.contains(c.id) || c.isCompleted(user));

      return {
        'id': c.id,
        'title': AppLocalizations.of(context)?.get(c.titleKey) ?? c.id,
        'description': AppLocalizations.of(context)?.get(c.descKey) ?? '',
        'isCompleted': isCompleted,
        'reward':
            '${c.reward} ${AppLocalizations.of(context)?.get('branch') ?? 'Branch'}',
      };
    }).toList();

    // isCompleted가 true인 항목을 뒤로 보내기
    challengesList.sort((a, b) {
      bool aCompleted = a['isCompleted'];
      bool bCompleted = b['isCompleted'];
      if (aCompleted == bCompleted) return 0;
      return aCompleted ? 1 : -1;
    });

    final completedCount = challengesList.where((c) => c['isCompleted']).length;

    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;

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
                        itemCount: challengesList.length,
                        itemBuilder: (context, index) {
                          return _buildChallengeListItem(
                              context, challengesList[index], colorScheme);
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
            SizedBox(height: 90 + bottomInset),
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

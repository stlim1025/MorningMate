import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../character/controllers/character_controller.dart';
import '../data/challenge_data.dart';

class ChallengeDetailScreen extends StatelessWidget {
  final String challengeId;
  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context) {
    final characterController = context.watch<CharacterController>();
    final user = characterController.currentUser;
    final loc = AppLocalizations.of(context);

    // 현재 도전과제 찾기
    final challenge = challenges.firstWhere(
      (c) => c.id == challengeId,
      orElse: () => challenges.first,
    );

    // 같은 계열 도전과제 목록 (원래 순서 유지)
    final sameSeries =
        challenges.where((c) => c.group == challenge.group).toList();

    // 현재 값 / 목표 값
    final currentValue = user != null ? challenge.getCurrentValue(user) : 0;
    final targetValue = challenge.targetValue;
    final isCompleted = user != null ? challenge.isCompleted(user) : false;

    // 같은 계열 중 미완료 도전과제 수
    final remainingInSeries = user != null
        ? sameSeries.where((c) => !c.isCompleted(user)).length
        : sameSeries.length;

    final isStreakCategory = challenge.category == 'streak';

    return PopScope(
      canPop: true,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Challenge_Background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
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
                        const SizedBox(height: 10),
                        // 뒤로가기 버튼 + 타이틀
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 타이틀 (중앙)
                              Text(
                                loc?.get(challenge.titleKey) ?? challenge.id,
                                style: const TextStyle(
                                  fontFamily: 'BMJUA',
                                  fontSize: 18,
                                  color: Color(0xFF4E342E),
                                ),
                              ),
                              // Cancel 버튼 (왼쪽)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Image.asset(
                                    'assets/icons/X_Button.png',
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 본문
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(35, 15, 35, 120),
                            children: [
                              // 진행률 그래프
                              _buildProgressGraph(
                                context,
                                currentValue,
                                targetValue,
                                isCompleted,
                                isStreakCategory,
                              ),
                              const SizedBox(height: 16),
                              _DottedDivider(
                                  color: Colors.brown.withOpacity(0.3)),
                              const SizedBox(height: 16),

                              // 상세 내용
                              _buildDetailSection(context, challenge, loc),
                              const SizedBox(height: 16),
                              _DottedDivider(
                                  color: Colors.brown.withOpacity(0.3)),
                              const SizedBox(height: 16),

                              // 연속 기록 주의사항
                              if (isStreakCategory) ...[
                                _buildWarningSection(context, loc),
                                const SizedBox(height: 16),
                                _DottedDivider(
                                    color: Colors.brown.withOpacity(0.3)),
                                const SizedBox(height: 16),
                              ],

                              // 같은 계열 남은 도전과제
                              _buildRemainingChallenges(
                                context,
                                sameSeries,
                                user,
                                remainingInSeries,
                                loc,
                              ),
                              const SizedBox(height: 16),
                              _DottedDivider(
                                  color: Colors.brown.withOpacity(0.3)),
                              const SizedBox(height: 16),

                              // 보상
                              _buildRewardSection(context, challenge, loc),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressGraph(
    BuildContext context,
    int currentValue,
    int targetValue,
    bool isCompleted,
    bool isStreakCategory,
  ) {
    final loc = AppLocalizations.of(context);
    final double progress =
        targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          // 현재 / 목표 텍스트
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc?.get('challengeDetailCurrent') ?? 'Current',
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 13,
                  color: Color(0xFF8D6E63),
                ),
              ),
              Text(
                loc?.get('challengeDetailTarget') ?? 'Target',
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 13,
                  color: Color(0xFF8D6E63),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isStreakCategory
                    ? '$currentValue${loc?.get('days') ?? ' Days'}'
                    : '$currentValue',
                style: TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 24,
                  color: isCompleted
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF4E342E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isStreakCategory
                    ? '$targetValue${loc?.get('days') ?? ' Days'}'
                    : '$targetValue',
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 24,
                  color: Color(0xFF4E342E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 프로그레스 바
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Image.asset(
                'assets/images/Challenge_ProgressBar_Empty.png',
                width: double.infinity,
                height: 24,
                fit: BoxFit.fill,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress * 0.94,
                    child: Image.asset(
                      'assets/images/Challenge_ProgressBar.png',
                      width: double.infinity,
                      height: 14,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              // 중앙에 퍼센트 text
              Center(
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontFamily: 'BMJUA',
                    fontSize: 11,
                    color: Color(0xFF5D4037),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (isCompleted) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle,
                    color: Color(0xFF4CAF50), size: 18),
                const SizedBox(width: 6),
                Text(
                  loc?.get('completed') ?? 'Completed',
                  style: const TextStyle(
                    fontFamily: 'BMJUA',
                    fontSize: 14,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection(
      BuildContext context, Challenge challenge, AppLocalizations? loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF8D6E63), size: 18),
            const SizedBox(width: 8),
            Text(
              loc?.get('challengeDetailInfo') ?? 'Challenge Details',
              style: const TextStyle(
                fontFamily: 'BMJUA',
                fontSize: 15,
                color: Color(0xFF4E342E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          loc?.get(challenge.descKey) ?? '',
          style: const TextStyle(
            fontFamily: 'KyoboHandwriting2024psw',
            fontSize: 15,
            color: Color(0xFF5D4037),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningSection(BuildContext context, AppLocalizations? loc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFE65100), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc?.get('challengeDetailWarningTitle') ?? 'Caution',
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 14,
                  color: Color(0xFFE65100),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loc?.get('challengeDetailWarningDesc') ??
                    'If you miss even one day, the streak resets to 0!',
                style: const TextStyle(
                  fontFamily: 'KyoboHandwriting2024psw',
                  fontSize: 14,
                  color: Color(0xFFBF360C),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRemainingChallenges(
    BuildContext context,
    List<Challenge> sameSeries,
    dynamic user,
    int remainingCount,
    AppLocalizations? loc,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.format_list_numbered,
                color: Color(0xFF8D6E63), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loc?.get('challengeDetailRemaining') ??
                    'Remaining challenges in this series',
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 14,
                  color: Color(0xFF4E342E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.brown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$remainingCount',
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 14,
                  color: Color(0xFF4E342E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 같은 계열 도전과제 리스트
        ...sameSeries.map((c) {
          final done = user != null ? c.isCompleted(user) : false;
          final isCurrent = c.id == challengeId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color:
                      done ? const Color(0xFF4CAF50) : const Color(0xFF8D6E63),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc?.get(c.titleKey) ?? c.id,
                    style: TextStyle(
                      fontFamily: 'BMJUA',
                      fontSize: 13,
                      color: isCurrent
                          ? const Color(0xFF4E342E)
                          : const Color(0xFF8D6E63),
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8D6E63).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      loc?.get('challengeDetailCurrentLabel') ?? 'Current',
                      style: const TextStyle(
                        fontFamily: 'BMJUA',
                        fontSize: 10,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRewardSection(
      BuildContext context, Challenge challenge, AppLocalizations? loc) {
    return Row(
      children: [
        Image.asset(
          'assets/images/branch.png',
          width: 28,
          height: 28,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc?.get('challengeDetailReward') ?? 'Reward',
              style: const TextStyle(
                fontFamily: 'BMJUA',
                fontSize: 14,
                color: Color(0xFF4E342E),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${challenge.reward} ${loc?.get('branch') ?? 'Branch'}',
              style: const TextStyle(
                fontFamily: 'BMJUA',
                fontSize: 18,
                color: Color(0xFFE65100),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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

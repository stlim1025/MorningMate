import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../common/widgets/custom_bottom_navigation_bar.dart';
import '../../character/controllers/character_controller.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final characterController = context.watch<CharacterController>();
    final user = characterController.currentUser;

    final List<Map<String, dynamic>> challenges = [
      {
        'title': '새벽의 시작',
        'description': '오전 6시 이전에 일기 1회 작성하기',
        'isCompleted': (user?.consecutiveDays ?? 0) >= 1,
        'reward': '50 가지',
      },
      {
        'title': '꾸준한 습관',
        'description': '3일 연속 일기 작성하기',
        'isCompleted': (user?.consecutiveDays ?? 0) >= 3,
        'reward': '100 가지',
      },
      {
        'title': '진정한 아침형 인간',
        'description': '7일 연속 일기 작성하기',
        'isCompleted': (user?.consecutiveDays ?? 0) >= 7,
        'reward': '300 가지',
      },
      {
        'title': '풍성한 방',
        'description': '소품 3개 이상 구매하기',
        'isCompleted': (user?.purchasedPropIds.length ?? 0) >= 3,
        'reward': '150 가지',
      },
      {
        'title': '마당 넓은 주인',
        'description': '친구 5명 맺기',
        'isCompleted': (user?.friendIds.length ?? 0) >= 5,
        'reward': '200 가지',
      },
      {
        'title': '일기의 달인',
        'description': '누적 일기 30개 작성하기',
        'isCompleted': false,
        'reward': '500 가지',
      },
    ];

    final completedCount = challenges.where((c) => c['isCompleted']).length;

    return Scaffold(
      extendBody: true,
      body: Container(
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
                      const Text(
                        '도전과제',
                        style: TextStyle(
                          fontFamily: 'BMJUA',
                          fontSize: 18,
                          color: Color(0xFF4E342E),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Progress Section
                      _buildHeaderProgress(completedCount, challenges.length),
                      const SizedBox(height: 10),
                      // Dotted Separator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: _DottedDivider(
                            color: Colors.brown.withOpacity(0.3)),
                      ),
                      // List Section
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(35, 10, 35, 60),
                          itemCount: challenges.length,
                          itemBuilder: (context, index) {
                            return _buildChallengeListItem(
                                context, challenges[index], colorScheme);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildHeaderProgress(int completed, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '도전과제 달성 수',
                style: TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 14,
                  color: Color(0xFF4E342E),
                ),
              ),
              Text(
                '$completed / $total',
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 14,
                  color: Color(0xFF4E342E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              minHeight: 12,
              backgroundColor: Colors.brown.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
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
        Padding(
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.redAccent.withOpacity(0.6), width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '완료',
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
                Icon(
                  Icons.lock_outline,
                  color: Colors.brown.withOpacity(0.3),
                  size: 24,
                ),
            ],
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

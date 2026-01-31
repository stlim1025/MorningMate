import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../controllers/morning_controller.dart';

class RandomQuestionWidget extends StatelessWidget {
  const RandomQuestionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    return Consumer<MorningController>(
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () async {
            await controller.fetchRandomQuestion();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.secondary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: colorScheme.pointStar,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘의 질문',
                        style: TextStyle(
                          color: colorScheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.currentQuestion ?? '탭하여 질문 보기',
                        style: TextStyle(
                          color: colorScheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.refresh,
                  color: colorScheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final double progress;
  final String? title;
  final bool showPercentage;

  const ProgressIndicatorWidget({
    super.key,
    required this.progress,
    this.title,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final percentage = (progress * 100).clamp(0, 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!,
                  style: TextStyle(
                    color: colorScheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showPercentage)
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      color: colorScheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colorScheme.textHint.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progress, colorScheme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress, AppColorScheme colorScheme) {
    if (progress < 0.3) {
      return colorScheme.error;
    } else if (progress < 0.7) {
      return colorScheme.warning;
    } else {
      return colorScheme.success;
    }
  }
}

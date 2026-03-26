import 'package:flutter/material.dart';
import 'header_image_button.dart';

class TodayDiaryButton extends StatelessWidget {
  final VoidCallback onTap;
  const TodayDiaryButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HeaderImageButton(
      imagePath: 'assets/icons/Today_Diary_Icon.png',
      onTap: onTap,
      size: 50.0,
    );
  }
}

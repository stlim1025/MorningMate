import 'package:flutter/material.dart';

class MemoNotification {
  static void show(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          width: double.infinity,
          height: 100, // 높이를 약간 늘림
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/images/Memo.png'),
              fit: BoxFit.fill,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 20, 40, 10), // 상단 패딩 조정
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'BMJUA',
                  fontSize: 16, // 폰트 사이즈를 약간 줄여서 가독성 확보
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 2),
        margin: const EdgeInsets.only(bottom: 40, left: 30, right: 30),
      ),
    );
  }
}
